import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/capteur.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CapteurService
// Endpoints utilisés :
//   GET    /api/capteurs          → liste tous les capteurs
//   GET    /api/capteurs/:id      → détail d'un capteur
//   POST   /api/capteurs          → créer un capteur
//   PATCH  /api/capteurs/:id/etat → mettre à jour l'état du capteur
// Auth : JWT envoyé dans Authorization: Bearer <token>
// ─────────────────────────────────────────────────────────────────────────────

class CapteurService extends ChangeNotifier {
  final String baseUrl;

  // Le token JWT doit être fourni (via AuthService ou SharedPreferences)
  String? _token;

  CapteurService({required this.baseUrl, String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  // ── Headers avec auth ─────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── GET /api/capteurs ─────────────────────────────────────────────────────
  Future<List<CapteurModel>> getCapteurs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/capteurs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => CapteurModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié. Veuillez vous reconnecter.');
    } else {
      throw Exception(
        'Erreur lors du chargement des capteurs (${response.statusCode})',
      );
    }
  }

  // ── GET /api/capteurs/:id ─────────────────────────────────────────────────
  Future<CapteurModel> getCapteur(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/capteurs/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return CapteurModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw Exception('Capteur introuvable');
    } else {
      throw Exception(
        'Erreur lors du chargement du capteur (${response.statusCode})',
      );
    }
  }

  // ── POST /api/capteurs ────────────────────────────────────────────────────
  Future<CapteurModel> createCapteur({
    required String nom,
    String? typeCapteur,
    double? latitude,
    double? longitude,
    int batterie = 100,
    double? surfaceCouverte,
  }) async {
    final body = jsonEncode({
      'nom': nom,
      if (typeCapteur != null) 'type_capteur': typeCapteur,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'batterie': batterie,
      if (surfaceCouverte != null) 'surface_couverte': surfaceCouverte,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/capteurs'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CapteurModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié.');
    } else {
      final err = jsonDecode(response.body)['error'] ?? 'Données invalides';
      throw Exception(err);
    }
  }

  // ── PATCH /api/capteurs/:id/etat ──────────────────────────────────────────
  Future<CapteurModel> updateEtat({
    required String id,
    required String etat,
    int? batterie,
    String? derniereConnexion,
  }) async {
    final body = jsonEncode({
      'etat': etat,
      if (batterie != null) 'batterie': batterie,
      if (derniereConnexion != null)
        'derniere_connexion': derniereConnexion,
    });

    final response = await http.patch(
      Uri.parse('$baseUrl/capteurs/$id/etat'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return CapteurModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié.');
    } else if (response.statusCode == 404) {
      throw Exception('Capteur introuvable');
    } else {
      throw Exception(
        'Erreur mise à jour état (${response.statusCode})',
      );
    }
  }
}