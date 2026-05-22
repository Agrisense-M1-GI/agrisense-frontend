class ChampModel {
  final String id;
  final String nom;
  final String? description;
  final String? localisation;
  final double superficie;
  final double? latitude;
  final double? longitude;

  ChampModel({
    required this.id,
    required this.nom,
    this.description,
    this.localisation,
    required this.superficie,
    this.latitude,
    this.longitude,
  });

  factory ChampModel.fromJson(Map<String, dynamic> json) {
    return ChampModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      localisation: json['localisation'],
      superficie: (json['superficie'] as num).toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'localisation': localisation,
      'superficie': superficie,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}