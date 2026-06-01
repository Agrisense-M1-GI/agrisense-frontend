class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String profession;
  final String statut;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.profession,
    required this.statut,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:         json['id']         as String? ?? '',
      email:      json['email']      as String? ?? '',
      nom:        json['nom']        as String? ?? '',
      prenom:     json['prenom']     as String? ?? '',
      profession: json['profession'] as String? ?? '',
      statut:     json['statut']     as String? ?? 'actif',
      createdAt:  json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'email':      email,
    'nom':        nom,
    'prenom':     prenom,
    'profession': profession,
    'statut':     statut,
    'created_at': createdAt,
  };

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }

  UserModel copyWith({
    String? email,
    String? nom,
    String? prenom,
    String? profession,
    String? statut,
  }) {
    return UserModel(
      id:         id,
      email:      email      ?? this.email,
      nom:        nom        ?? this.nom,
      prenom:     prenom     ?? this.prenom,
      profession: profession ?? this.profession,
      statut:     statut     ?? this.statut,
      createdAt:  createdAt,
    );
  }

  // ✅ Un utilisateur valide doit avoir un id et un email non vides
  bool get estValide => id.isNotEmpty && email.isNotEmpty;
}

class AuthResponse {
  final String token;
  final UserModel utilisateur;

  const AuthResponse({
    required this.token,
    required this.utilisateur,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Si 'token' ou 'utilisateur' est absent → lève une exception
    // que login() interceptera pour retourner false
    final token = json['token'] as String?;
    final userJson = json['utilisateur'];

    if (token == null || token.isEmpty || userJson == null) {
      throw const FormatException('Réponse API invalide : token ou utilisateur manquant');
    }

    return AuthResponse(
      token:       token,
      utilisateur: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }
}