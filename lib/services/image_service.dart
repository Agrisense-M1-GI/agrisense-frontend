// lib/services/image_service.dart
/*import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/image.dart';
import 'auth_service.dart';

class ImageService extends ChangeNotifier {
  final AuthService _authService;

  ImageService({required AuthService authService})
      : _authService = authService;

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET /images/:capteur_id ───────────────────────────────
  Future<List<ImageApi>> getImages(String capteurId) async {
    final response = await http
        .get(Uri.parse(ApiConfig.imagesDuCapteur(capteurId)), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => ImageApi.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur chargement images (${response.statusCode})');
    }
  }

  // ── GET /images/:capteur_id/non-traitees ──────────────────
  Future<List<ImageApi>> getImagesNonTraitees(String capteurId) async {
    final response = await http
        .get(Uri.parse(ApiConfig.imagesNonTraitees(capteurId)), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => ImageApi.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erreur images non traitées (${response.statusCode})');
    }
  }

  // ── GET /images/detail/:id ───────────────────────────────
  Future<ImageApi?> getImageDetail(String imageId) async {
    final response = await http
        .get(Uri.parse(ApiConfig.imageDetail(imageId)), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ImageApi.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Erreur détail image (${response.statusCode})');
    }
  }

  // ── GET images de plusieurs capteurs ─────────────────────
  Future<List<ImageApi>> getImagesMultiCapteurs(List<String> capteurIds) async {
    final futures = capteurIds.map(
      (id) => getImages(id).catchError((_) => <ImageApi>[]),
    );
    final results = await Future.wait(futures);
    final all = results.expand((list) => list).toList();
    all.sort((a, b) => b.dateCapture.compareTo(a.dateCapture));
    return all;
  }

  // ── POST /images (capteur → serveur, pas d'auth requise) ──
  Future<ImageApi> postImage({
    required String noeudCapteurId,
    required String code,
    required int longueur,
    required int largeur,
    required String cheminStockage,
    required int tailleOctets,
    String format = 'jpg',
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.images),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'noeud_capteur_id': noeudCapteurId,
            'code':             code,
            'longueur':         longueur,
            'largeur':          largeur,
            'chemin_stockage':  cheminStockage,
            'taille_octets':    tailleOctets,
            'format':           format,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return ImageApi.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Erreur envoi image (${response.statusCode})');
    }
  }
}*/
// ─────────────────────────────────────────────────────────────────────────────
// image_service.dart
// Connecté à :
//   GET  /api/images/:capteur_id          → liste des images d'un capteur
//   GET  /api/images/:capteur_id/non-traitees → images non analysées
//   GET  /api/images/detail/:id           → détails d'une image
// ─────────────────────────────────────────────────────────────────────────────
/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/image.dart';
import '../models/capteur.dart';

class ImageService {
  final String baseUrl;   // ex: "http://192.168.1.42:8080"
  final String Function() getToken;

  const ImageService({required this.baseUrl, required this.getToken});

