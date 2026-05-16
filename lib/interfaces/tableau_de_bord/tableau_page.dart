import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import 'notifications_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Bonjour, Kouam 👋',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text),
            ),
            Text(
              'Champ Nord · Dschang · 3 min',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.green200,
              child: const Text(
                'KN',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.green700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Vue d\'ensemble'),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.20,
              children: const [
                MetricCard(
                  icon: Icons.water_drop_outlined,
                  iconBg: AppColors.green100,
                  iconColor: AppColors.green700,
                  value: '72',
                  unit: '%',
                  label: 'Humidité moy.',
                  badge: '↑ Normal',
                  badgeBg: AppColors.green100,
                  badgeText: AppColors.green700,
                ),
                MetricCard(
                  icon: Icons.wb_sunny_outlined,
                  iconBg: AppColors.amber100,
                  iconColor: AppColors.amber800,
                  value: '28',
                  unit: '°C',
                  label: 'Température',
                  badge: 'Élevée',
                  badgeBg: AppColors.amber100,
                  badgeText: AppColors.amber800,
                ),
                MetricCard(
                  icon: Icons.sensors,
                  iconBg: AppColors.green100,
                  iconColor: AppColors.green700,
                  value: '6',
                  unit: '/8',
                  label: 'Capteurs actifs',
                  badge: 'Opérationnel',
                  badgeBg: AppColors.green100,
                  badgeText: AppColors.green700,
                ),
                MetricCard(
                  icon: Icons.warning_amber_outlined,
                  iconBg: AppColors.red100,
                  iconColor: AppColors.red800,
                  value: '2',
                  unit: '',
                  label: 'Alertes actives',
                  badge: 'Attention',
                  badgeBg: AppColors.red100,
                  badgeText: AppColors.red800,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Graphique ─────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Humidité sur 7 jours',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Voir tout',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.green700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomPaint(
                      painter: HumidityChartPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Auj']
                        .map((d) => Text(
                              d,
                              style: TextStyle(
                                fontSize: 10,
                                color: d == 'Auj'
                                    ? AppColors.green700
                                    : AppColors.textMuted,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Alertes ─────────────────────────────
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alertes récentes',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Tout voir',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.green700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AlertRow(
                    dotColor: AppColors.red600,
                    title: 'Humidité critique — Zone B (48%)',
                    time: 'Il y a 12 min',
                  ),
                  const AlertRow(
                    dotColor: AppColors.amber600,
                    title: 'Capteur C3 — batterie faible (18%)',
                    time: 'Il y a 1h',
                  ),
                  const AlertRow(
                    dotColor: AppColors.green600,
                    title: 'Irrigation Zone A terminée',
                    time: 'Il y a 3h',
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

class AlertRow extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String time;
  final bool isLast;

  const AlertRow({
    super.key,
    required this.dotColor,
    required this.title,
    required this.time,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFF0F5EB),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HumidityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 25.0;

    // 🔹 Labels (axe Y en %)
    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final labels = ['75%', '50%', '25%'];

    for (int i = 0; i < labels.length; i++) {
      final y = (i + 1) * size.height / (labels.length + 1);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textMuted,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // 🔹 Courbe
    final paint = Paint()
      ..color = AppColors.green600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [0.55, 0.45, 0.35, 0.50, 0.30, 0.42, 0.35];

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = leftPadding +
          i * (size.width - leftPadding) / (points.length - 1);
      final y = points[i] * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 🔹 point final
    final dotPaint = Paint()
      ..color = AppColors.green600
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width,
        points.last * size.height,
      ),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}