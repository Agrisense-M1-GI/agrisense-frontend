// lib/services/image_service.dart
import 'dart:convert';
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
}