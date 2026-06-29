import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'models/seuil.dart';

// ─── Card générique ───────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

// ─── Badge / Pill de statut ───────────────────────────────────────────────────
class StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Label de section ─────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? margin;

  const SectionLabel(this.text, {super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Carte métrique ───────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final String badge;
  final Color badgeBg;
  final Color badgeText;
  final String? subValue;

  const MetricCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    required this.badge,
    required this.badgeBg,
    required this.badgeText,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 8),
          /*RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),*/
          Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      value,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    const SizedBox(width: 3),
    Text(
      unit,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    ),
  ],
),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(subValue!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 5),
          StatusPill(label: badge, bg: badgeBg, textColor: badgeText),
        ],
      ),
    );
  }
}

// ─── Ligne de zone (irrigation) ───────────────────────────────────────────────
class ZoneRow extends StatelessWidget {
  final String label, sub, status;
  final Color statusBg, statusText, iconBg, iconColor;
  final IconData icon;
  final bool isLast;

  const ZoneRow({
    super.key,
    required this.label,
    required this.sub,
    required this.status,
    required this.statusBg,
    required this.statusText,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          StatusPill(label: status, bg: statusBg, textColor: statusText),
        ],
      ),
    );
  }
}
// ─── Helpers badge humidité/température (utilisés dans Dashboard + Monitoring) ─

// '--' si seuil ou valeur manquants
String badgeHumidite(double? valeur, SeuilModel? seuil) {
  if (valeur == null || seuil == null) return '--';
  if (valeur < seuil.valeurMin) return 'Critique';
  if (valeur > seuil.valeurMax) return 'Excessive';
  return 'Normale';
}

Color couleurHumidite(double? valeur, SeuilModel? seuil) {
  if (valeur == null || seuil == null) return AppColors.textMuted;
  if (valeur < seuil.valeurMin) return AppColors.red600;
  if (valeur > seuil.valeurMax) return AppColors.amber600;
  return AppColors.green600;
}

Color fondHumidite(double? valeur, SeuilModel? seuil) {
  if (valeur == null || seuil == null) return AppColors.gray50;
  if (valeur < seuil.valeurMin) return AppColors.red100;
  if (valeur > seuil.valeurMax) return AppColors.amber100;
  return AppColors.green100;
}

// Fonctionne SANS SeuilModel (seuils fixes 15°C / 35°C)
String badgeTemperature(double? valeur) {
  if (valeur == null) return '--';
  if (valeur < 15) return 'Basse';
  if (valeur > 35) return 'Élevée';
  return 'Normale';
}

Color couleurTemperature(double? valeur) {
  if (valeur == null) return AppColors.textMuted;
  if (valeur < 15) return AppColors.blue700;
  if (valeur > 35) return AppColors.red600;
  return AppColors.amber800;
}

Color fondTemperature(double? valeur) {
  if (valeur == null) return AppColors.gray50;
  if (valeur < 15) return AppColors.blue100;
  if (valeur > 35) return AppColors.red100;
  return AppColors.amber100;
}