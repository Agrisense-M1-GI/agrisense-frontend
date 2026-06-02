import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  String?    _token;
  bool       _isLoading = true; // true par défaut → splash affiché jusqu'à fin init()
  String?    _errorMessage;

  static const String _keyToken = 'agrisense_jwt_token';
  static const String _keyUser  = 'agrisense_user';

  UserModel? get user         => _user;
  String?    get token        => _token;
  bool       get isLoading    => _isLoading;
  String?    get errorMessage => _errorMessage;

  // ✅ CRITIQUE : token non null ET non vide ET user valide
  bool get isLoggedIn =>
      _token != null &&
      _token!.isNotEmpty &&
      _user != null &&
      _user!.estValide;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  Map<String, String> get _authHeaders => {
    ..._headers,
    'Authorization': 'Bearer $_token',
  };

  
// ── INITIALISATION ──────────────────────────────────────────
Future<void> init() async {
  _isLoading = true;
  notifyListeners();

  final prefs = await SharedPreferences.getInstance();
  _token = prefs.getString(_keyToken);
  final userJson = prefs.getString(_keyUser);

  if (_token != null && userJson != null) {
    try {
      _user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      final response = await http
          .get(Uri.parse(ApiConfig.me), headers: _authHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        await _persistUser(_user!);
      } else {
        await _clearSession();
      }
    } catch (_) {
      // Pas de réseau → garder cache local
    }
  }

  _isLoading = false;
  notifyListeners();
}
  /*Future<void> init() async {
    // isLoading est déjà true depuis la construction

    final prefs    = await SharedPreferences.getInstance();
    final token    = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);

    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );

        // User local invalide → on nettoie
        if (!user.estValide) {
          await _clearSession();
          _isLoading = false;
          notifyListeners();
          return;
        }

        _token = token;
        _user  = user;

        // Vérifie le token côté serveur
        final tokenOk = await _verifierToken();
        if (!tokenOk) {
          await _clearSession();
        }
      } catch (_) {
        await _clearSession();
      }
    } else {
      // Pas de session sauvegardée → on nettoie au cas où
      await _clearSession();
    }

    _isLoading = false;
    notifyListeners();
  }*/

  // ── INSCRIPTION ─────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String profession,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: _headers,
            body: jsonEncode({
              'email':      email.trim(),
              'password':   password,
              'nom':        nom.trim(),
              'prenom':     prenom.trim(),
              'profession': profession.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Inscription réussie → PAS de sauvegarde de session
        // L'utilisateur doit se connecter manuellement
        _setLoading(false);
        return true;
      } else {
        _errorMessage = body['error'] as String? ??
            'Erreur lors de l\'inscription';
        _setLoading(false);
        return false;
      }
    } on Exception catch (e) {
      _errorMessage = _handleException(e);
      _setLoading(false);
      return false;
    }
  }

  // ── CONNEXION ───────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: _headers,
            body: jsonEncode({
              'email':    email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // ✅ On vérifie le statusCode EN PREMIER avant de parser
      if (response.statusCode == 200) {
        try {
          final auth = AuthResponse.fromJson(body);

          // ✅ Double vérification : user doit être valide
          if (!auth.utilisateur.estValide || auth.token.isEmpty) {
            _errorMessage = 'Réponse du serveur invalide';
            _setLoading(false);
            return false;
          }

          await _saveSession(auth.token, auth.utilisateur);
          _setLoading(false);
          return true;
        } on FormatException catch (e) {
          _errorMessage = e.message;
          _setLoading(false);
          return false;
        }
      } else {
        // 400, 401, 404... → erreur métier
        _errorMessage = body['error'] as String? ??
            'Email ou mot de passe incorrect';
        _setLoading(false);
        return false;
      }
    } on Exception catch (e) {
      _errorMessage = _handleException(e);
      _setLoading(false);
      return false;
    }
  }

  // ── DÉCONNEXION ─────────────────────────────────────────────
  Future<void> logout() async {
    await _clearSession();
    _isLoading = false;
    notifyListeners();
  }

  // ── RÉCUPÉRER MON PROFIL ────────────────────────────────────
  Future<bool> fetchMe() async {
    if (_token == null || _token!.isEmpty) return false;

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.me), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserModel.fromJson(body);
        if (user.estValide) {
          _user = user;
          await _persistUser(_user!);
          notifyListeners();
          return true;
        }
        return false;
      } else if (response.statusCode == 401) {
        await _clearSession();
        notifyListeners();
        return false;
      }
    } on Exception {
      // Pas de réseau → on garde les données locales
    }
    return false;
  }

  // ── MISE À JOUR PROFIL ──────────────────────────────────────
  Future<bool> updateMe({
    required String nom,
    required String prenom,
    required String email,
    required String profession,
  }) async {
    if (_token == null || _token!.isEmpty) return false;
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.updateMe),
            headers: _authHeaders,
            body: jsonEncode({
              'nom':        nom.trim(),
              'prenom':     prenom.trim(),
              'email':      email.trim(),
              'profession': profession.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body);
        if (user.estValide) {
          _user = user;
          await _persistUser(_user!);
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = body['error'] as String? ??
            'Erreur lors de la mise à jour';
        _setLoading(false);
        return false;
      }
    } on Exception catch (e) {
      _errorMessage = _handleException(e);
      _setLoading(false);
      return false;
    }
  }

  // ── MÉTHODES PRIVÉES ────────────────────────────────────────
  Future<void> _saveSession(String token, UserModel user) async {
    _token = token;
    _user  = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    _token = null;
    _user  = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // Retourne true = token valide, false = token expiré/invalide
  Future<bool> _verifierToken() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.me), headers: _authHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // Met à jour le user depuis le serveur
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = UserModel.fromJson(body);
        if (user.estValide) {
          _user = user;
          await _persistUser(user);
        }
        return true;
      } else if (response.statusCode == 401) {
        return false;
      }
      return true;
    } on Exception {
      // Pas de réseau → on garde la session locale
      return true;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _handleException(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout'))    return 'Délai dépassé. Vérifiez votre connexion.';
    if (msg.contains('socket'))     return 'Impossible de joindre le serveur.';
    if (msg.contains('connection')) return 'Pas de connexion réseau.';
    return 'Une erreur s\'est produite. Réessayez.';
  }
}