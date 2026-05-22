// ============================================================
// lib/models/user_model.dart
// Modèle utilisateur — calqué exactement sur la réponse API Rust
// ============================================================

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

  // ── Depuis JSON (réponse API) ──────────────────────────────
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

  // ── Vers JSON (stockage local) ─────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':         id,
    'email':      email,
    'nom':        nom,
    'prenom':     prenom,
    'profession': profession,
    'statut':     statut,
    'created_at': createdAt,
  };

  // ── Nom complet ────────────────────────────────────────────
  String get nomComplet => '$prenom $nom';

  // ── Initiales pour l'avatar ────────────────────────────────
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n';
  }

  // ── Copie avec modification ────────────────────────────────
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
}

// ── Modèle réponse auth (login + register) ─────────────────────
class AuthResponse {
  final String    token;
  final UserModel utilisateur;

  const AuthResponse({required this.token, required this.utilisateur});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token:        json['token'] as String,
      utilisateur:  UserModel.fromJson(
          json['utilisateur'] as Map<String, dynamic>),
    );
  }
}