import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  bool _autoMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Irrigation'),
            Text(
              'Contrôle & automatisation',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.red100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.red800, size: 17),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Métriques haut ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green100,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Humidité actuelle',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.green600,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '72%',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: AppColors.green800),
                        ),
                        Text(
                          'Seuil défini : 60%',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.green600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Dernière irrigation',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Il y a 3h',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text),
                        ),
                        Text(
                          'Zone A · 45L',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                        SizedBox(height: 6),
                        StatusPill(
                          label: 'Succès',
                          bg: AppColors.green100,
                          textColor: AppColors.green700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Mode automatique ──────────────────────────────────────────
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Mode automatique',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text),
                          ),
                          Text(
                            'Déclenche selon le seuil d\'humidité',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Switch(
                        value: _autoMode,
                        onChanged: (v) => setState(() => _autoMode = v),
                        activeThumbColor: AppColors.green600,
                      ),
                    ],
                  ),
                  const Divider(
                      height: 20, thickness: 0.5, color: Color(0xFFE8EDE4)),
                  Row(
                    children: const [
                      _StatChip(label: 'Quantité', value: '50 L'),
                      SizedBox(width: 8),
                      _StatChip(label: 'Durée', value: '20 min'),
                      SizedBox(width: 8),
                      _StatChip(label: 'Zone', value: 'Toutes'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Boutons action ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.water_drop, size: 16),
                label: const Text('Lancer l\'irrigation manuellement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.show_chart, size: 16),
                label: const Text('Voir l\'historique d\'humidité'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green700,
                  side: const BorderSide(
                      color: AppColors.green600, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Zones surveillées ─────────────────────────────────────────
            const SectionLabel('Zones surveillées'),
            AppCard(
              child: Column(
                children: const [
                  ZoneRow(
                    label: 'Zone A',
                    sub: 'Humidité 74% · 0.8 ha',
                    status: 'OK',
                    statusBg: AppColors.green100,
                    statusText: AppColors.green700,
                    iconBg: AppColors.green100,
                    iconColor: AppColors.green700,
                    icon: Icons.check_circle_outline,
                  ),
                  ZoneRow(
                    label: 'Zone B',
                    sub: 'Humidité 48% · critique !',
                    status: 'Alerte',
                    statusBg: AppColors.red100,
                    statusText: AppColors.red800,
                    iconBg: AppColors.red100,
                    iconColor: AppColors.red800,
                    icon: Icons.warning_amber_outlined,
                  ),
                  ZoneRow(
                    label: 'Zone C',
                    sub: 'Humidité 81% · 1.2 ha',
                    status: 'OK',
                    statusBg: AppColors.green100,
                    statusText: AppColors.green700,
                    iconBg: AppColors.green100,
                    iconColor: AppColors.green700,
                    icon: Icons.check_circle_outline,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget chip statistique ──────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}