  Map<String, String> get _headers => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${getToken()}',
  };

  // ── GET /api/images/:capteur_id ────────────────────────────────────────────
  /// Récupère toutes les images d'un capteur.
  /// [capteur] est fourni pour renseigner capteurNom dans le modèle.
  Future<List<CaptureImage>> getImagesCapteur(CapteurModel capteur) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/images/${capteur.id}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((j) => CaptureImage.fromJson(
                j as Map<String, dynamic>,
                capteurNom: capteur.nom,
              ))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Erreur chargement images : ${response.statusCode}');
  }

  // ── GET /api/images/:capteur_id/non-traitees ───────────────────────────────
  /// Images non encore analysées par l'IA (est_traitee = false).
  Future<List<CaptureImage>> getImagesNonTraitees(CapteurModel capteur) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/images/${capteur.id}/non-traitees'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((j) => CaptureImage.fromJson(
                j as Map<String, dynamic>,
                capteurNom: capteur.nom,
              ))
          .toList();
    }
    return [];
  }

  // ── GET /api/images/detail/:id ─────────────────────────────────────────────
  Future<CaptureImage> getImageDetail(
      String imageId, String capteurNom) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/images/detail/$imageId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return CaptureImage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        capteurNom: capteurNom,
      );
    }
    throw Exception('Image introuvable');
  }

  /// Construit l'URL HTTP d'affichage depuis un chemin de stockage
  String buildImageUrl(String cheminStockage) {
    final relativePath = cheminStockage.replaceFirst('data/nodes/', '');
    return '$baseUrl/fichiers/$relativePath';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ia_service.dart
// Connecté à :
//   GET  http://127.0.0.1:5000/api/ia/statut   → vérification disponibilité
//   POST http://127.0.0.1:5000/api/ia/analyser → diagnostic phytosanitaire
//   POST http://127.0.0.1:5000/api/ia/predire  → prédiction adéquation culture
// ─────────────────────────────────────────────────────────────────────────────

class IaService {
  /// URL du serveur Flask IA (distinct du backend Rust)
  final String iaBaseUrl; // ex: "http://127.0.0.1:5000"

  const IaService({required this.iaBaseUrl});

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ── GET /api/ia/statut ─────────────────────────────────────────────────────
  Future<bool> isDisponible() async {
    try {
      final response = await http
          .get(Uri.parse('$iaBaseUrl/api/ia/statut'), headers: _headers)
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
  /// Lance le diagnostic IA sur la dernière image du dossier du capteur.
  ///
  /// [culture]       : nom de la culture ciblée (ex: "Tomate")
  /// [dossierImages] : chemin extrait du cheminStockage de l'image
  ///                   (ex: "data/nodes/node_01")
  Future<ResultatIA> analyserImage({
    required String culture,
    required String dossierImages,
  }) async {
    final body = jsonEncode({
      'culture':        culture,
      'dossier_images': dossierImages,
    });

    final response = await http
        .post(
          Uri.parse('$iaBaseUrl/api/ia/analyser'),
          headers: _headers,
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['succes'] == true) {
        return ResultatIA.fromJson(data);
      }
      throw Exception('L\'IA n\'a pas pu analyser l\'image.');
    }
    throw Exception('Erreur IA analyser : ${response.statusCode}');
  }

  // ── POST /api/ia/predire ───────────────────────────────────────────────────
  /// Évalue l'adéquation de cultures selon les métriques du terrain.
  ///
  /// [metriques] : Map des relevés capteurs
  ///   ex: { "pH_sol": "5.5", "humidite_sol": "65%", "temperature_moyenne": "28°C" }
  /// [dossierImages] : optionnel, dossier d'une photo du sol (depuis cheminStockage)
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
// lib/services/image_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté à :
//   GET  /api/images/:capteur_id              → liste des images d'un capteur
//   GET  /api/images/:capteur_id/non-traitees → images non analysées
//   GET  /api/images/detail/:id               → détails d'une image
// ─────────────────────────────────────────────────────────────────────────────
// lib/services/image_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté à :
//   GET  /api/images/:capteur_id              → liste des images d'un capteur
//   GET  /api/images/:capteur_id/non-traitees → images non analysées
//   GET  /api/images/detail/:id               → détails d'une image
//
// ⚠️  ApiConfig.baseUrl  = "http://X.X.X.X:8080/api"  (avec /api)
//     ApiConfig.rootUrl  = "http://X.X.X.X:8080"       (sans /api)
//
// Règle : appels API   → ApiConfig.baseUrl  (on N'ajoute PAS /api en plus)
//         fichiers     → ApiConfig.rootUrl  + /fichiers/...
// ─────────────────────────────────────────────────────────────────────────────
// lib/services/image_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté à :
//   GET  /api/images/:capteur_id              → liste des images d'un capteur
//   GET  /api/images/:capteur_id/non-traitees → images non analysées
//   GET  /api/images/detail/:id               → détails d'une image
//
// ⚠️  ApiConfig.baseUrl  = "http://X.X.X.X:8080/api"  (avec /api)
//     ApiConfig.rootUrl  = "http://X.X.X.X:8080"       (sans /api)
//
// Règle : appels API   → ApiConfig.baseUrl  (on N'ajoute PAS /api en plus)
//         fichiers     → ApiConfig.rootUrl  + /fichiers/...
// ─────────────────────────────────────────────────────────────────────────────
// lib/services/image_service.dart
// (en-tête de commentaires inchangé)

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/image.dart';
import '../models/capteur.dart';
import 'auth_service.dart';

class ImageService {                                    // ← plus de "extends ChangeNotifier"
  final AuthService _authService;

  ImageService({required AuthService authService})
      : _authService = authService;

  String get _apiUrl => ApiConfig.baseUrl;
  String get _fileUrl => ApiConfig.rootUrl;

  Map<String, String> get _headers {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<CaptureImage>> getImagesCapteur(CapteurModel capteur) async {
    final url = Uri.parse('$_apiUrl/images/${capteur.id}');
    final response = await http
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      final images = data
          .map((j) => CaptureImage.fromJson(
                j as Map<String, dynamic>,
                capteurNom: capteur.nom,
                baseUrl: _fileUrl,
                zone: capteur.nom,
              ))
          .toList();

      images.sort((a, b) {
        if (a.dateCapture == null && b.dateCapture == null) return 0;
        if (a.dateCapture == null) return 1;
        if (b.dateCapture == null) return -1;
        return b.dateCapture!.compareTo(a.dateCapture!);
      });

      return images;
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Erreur chargement images : ${response.statusCode}');
  }

  Future<List<CaptureImage>> getImagesNonTraitees(CapteurModel capteur) async {
    final url = Uri.parse('$_apiUrl/images/${capteur.id}/non-traitees');
    final response = await http
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((j) => CaptureImage.fromJson(
                j as Map<String, dynamic>,
                capteurNom: capteur.nom,
                baseUrl: _fileUrl,
                zone: capteur.nom,
              ))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Erreur images non traitées : ${response.statusCode}');
  }

  Future<CaptureImage> getImageDetail(String imageId, String capteurNom) async {
    final url = Uri.parse('$_apiUrl/images/detail/$imageId');
    final response = await http
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return CaptureImage.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        capteurNom: capteurNom,
        baseUrl: _fileUrl,
      );
    } else if (response.statusCode == 404) {
      throw Exception('Image introuvable');
    }
    throw Exception('Erreur détail image : ${response.statusCode}');
  }

  String buildImageUrl(String cheminStockage) {
    final relativePath = cheminStockage.replaceFirst('data/nodes/', '');
    return '$_fileUrl/fichiers/$relativePath';
  }
}