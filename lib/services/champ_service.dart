import 'dart:convert';
import 'package:agrisense/models/culture.dart';
import 'package:http/http.dart' as http;

import '../models/champ.dart';
import 'auth_service.dart';

class ChampService {
  final String baseUrl;
  final AuthService authService;

  ChampService({
    required this.baseUrl,
    required this.authService,
  });

  Future<List<ChampModel>> getChamps() async {
    final token = authService.token;

    final response = await http.get(
      Uri.parse('$baseUrl/champs'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data as List)
          .map((e) => ChampModel.fromJson(e))
          .toList();
    }

    throw Exception('Erreur chargement champs');
  }

  Future<ChampModel> updateChamp({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final token = authService.token;

    final response = await http.put(
      Uri.parse('$baseUrl/champs/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return ChampModel.fromJson(jsonDecode(response.body));
    }

    throw Exception('Erreur modification champ');
  }

  Future<ChampModel> createChamp({
  required String nom,
  String? description,
  String? localisation,
  required double superficie,
  double? latitude,
  double? longitude,
}) async {
  final token = authService.token;
  final response = await http.post(
    Uri.parse('$baseUrl/champs'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nom': nom,
      if (description != null) 'description': description,
      if (localisation != null) 'localisation': localisation,
      'superficie': superficie,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    }),
  );
  if (response.statusCode == 200) {
    return ChampModel.fromJson(jsonDecode(response.body));
  }
  throw Exception('Erreur création champ');
}

Future<void> createCulture({
  required String champId,
  required String nom,
  required String typeCulture,
  required String stadeCroissance,
  String? dateSemence,
  String? dateRecoltePrevue,
  String? notes,
}) async {
  final token = authService.token;
  final response = await http.post(
    Uri.parse('$baseUrl/champs/$champId/cultures'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nom': nom,
      'type_culture': typeCulture,
      'stade_croissance': stadeCroissance,
      if (dateSemence != null) 'date_semence': dateSemence,
      if (dateRecoltePrevue != null) 'date_recolte_prevue': dateRecoltePrevue,
      if (notes != null) 'notes': notes,
    }),
  );
  if (response.statusCode != 200) {
    throw Exception('Erreur création culture');
  }
}

Future<List<CultureModel>> getCultures(String champId) async {
  final token = authService.token;
  final response = await http.get(
    Uri.parse('$baseUrl/champs/$champId/cultures'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((e) => CultureModel.fromJson(e)).toList();
  }
  throw Exception('Erreur chargement cultures');
}

Future<void> updateCulture({
  required String champId,
  required String cultureId,
  required Map<String, dynamic> data,
}) async {
  final token = authService.token;
  final response = await http.put(
    Uri.parse('$baseUrl/champs/$champId/cultures/$cultureId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );
  if (response.statusCode != 200) {
    throw Exception('Erreur modification culture');
  }
}

Future<void> deleteCulture({
  required String champId,
  required String cultureId,
}) async {
  final token = authService.token;
  final response = await http.delete(
    Uri.parse('$baseUrl/champs/$champId/cultures/$cultureId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('Erreur suppression culture');
  }
}

Future<void> deleteChamp(String id) async {
  final token = authService.token;
  final response = await http.delete(
    Uri.parse('$baseUrl/champs/$id'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('Erreur suppression champ');
  }
}
}