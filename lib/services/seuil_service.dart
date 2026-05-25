import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/seuil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SeuilService
// Endpoints :
//   GET  /api/seuils  → récupère le seuil de l'utilisateur connecté
//   POST /api/seuils  → crée ou remplace le seuil (UPSERT)
// Auth : JWT via Authorization: Bearer <token>
// ─────────────────────────────────────────────────────────────────────────────

class SeuilService extends ChangeNotifier {
  final String baseUrl;
  String? _token;

  SeuilService({required this.baseUrl, String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET /api/seuils ───────────────────────────────────────────────────────
  Future<SeuilModel?> getSeuil() async {
    final response = await http.get(
      Uri.parse('$baseUrl/seuils'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return SeuilModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null; // Aucun seuil configuré → fallback statique
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur chargement seuil (${response.statusCode})');
    }
  }

  // ── POST /api/seuils (UPSERT) ─────────────────────────────────────────────
  Future<SeuilModel> saveSeuil({
    required double valeurMin,
    required double valeurMax,
    required bool irrigationAuto,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/seuils'),
      headers: _headers,
      body: jsonEncode({
        'valeur_min':      valeurMin,
        'valeur_max':      valeurMax,
        'irrigation_auto': irrigationAuto,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SeuilModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié.');
    } else {
      final err = (jsonDecode(response.body) as Map<String, dynamic>)['error']
          ?? 'Données invalides';
      throw Exception(err);
    }
  }
}