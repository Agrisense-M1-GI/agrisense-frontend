class ApiConfig {
  // ── Modifie cette URL selon ton environnement ──────────────
  // En développement local (téléphone sur le même réseau WiFi) :
  //   Remplace 192.168.x.x par l'IP locale de ton PC
  //   Lance "ipconfig" (Windows) ou "ifconfig" (Mac/Linux) pour trouver ton IP

  // Émulateur Android → utilise 10.0.2.2
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Téléphone physique → utilise l'IP locale de ton PC
  static const String baseUrl = 'http://172.22.193.179:8080/api';

  // Production → remplace par ton domaine
  // static const String baseUrl = 'https://ton-domaine.com/api';

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
}