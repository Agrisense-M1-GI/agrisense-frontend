import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UtilisateurService
// Utilise UserModel (lib/models/user_model.dart) — pas de doublon de modèle.
//
// Endpoints :
//   GET /api/utilisateurs/me  → infos utilisateur connecté
//   PUT /api/utilisateurs/me  → mise à jour profil
// ─────────────────────────────────────────────────────────────────────────────
class UtilisateurService extends ChangeNotifier {
  final String baseUrl;
  String? _token;

  UtilisateurService({required this.baseUrl, String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET /api/utilisateurs/me ──────────────────────────────────────────────
  // Retourne null si non authentifié ou introuvable → dashboard reste en démo
  Future<UserModel?> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/utilisateurs/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 401 || response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Erreur chargement utilisateur (${response.statusCode})');
    }
  }

  // ── PUT /api/utilisateurs/me ──────────────────────────────────────────────
  Future<UserModel> updateMe({
    required String nom,
    required String prenom,
    String? profession,
    String? email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/utilisateurs/me'),
      headers: _headers,
      body: jsonEncode({
        'nom':    nom,
        'prenom': prenom,
        if (profession != null) 'profession': profession,
        if (email != null)      'email':      email,
      }),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié.');
    } else {
      throw Exception('Erreur mise à jour profil (${response.statusCode})');
    }
  }
}