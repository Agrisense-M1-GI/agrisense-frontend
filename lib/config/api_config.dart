/*class ApiConfig {
  
  // ── Endpoints ─────────────────────────────────────────────
  static const String register       = '$baseUrl/auth/register';
  static const String login          = '$baseUrl/auth/login';
  static const String me             = '$baseUrl/utilisateurs/me';
  static const String updateMe       = '$baseUrl/utilisateurs/me';
  static const String champs         = '$baseUrl/champs';
  static const String capteurs       = '$baseUrl/capteurs';
  static const String seuils         = '$baseUrl/seuils';

  // ── Helper : URL d'un champ spécifique ────────────────────
  static String champById(String id) => '$baseUrl/champs/$id';
  static String culturesParChamp(String champId) =>
      '$baseUrl/champs/$champId/cultures';
  static String capteurById(String id) => '$baseUrl/capteurs/$id';
  static String capteurEtat(String id) => '$baseUrl/capteurs/$id/etat';




  // ── Images ───────────────────────────────────────────────
  static const String images                   = '$baseUrl/images';
  static String imagesDuCapteur(String id)     => '$baseUrl/images/$id';
  static String imagesNonTraitees(String id)   => '$baseUrl/images/$id/non-traitees';
  static String imageDetail(String id)         => '$baseUrl/images/detail/$id';
}*/

class ApiConfig {
  static const String baseUrl = 'http://10.231.48.179:8080/api';

  // ── Auth ──────────────────────────────────────────────────
  static const String register = '$baseUrl/auth/register';
  static const String login    = '$baseUrl/auth/login';
  static const String me       = '$baseUrl/utilisateurs/me';
  static const String updateMe = '$baseUrl/utilisateurs/me';

  // ── Champs ────────────────────────────────────────────────
  static const String champs = '$baseUrl/champs';
  static String champById(String id)        => '$baseUrl/champs/$id';
  static String culturesParChamp(String id) => '$baseUrl/champs/$id/cultures';

  // ── Capteurs ──────────────────────────────────────────────
  static const String capteurs = '$baseUrl/capteurs';
  static String capteurById(String id)  => '$baseUrl/capteurs/$id';
  static String capteurEtat(String id)  => '$baseUrl/capteurs/$id/etat';

  // ── Seuils ────────────────────────────────────────────────
  static const String seuils = '$baseUrl/seuils';

  // ── Humidité ──────────────────────────────────────────────
  static const String humidite                         = '$baseUrl/humidite';
  static String humiditeParCapteur(String id)          => '$baseUrl/humidite/$id';
  static String humiditeParCapteurFiltre(String id,
      {String? debut, String? fin}) {
    final params = <String>[];
    if (debut != null) params.add('debut=$debut');
    if (fin   != null) params.add('fin=$fin');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/humidite/$id$query';
  }
  static String humiditeLastParCapteur(String id)      => '$baseUrl/humidite/$id/derniere';

  // ── Température ───────────────────────────────────────────
  static const String temperature                      = '$baseUrl/temperature';
  static String temperatureParCapteur(String id)       => '$baseUrl/temperature/$id';
  static String temperatureParCapteurFiltre(String id,
      {String? debut, String? fin}) {
    final params = <String>[];
    if (debut != null) params.add('debut=$debut');
    if (fin   != null) params.add('fin=$fin');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/temperature/$id$query';
  }
  static String temperatureLastParCapteur(String id)   => '$baseUrl/temperature/$id/derniere';

  // ── Images ────────────────────────────────────────────────
  static const String images                           = '$baseUrl/images';
  static String imagesDuCapteur(String id)             => '$baseUrl/images/$id';
  static String imagesNonTraitees(String id)           => '$baseUrl/images/$id/non-traitees';
  static String imageDetail(String id)                 => '$baseUrl/images/detail/$id';
}
