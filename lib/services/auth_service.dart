import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  // ── État interne ───────────────────────────────────────────
  UserModel? _user;
  String?    _token;
  bool       _isLoading = false;
  String?    _errorMessage;

  // ── Clés SharedPreferences ─────────────────────────────────
  static const String _keyToken = 'agrisense_jwt_token';
  static const String _keyUser  = 'agrisense_user';
  static const bool devMode=true;

  // ── Getters publics ────────────────────────────────────────
  UserModel? get user        => _user;
  String?    get token       => _token;
  bool       get isLoading   => _isLoading;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn  => _token != null && _user != null;

  // ── Headers communs ────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  Map<String, String> get _authHeaders => {
    ..._headers,
    'Authorization': 'Bearer $_token',
  };

  // ══════════════════════════════════════════════════════════
  // INITIALISATION — à appeler au démarrage de l'app
  // ══════════════════════════════════════════════════════════
  /*Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);
    if (userJson != null && _token != null) {
      try {
        _user = UserModel.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
        notifyListeners();
        // Vérifie que le token est encore valide
        await _verifierToken();
      } catch (_) {
        await _clearSession();
      }
    }
    

    _isLoading = false;
    notifyListeners();
  }*/
  Future<void> init() async {
  _isLoading = true;
  notifyListeners();

  // ── MODE DEV : bypass login ─────────────────────────────
  if (devMode) {
    _user = const UserModel(
      id: '1',
      email: 'kouam.njankou@agrisense.cm',
      nom: 'Kouam',
      prenom: 'Njankou',
      profession: 'Agriculteur',
      statut: 'actif',
      createdAt: '2026-01-01',
    );

    _token = 'dev-token';

    _isLoading = false;
    notifyListeners();
    return;
  }

  // ── MODE NORMAL ─────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();

  _token = prefs.getString(_keyToken);

  final userJson = prefs.getString(_keyUser);

  if (userJson != null && _token != null) {
    try {
      _user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );

      await _verifierToken();
    } catch (_) {
      await _clearSession();
    }
  }

  _isLoading = false;
  notifyListeners();
}

  // ══════════════════════════════════════════════════════════
  // INSCRIPTION — POST /auth/register
  // ══════════════════════════════════════════════════════════
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
        final auth = AuthResponse.fromJson(body);
        await _saveSession(auth.token, auth.utilisateur);
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

  // ══════════════════════════════════════════════════════════
  // CONNEXION — POST /auth/login
  // ══════════════════════════════════════════════════════════
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

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(body);
        await _saveSession(auth.token, auth.utilisateur);
        _setLoading(false);
        return true;
      } else {
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

  // ══════════════════════════════════════════════════════════
  // DÉCONNEXION
  // ══════════════════════════════════════════════════════════
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // RÉCUPÉRER MON PROFIL — GET /utilisateurs/me
  // ══════════════════════════════════════════════════════════
  Future<bool> fetchMe() async {
    if (_token == null) return false;

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.me), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _user = UserModel.fromJson(body);
        await _persistUser(_user!);
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        await _clearSession();
        return false;
      }
    } on Exception {
      // Pas de connexion réseau — on garde les données locales
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════
  // METTRE À JOUR MON PROFIL — PUT /utilisateurs/me
  // ══════════════════════════════════════════════════════════
  Future<bool> updateMe({
    required String nom,
    required String prenom,
    required String email,
    required String profession,
  }) async {
    if (_token == null) return false;
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
        _user = UserModel.fromJson(body);
        await _persistUser(_user!);
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

  // ══════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ══════════════════════════════════════════════════════════

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

  Future<void> _verifierToken() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.me), headers: _authHeaders)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 401) {
        await _clearSession();
      }
    } on Exception {
      // Pas de réseau — on garde la session locale
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _handleException(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout'))   return 'Délai dépassé. Vérifiez votre connexion.';
    if (msg.contains('socket'))    return 'Impossible de joindre le serveur.';
    if (msg.contains('connection')) return 'Pas de connexion réseau.';
    return 'Une erreur s\'est produite. Réessayez.';
  }
}