// Modèle aligné sur GET /api/seuils
//
// {
//   "id": "550e8400-...",
//   "utilisateur_id": "...",
//   "valeur_min": 30.0,
//   "valeur_max": 70.0,
//   "irrigation_auto": true,
//   "created_at": "...",
//   "updated_at": "..."
// }

class SeuilModel {
  final String id;
  final String utilisateurId;
  final double valeurMin;
  final double valeurMax;
  final bool irrigationAuto;
  final String? createdAt;
  final String? updatedAt;

  const SeuilModel({
    required this.id,
    required this.utilisateurId,
    required this.valeurMin,
    required this.valeurMax,
    required this.irrigationAuto,
    this.createdAt,
    this.updatedAt,
  });

  factory SeuilModel.fromJson(Map<String, dynamic> json) {
    return SeuilModel(
      id:             json['id']             as String,
      utilisateurId:  json['utilisateur_id'] as String,
      valeurMin:      (json['valeur_min']    as num).toDouble(),
      valeurMax:      (json['valeur_max']    as num).toDouble(),
      irrigationAuto: json['irrigation_auto'] as bool? ?? false,
      createdAt:      json['created_at']     as String?,
      updatedAt:      json['updated_at']     as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'utilisateur_id':  utilisateurId,
    'valeur_min':      valeurMin,
    'valeur_max':      valeurMax,
    'irrigation_auto': irrigationAuto,
    'created_at':      createdAt,
    'updated_at':      updatedAt,
  };

  // Valeur de seuil critique à afficher dans l'UI (on utilise valeur_min)
  double get seuilCritique => valeurMin;
}