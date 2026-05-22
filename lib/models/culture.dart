class CultureModel {
  final String id;
  final String nom;
  final String typeCulture;
  final String stadeCroissance;
  final String? notes;

  CultureModel({
    required this.id,
    required this.nom,
    required this.typeCulture,
    required this.stadeCroissance,
    this.notes,
  });

  factory CultureModel.fromJson(Map<String, dynamic> json) {
    return CultureModel(
      id: json['id'],
      nom: json['nom'],
      typeCulture: json['type_culture'],
      stadeCroissance: json['stade_croissance'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'type_culture': typeCulture,
      'stade_croissance': stadeCroissance,
      'notes': notes,
    };
  }
}