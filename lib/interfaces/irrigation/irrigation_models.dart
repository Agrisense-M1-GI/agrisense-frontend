import 'package:flutter/material.dart';
import '../../app_colors.dart';

// ─── Modèle session d'irrigation ──────────────────────────────────────────────
class IrrigationSession {
  final String id;
  final String zone;
  final String capteurId;
  final String date;
  final String heure;
  final int quantiteLitres;
  final int dureeMins;
  final String mode; // 'manuel' | 'auto'
  final String statut; // 'succes' | 'echec' | 'en_cours'
  final String? note;

  const IrrigationSession({
    required this.id,
    required this.zone,
    required this.capteurId,
    required this.date,
    required this.heure,
    required this.quantiteLitres,
    required this.dureeMins,
    required this.mode,
    required this.statut,
    this.note,
  });
}

// ─── Modèle zone ──────────────────────────────────────────────────────────────
class ZoneIrrigation {
  final String nom;
  final double humidite;
  final double surface;
  final String statut; // 'ok' | 'alerte' | 'irrigation'
  final String capteurId;
  final int seuilMin;

  const ZoneIrrigation({
    required this.nom,
    required this.humidite,
    required this.surface,
    required this.statut,
    required this.capteurId,
    required this.seuilMin,
  });
}

// ─── Données mock ──────────────────────────────────────────────────────────────
final List<ZoneIrrigation> zonesIrrigation = [
  const ZoneIrrigation(nom: 'Zone A', humidite: 74, surface: 0.8, statut: 'ok',         capteurId: 'C1', seuilMin: 60),
  const ZoneIrrigation(nom: 'Zone B', humidite: 48, surface: 1.1, statut: 'alerte',     capteurId: 'C3', seuilMin: 60),
  const ZoneIrrigation(nom: 'Zone C', humidite: 81, surface: 1.2, statut: 'ok',         capteurId: 'C5', seuilMin: 60),
  const ZoneIrrigation(nom: 'Zone D', humidite: 65, surface: 0.9, statut: 'ok',         capteurId: 'C7', seuilMin: 60),
];

final List<IrrigationSession> sessionsHistorique = [
  const IrrigationSession(id:'IRR001', zone:'Zone A', capteurId:'C1', date:"Aujourd'hui", heure:'06h30', quantiteLitres:45, dureeMins:18, mode:'manuel',  statut:'succes'),
  const IrrigationSession(id:'IRR002', zone:'Zone B', capteurId:'C3', date:"Aujourd'hui", heure:'04h00', quantiteLitres:60, dureeMins:24, mode:'auto',    statut:'succes', note:'Déclenchement auto seuil 48%'),
  const IrrigationSession(id:'IRR003', zone:'Zone A', capteurId:'C1', date:'Hier',        heure:'07h15', quantiteLitres:50, dureeMins:20, mode:'auto',    statut:'succes'),
  const IrrigationSession(id:'IRR004', zone:'Zone C', capteurId:'C5', date:'Hier',        heure:'14h00', quantiteLitres:0,  dureeMins:0,  mode:'auto',    statut:'echec',  note:'Capteur C5 injoignable'),
  const IrrigationSession(id:'IRR005', zone:'Zone B', capteurId:'C3', date:'Lundi',       heure:'08h00', quantiteLitres:55, dureeMins:22, mode:'manuel',  statut:'succes'),
  const IrrigationSession(id:'IRR006', zone:'Zone D', capteurId:'C7', date:'Lundi',       heure:'06h45', quantiteLitres:40, dureeMins:16, mode:'auto',    statut:'succes'),
  const IrrigationSession(id:'IRR007', zone:'Zone A', capteurId:'C1', date:'Dimanche',    heure:'07h00', quantiteLitres:50, dureeMins:20, mode:'auto',    statut:'succes'),
  const IrrigationSession(id:'IRR008', zone:'Zone B', capteurId:'C3', date:'Samedi',      heure:'06h30', quantiteLitres:65, dureeMins:26, mode:'manuel',  statut:'succes'),
];

// ─── Données historique humidité (points par jour) ────────────────────────────
final Map<String, List<double>> humiditeParZone = {
  'Zone A': [68, 72, 70, 74, 71, 73, 74],
  'Zone B': [62, 58, 54, 50, 48, 46, 48],
  'Zone C': [78, 80, 82, 79, 81, 83, 81],
  'Zone D': [70, 68, 66, 64, 65, 63, 65],
};

// ─── Helpers statut ────────────────────────────────────────────────────────────
Color sessionStatutColor(String s) {
  switch (s) {
    case 'succes':    return AppColors.green600;
    case 'echec':     return AppColors.red600;
    case 'en_cours':  return AppColors.amber600;
    default:          return AppColors.textMuted;
  }
}

Color sessionStatutBg(String s) {
  switch (s) {
    case 'succes':    return AppColors.green100;
    case 'echec':     return AppColors.red100;
    case 'en_cours':  return AppColors.amber100;
    default:          return AppColors.gray50;
  }
}

String sessionStatutLabel(String s) {
  switch (s) {
    case 'succes':    return 'Succès';
    case 'echec':     return 'Échec';
    case 'en_cours':  return 'En cours';
    default:          return 'Inconnu';
  }
}

Color zoneStatutColor(String s) {
  switch (s) {
    case 'ok':         return AppColors.green600;
    case 'alerte':     return AppColors.red600;
    case 'irrigation': return AppColors.amber600;
    default:           return AppColors.textMuted;
  }
}

Color zoneStatutBg(String s) {
  switch (s) {
    case 'ok':         return AppColors.green100;
    case 'alerte':     return AppColors.red100;
    case 'irrigation': return AppColors.amber100;
    default:           return AppColors.gray50;
  }
}

String zoneStatutLabel(String s) {
  switch (s) {
    case 'ok':         return 'OK';
    case 'alerte':     return 'Alerte';
    case 'irrigation': return 'En cours';
    default:           return 'Inconnu';
  }
}

IconData zoneStatutIcon(String s) {
  switch (s) {
    case 'ok':         return Icons.check_circle_outline;
    case 'alerte':     return Icons.warning_amber_outlined;
    case 'irrigation': return Icons.water_drop_outlined;
    default:           return Icons.help_outline;
  }
}