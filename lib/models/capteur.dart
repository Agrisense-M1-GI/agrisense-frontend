// Modèle aligné sur la réponse de GET /api/capteurs et GET /api/capteurs/:id
//
// Réponse API :
// {
//   "id": "550e8400-...",
//   "nom": "Capteur Nord-Ouest",
//   "type_capteur": "Humidité + Température",
//   "longitude": 1.2345,
//   "latitude": 47.5789,
//   "batterie": 85,
//   "etat": "actif",
//   "surface_couverte": 2.5,
//   "derniere_connexion": "2026-05-13T12:45:00Z",
//   "created_at": "2026-05-10T10:00:00Z",
//   "updated_at": "2026-05-13T12:45:00Z"
// }

class CapteurModel {
  final String id;
  final String nom;
  final String? typeCapteur;
  final double? longitude;
  final double? latitude;
  final int? batterie;
  final String etat; // 'actif' | 'inactif'
  final double? surfaceCouverte;
  final String? derniereConnexion;
  final String? createdAt;
  final String? updatedAt;

  const CapteurModel({
    required this.id,
    required this.nom,
    this.typeCapteur,
    this.longitude,
    this.latitude,
    this.batterie,
    required this.etat,
    this.surfaceCouverte,
    this.derniereConnexion,
    this.createdAt,
    this.updatedAt,
  });

  factory CapteurModel.fromJson(Map<String, dynamic> json) {
    return CapteurModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      typeCapteur: json['type_capteur'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      batterie: json['batterie'] as int?,
      etat: json['etat'] as String? ?? 'inactif',
      surfaceCouverte: (json['surface_couverte'] as num?)?.toDouble(),
      derniereConnexion: json['derniere_connexion'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'type_capteur': typeCapteur,
        'longitude': longitude,
        'latitude': latitude,
        'batterie': batterie,
        'etat': etat,
        'surface_couverte': surfaceCouverte,
        'derniere_connexion': derniereConnexion,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}