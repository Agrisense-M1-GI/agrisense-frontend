import 'dart:convert';
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
}