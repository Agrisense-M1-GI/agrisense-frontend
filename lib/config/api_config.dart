// lib/config/api_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// Configuration centralisée de l'URL du backend.
//
// Deux niveaux, dans cet ordre de priorité :
//  1. Override utilisateur sauvegardé localement (écran "Adresse du serveur")
//  2. Valeur de build fournie via --dart-define=API_BASE_URL=...
//     (sinon, valeur de secours codée ci-dessous pour le dev quotidien)
//
// IMPORTANT : ApiConfig.init() doit être appelé une fois dans main(),
// avant runApp(), pour charger l'override éventuel depuis le disque.
//
// ⚠️  RÈGLE D'UTILISATION :
//   baseUrl  = "http://X.X.X.X:8080/api"  → appels API  (/capteurs, /images…)
//   rootUrl  = "http://X.X.X.X:8080"      → fichiers statiques (/fichiers/…)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const String _prefsKey = 'agrisense_api_base_url';

  /// Valeur de build : passée au moment du `flutter build`/`flutter run`
  /// avec --dart-define=API_BASE_URL=http://X.X.X.X:8080/api
  /// Si absente, retombe sur cette IP de dev par défaut.
  static const String _buildDefault = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.177.138.179:8080/api',
  );

  static String? _override;

  /// À appeler une seule fois au démarrage de l'app, avant runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _override = saved.trim();
    }
  }

  /// URL de base de l'API : "http://X.X.X.X:8080/api"
  /// → À utiliser pour tous les appels REST
  static String get baseUrl => _override ?? _buildDefault;

  /// URL racine du serveur (sans /api) : "http://X.X.X.X:8080"
  /// → À utiliser pour construire les URLs /fichiers/...
  static String get rootUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Valeur de build, utile pour afficher "(par défaut)" dans l'UI.
  static String get buildDefault => _buildDefault;

  /// true si une valeur a été configurée manuellement par l'utilisateur.
  static bool get hasOverride => _override != null;

  /// Change l'URL du serveur et la persiste sur l'appareil.
  /// Ne prend effet sur les services déjà créés qu'après redémarrage de l'app.
  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      _override = null;
      await prefs.remove(_prefsKey);
    } else {
      _override = clean;
      await prefs.setString(_prefsKey, clean);
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
  static String get register => '$baseUrl/auth/register';
  static String get login    => '$baseUrl/auth/login';
  static String get me       => '$baseUrl/utilisateurs/me';
  static String get updateMe => '$baseUrl/utilisateurs/me';

  // ── Champs ──────────────────────────────────────────────────────────────────
  static String get champs                    => '$baseUrl/champs';
  static String champById(String id)          => '$baseUrl/champs/$id';
  static String culturesParChamp(String id)   => '$baseUrl/champs/$id/cultures';
  static String cultureById(String champId, String cultureId)
      => '$baseUrl/champs/$champId/cultures/$cultureId';

  // ── Capteurs ────────────────────────────────────────────────────────────────
  static String get capteurs              => '$baseUrl/capteurs';
  static String capteurById(String id)    => '$baseUrl/capteurs/$id';
  static String capteurEtat(String id)    => '$baseUrl/capteurs/$id/etat';

  // ── Seuils ──────────────────────────────────────────────────────────────────
  static String get seuils => '$baseUrl/seuils';

  // ── Humidité ────────────────────────────────────────────────────────────────
  static String get humidite => '$baseUrl/humidite';

  static String humiditeParCapteur(String id) => '$baseUrl/humidite/$id';

  static String humiditeParCapteurFiltre(String id,
      {String? debut, String? fin}) {
    final params = <String>[];
    if (debut != null) params.add('debut=$debut');
    if (fin   != null) params.add('fin=$fin');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/humidite/$id$query';
  }

  static String humiditeLastParCapteur(String id)
      => '$baseUrl/humidite/$id/derniere';

  // ── Température ─────────────────────────────────────────────────────────────
  static String get temperature => '$baseUrl/temperature';

  static String temperatureParCapteur(String id) => '$baseUrl/temperature/$id';

  static String temperatureParCapteurFiltre(String id,
      {String? debut, String? fin}) {
    final params = <String>[];
    if (debut != null) params.add('debut=$debut');
    if (fin   != null) params.add('fin=$fin');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/temperature/$id$query';
  }

  static String temperatureLastParCapteur(String id)
      => '$baseUrl/temperature/$id/derniere';

  // ── Images ──────────────────────────────────────────────────────────────────
  static String get images                      => '$baseUrl/images';
  static String imagesDuCapteur(String id)      => '$baseUrl/images/$id';
  static String imagesNonTraitees(String id)    => '$baseUrl/images/$id/non-traitees';
  static String imageDetail(String id)          => '$baseUrl/images/detail/$id';

  // ── Capture (demande via LoRa) ───────────────────────────────────────────────
  static String get capturer                    => '$baseUrl/capturer';
  static String capturerStatut(String jobId)    => '$baseUrl/capturer/$jobId';
  static String get capturerHistorique          => '$baseUrl/capturer/historique';

  // ── Nœuds (communication Pi → backend) ─────────────────────────────────────
  static String nodeMode(String nodeId)         => '$baseUrl/node/$nodeId/mode';
  static String get nodeModeGlobal              => '$baseUrl/node/mode';
  static String nodeUploadImage(String nodeId)  => '$baseUrl/node/$nodeId/upload/image';
  static String nodeUploadMetrics(String nodeId)=> '$baseUrl/node/$nodeId/upload/metrics';

  // ── Fichiers statiques (images stockées) ───────────────────────────────────
  /// Construit l'URL d'accès à une image stockée depuis son chemin brut.
  ///
  /// Ex: "data/nodes/node_01/images/node_01_20260604.jpg"
  ///  →  "http://192.168.1.42:8080/fichiers/node_01/images/node_01_20260604.jpg"
  static String fichierImage(String cheminStockage) {
    final relativePath = cheminStockage.replaceFirst('data/nodes/', '');
    return '$rootUrl/fichiers/$relativePath';
  }

  /// Construit l'URL d'accès au JSON de métriques d'une image.
  ///
  /// Ex: nodeId = "noode_first_001", timestamp = "20260604_153000"
  ///  →  "http://192.168.1.42:8080/fichiers/noode_first_001/metrics/20260604_153000.json"
  static String fichierMetrics(String nodeId, String timestamp) {
    return '$rootUrl/fichiers/$nodeId/metrics/$timestamp.json';
  }
}