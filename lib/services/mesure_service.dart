import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MesureModel {
  final String   id;
  final String   noeudCapteurId;
  final double   valeur;
  final DateTime dateMesure;

  const MesureModel({
    required this.id,
    required this.noeudCapteurId,
    required this.valeur,
    required this.dateMesure,
  });

  factory MesureModel.fromJson(Map<String, dynamic> json) => MesureModel(
        id:             json['id']               as String,
        noeudCapteurId: json['noeud_capteur_id'] as String,
        valeur:         (json['valeur'] as num).toDouble(),
        dateMesure:     DateTime.parse(json['date_mesure'] as String),
      );
}

class MesureService extends ChangeNotifier {
  String? _token;

  MesureService({String? token}) : _token = token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Dernière humidité d'un capteur ────────────────────────────────────────
  Future<MesureModel?> getDerniereHumidite(String capteurId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.humiditeLastParCapteur(capteurId)),
              headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return MesureModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null; // 404 ou autre → pas de mesure
    } catch (_) {
      return null;
    }
  }

  // ── Dernière température d'un capteur ─────────────────────────────────────
  Future<MesureModel?> getDerniereTemperature(String capteurId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.temperatureLastParCapteur(capteurId)),
              headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return MesureModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Historique humidité d'un capteur ──────────────────────────────────────
  Future<List<MesureModel>> getHistoriqueHumidite(String capteurId,
      {String? debut, String? fin}) async {
    try {
      final url = ApiConfig.humiditeParCapteurFiltre(capteurId,
          debut: debut, fin: fin);
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json
            .map((e) => MesureModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Historique température d'un capteur ───────────────────────────────────
  Future<List<MesureModel>> getHistoriqueTemperature(String capteurId,
      {String? debut, String? fin}) async {
    try {
      final url = ApiConfig.temperatureParCapteurFiltre(capteurId,
          debut: debut, fin: fin);
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json
            .map((e) => MesureModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Moyennes sur tous les capteurs ────────────────────────────────────────
  Future<Map<String, double?>> getMoyennesCapteurs(
      List<String> capteurIds) async {
    double? humMoy, tempMoy;
    int humCount = 0, tempCount = 0;

    final results = await Future.wait(capteurIds.map((id) async {
      final hum  = await getDerniereHumidite(id);
      final temp = await getDerniereTemperature(id);
      return {'hum': hum?.valeur, 'temp': temp?.valeur};
    }));

    for (final r in results) {
      if (r['hum']  != null) { humMoy  = (humMoy  ?? 0) + r['hum']!;  humCount++;  }
      if (r['temp'] != null) { tempMoy = (tempMoy ?? 0) + r['temp']!; tempCount++; }
    }

    return {
      'humidite':    humCount  > 0 ? humMoy!  / humCount  : null,
      'temperature': tempCount > 0 ? tempMoy! / tempCount : null,
    };
  }
}