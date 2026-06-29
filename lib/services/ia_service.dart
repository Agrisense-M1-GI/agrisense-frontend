// lib/services/ia_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté au serveur Flask AgriSense IA Engine
//   URL racine : http://127.0.0.1:5000
//
//   GET  /api/ia/statut   → vérification disponibilité
//   POST /api/ia/analyser → diagnostic phytosanitaire
//   POST /api/ia/predire  → prédiction adéquation culture
// ─────────────────────────────────────────────────────────────────────────────
/*
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/image.dart'; // ResultatIA, ResultatPrediction, PredictionCulture

class IaService {
  /// URL racine du serveur Flask IA (distinct du backend Rust)
  /// Valeur par défaut : "http://127.0.0.1:5000"
  final String iaBaseUrl;

  const IaService({this.iaBaseUrl = 'http://127.0.0.1:5000'});

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ── GET /api/ia/statut ─────────────────────────────────────────────────────
  /// Vérifie que le serveur Flask est opérationnel.
  /// Retourne true si {"status": "online"} est reçu.
  Future<bool> isDisponible() async {
    try {
      final response = await http
          .get(
            Uri.parse('$iaBaseUrl/api/ia/statut'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] == 'online';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── POST /api/ia/analyser ──────────────────────────────────────────────────
  /// Lance le diagnostic phytosanitaire sur la dernière image du dossier.
  ///
  /// Paramètres :
  ///   [culture]       : nom de la culture ciblée (ex: "Tomate") — obligatoire
  ///   [dossierImages] : chemin local du dossier d'images               — optionnel
  ///                     (ex: "data/nodes/node_01", valeur par défaut côté
  ///                      serveur : "images_backend")
  ///
  /// Retourne un [ResultatIA] (cases A et B gérées via analyse_requise).
  /// Lance une [Exception] en cas d'erreur réseau ou de réponse inattendue.
  Future<ResultatIA> analyserImage({
    required String culture,
    String? dossierImages,
  }) async {
    final Map<String, dynamic> payload = {'culture': culture};
    if (dossierImages != null) payload['dossier_images'] = dossierImages;

    final response = await http
        .post(
          Uri.parse('$iaBaseUrl/api/ia/analyser'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['succes'] == true) {
        return ResultatIA.fromJson(data);
      }
      throw Exception("L'IA n'a pas pu analyser l'image.");
    }
    throw Exception('Erreur IA analyser : ${response.statusCode}');
  }

  // ── POST /api/ia/predire ───────────────────────────────────────────────────
  /// Évalue l'adéquation de cultures selon les métriques du terrain.
  ///
  /// Paramètres :
  ///   [metriques]     : relevés capteurs, ex:
  ///                     { "pH_sol": "5.5", "humidite_sol": "65%",
  ///                       "temperature_moyenne": "28°C", "texture": "Sableux" }
  ///                     — obligatoire
  ///   [dossierImages] : chemin du dossier contenant une photo du sol — optionnel
  ///
  /// Retourne un [ResultatPrediction] avec synthèse + liste triée de cultures.
  /// Lance une [Exception] en cas d'erreur réseau ou de réponse inattendue.
  Future<ResultatPrediction> predireCultures({
    required Map<String, String> metriques,
    String? dossierImages,
  }) async {
    final Map<String, dynamic> payload = {'metriques': metriques};
    if (dossierImages != null) payload['dossier_images'] = dossierImages;

    final response = await http
        .post(
          Uri.parse('$iaBaseUrl/api/ia/predire'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['succes'] == true) {
        return ResultatPrediction.fromJson(data);
      }
      throw Exception('Erreur dans la prédiction IA.');
    }
    throw Exception('Erreur IA predire : ${response.statusCode}');
  }
}*/
// lib/services/ia_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté au serveur Flask AgriSense IA Engine
//   URL racine : http://127.0.0.1:5000
//
//   GET  /api/ia/statut   → vérification disponibilité
//   POST /api/ia/analyser → diagnostic phytosanitaire
//   POST /api/ia/predire  → prédiction adéquation culture
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/image.dart'; // ResultatIA, ResultatPrediction, PredictionCulture

class IaService {
  /// URL racine du serveur Flask IA (distinct du backend Rust)
  /// Valeur par défaut : "http://127.0.0.1:5000"
  final String iaBaseUrl;

  const IaService({this.iaBaseUrl = 'http://127.0.0.1:5000'});

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ── GET /api/ia/statut ─────────────────────────────────────────────────────
  /// Vérifie que le serveur Flask est opérationnel.
  /// Retourne true si {"status": "online"} est reçu.
  Future<bool> isDisponible() async {
    try {
      final response = await http
          .get(
            Uri.parse('$iaBaseUrl/api/ia/statut'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] == 'online';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── POST /api/ia/analyser ──────────────────────────────────────────────────
  /// Lance le diagnostic phytosanitaire sur la dernière image du dossier.
  ///
  /// Paramètres :
  ///   [culture]       : nom de la culture ciblée (ex: "Tomate") — obligatoire
  ///   [dossierImages] : chemin local du dossier d'images               — optionnel
  ///                     (ex: "data/nodes/node_01", valeur par défaut côté
  ///                      serveur : "images_backend")
  ///
  /// Retourne un [ResultatIA] (cases A et B gérées via analyse_requise).
  /// Lance une [Exception] en cas d'erreur réseau ou de réponse inattendue.
  Future<ResultatIA> analyserImage({
    required String culture,
    String? dossierImages,
  }) async {
    final Map<String, dynamic> payload = {'culture': culture};
    if (dossierImages != null) payload['dossier_images'] = dossierImages;

    final response = await http
        .post(
          Uri.parse('$iaBaseUrl/api/ia/analyser'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['succes'] == true) {
        return ResultatIA.fromJson(data);
      }
      throw Exception("L'IA n'a pas pu analyser l'image.");
    }
    throw Exception('Erreur IA analyser : ${response.statusCode}');
  }

  // ── POST /api/ia/predire ───────────────────────────────────────────────────
  /// Évalue l'adéquation de cultures selon les métriques du terrain.
  ///
  /// Paramètres :
  ///   [metriques]     : relevés capteurs, ex:
  ///                     { "pH_sol": "5.5", "humidite_sol": "65%",
  ///                       "temperature_moyenne": "28°C", "texture": "Sableux" }
  ///                     — obligatoire
  ///   [dossierImages] : chemin du dossier contenant une photo du sol — optionnel
  ///
  /// Retourne un [ResultatPrediction] avec synthèse + liste triée de cultures.
  /// Lance une [Exception] en cas d'erreur réseau ou de réponse inattendue.
  Future<ResultatPrediction> predireCultures({
    required Map<String, String> metriques,
    String? dossierImages,
  }) async {
    final Map<String, dynamic> payload = {'metriques': metriques};
    if (dossierImages != null) payload['dossier_images'] = dossierImages;

    final response = await http
        .post(
          Uri.parse('$iaBaseUrl/api/ia/predire'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['succes'] == true) {
        return ResultatPrediction.fromJson(data);
      }
      throw Exception('Erreur dans la prédiction IA.');
    }
    throw Exception('Erreur IA predire : ${response.statusCode}');
  }
}