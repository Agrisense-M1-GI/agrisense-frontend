import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import 'irrigation_models.dart';
import 'lancer_irrigation_page.dart';
import 'historique_humidite_page.dart';
import 'historique_irrigation_page.dart';
import 'programmation_page.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  bool _autoMode = true;

  @override
  Widget build(BuildContext context) {
    final alertes = zonesIrrigation.where((z) => z.statut == 'alerte').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Irrigation'),
            Text('Contrôle & automatisation',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // Badge alertes
          if (alertes > 0)
            Stack(children: [
              IconButton(
                onPressed: () {},
                icon: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: AppColors.red100,
                      borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.red800, size: 17),
                ),
              ),
              Positioned(top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.red600, shape: BoxShape.circle),
                  child: Center(child: Text('$alertes',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w700))),
                ),
              ),
            ]),
          // Bouton programmation
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProgrammationScreen())),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.schedule, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Métriques haut ─────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.green100,
                      borderRadius: BorderRadius.circular(13)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Humidité moyenne',
                        style: TextStyle(fontSize: 10, color: AppColors.green600, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('72%',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.green800)),
                    Text('Seuil défini : 60%',
                        style: TextStyle(fontSize: 10, color: AppColors.green600)),
                  ]),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoriqueIrrigationScreen())),
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Dernière irrigation',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('Il y a 3h',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                      Text('Zone A · 45L',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      SizedBox(height: 6),
                      StatusPill(label: 'Succès', bg: AppColors.green100, textColor: AppColors.green700),
                    ]),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Mode automatique ───────────────────────────────────────
            AppCard(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Mode automatique',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                    Text('Déclenche selon le seuil d\'humidité',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                  Switch(
                    value: _autoMode,
                    onChanged: (v) => setState(() => _autoMode = v),
                    activeColor: AppColors.green600,
                  ),
                ]),
                const Divider(height: 20, thickness: 0.5, color: Color(0xFFE8EDE4)),
                Row(children: const [
                  _StatChip(label: 'Quantité', value: '50 L'),
                  SizedBox(width: 8),
                  _StatChip(label: 'Durée', value: '20 min'),
                  SizedBox(width: 8),
                  _StatChip(label: 'Zone', value: 'Toutes'),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Boutons principaux ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LancerIrrigationScreen())),
                icon: const Icon(Icons.water_drop, size: 16),
                label: const Text('Lancer l\'irrigation manuellement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoriqueHumiditeScreen())),
                  icon: const Icon(Icons.show_chart, size: 15),
                  label: const Text('Humidité'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green700,
                    side: const BorderSide(color: AppColors.green600, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoriqueIrrigationScreen())),
                  icon: const Icon(Icons.history, size: 15),
                  label: const Text('Historique'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green700,
                    side: const BorderSide(color: AppColors.green600, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Zones surveillées ──────────────────────────────────────
            const SectionLabel('Zones surveillées'),
            AppCard(
              child: Column(
                children: zonesIrrigation.asMap().entries.map((entry) {
                  final i = entry.key;
                  final z = entry.value;
                  return _ZoneIrrigRow(
                    zone: z,
                    isLast: i == zonesIrrigation.length - 1,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LancerIrrigationScreen(zonePreselect: z.nom))),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Mini graphe humidité ───────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoriqueHumiditeScreen())),
              child: AppCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Humidité — 7 jours',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                    Text('Voir détails',
                        style: TextStyle(fontSize: 11, color: AppColors.green700)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: CustomPaint(
                      painter: _MiniHumiditeChart(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj']
                        .map((d) => Text(d, style: TextStyle(fontSize: 9,
                            color: d == 'Auj' ? AppColors.green700 : AppColors.textMuted,
                            fontWeight: d == 'Auj' ? FontWeight.w500 : FontWeight.normal)))
                        .toList(),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // ── Sessions récentes ──────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SectionLabel('Sessions récentes'),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoriqueIrrigationScreen())),
                child: const Text('Voir tout',
                    style: TextStyle(fontSize: 12, color: AppColors.green700)),
              ),
            ]),
            const SizedBox(height: 8),
            ...sessionsHistorique.take(3).map((s) => _SessionMiniTile(session: s)),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Zone irrigation row ────────────────────────────────────────────────────────
class _ZoneIrrigRow extends StatelessWidget {
  final ZoneIrrigation zone;
  final bool isLast;
  final VoidCallback onTap;

  const _ZoneIrrigRow({required this.zone, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color  = zoneStatutColor(zone.statut);
    final bg     = zoneStatutBg(zone.statut);
    final label  = zoneStatutLabel(zone.statut);
    final icon   = zoneStatutIcon(zone.statut);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(
              bottom: BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(zone.nom,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
            Text('Humidité ${zone.humidite.toInt()}% · ${zone.surface} ha · ${zone.capteurId}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          // Barre humidité
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusPill(label: label, bg: bg, textColor: color),
            const SizedBox(height: 5),
            SizedBox(
              width: 52, height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: zone.humidite / 100,
                  backgroundColor: const Color(0xFFE8EDE4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    zone.humidite < 50 ? AppColors.red600
                        : zone.humidite < 65 ? AppColors.amber600
                        : AppColors.green600,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
        ]),
      ),
    );
  }
}

// ── Session mini tile ─────────────────────────────────────────────────────────
class _SessionMiniTile extends StatelessWidget {
  final IrrigationSession session;
  const _SessionMiniTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = sessionStatutColor(session.statut);
    final bg    = sessionStatutBg(session.statut);
    final label = sessionStatutLabel(session.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(Icons.water_drop_outlined, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${session.zone} · ${session.quantiteLitres}L · ${session.dureeMins} min',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
          Text('${session.date} ${session.heure} · ${session.mode == "auto" ? "Auto" : "Manuel"}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        StatusPill(label: label, bg: bg, textColor: color),
      ]),
    );
  }
}

// ── Mini graphe humidité ──────────────────────────────────────────────────────
class _MiniHumiditeChart extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grille
    final grid = Paint()..color = const Color(0xFFE8EDE4)..strokeWidth = 0.5;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, y * size.height), Offset(size.width, y * size.height), grid);
    }
    // Ligne seuil 60%
    final seuil = Paint()..color = AppColors.red600.withOpacity(0.4)..strokeWidth = 1..style = PaintingStyle.stroke;
    final seuilY = (1 - 0.6) * size.height;
    _dashLine(canvas, Offset(0, seuilY), Offset(size.width, seuilY), seuil);

    // Zone A
    _drawCurve(canvas, size, [68,72,70,74,71,73,74].map((v) => v/100.0).toList(), AppColors.green600);
    // Zone B (alerte)
    _drawCurve(canvas, size, [62,58,54,50,48,46,48].map((v) => v/100.0).toList(), AppColors.red600, dashed: true);
  }

  void _drawCurve(Canvas canvas, Size size, List<double> pts, Color color, {bool dashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.14), color.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final offsets = pts.asMap().entries
        .map((e) => Offset(e.key * size.width / (pts.length - 1), (1 - e.value) * size.height))
        .toList();

    final fillPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fillPath.lineTo(o.dx, o.dy);
    fillPath..lineTo(offsets.last.dx, size.height)..lineTo(offsets.first.dx, size.height)..close();
    canvas.drawPath(fillPath, fill);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) linePath.lineTo(o.dx, o.dy);
    canvas.drawPath(linePath, paint);

    // Dernier point
    canvas.drawCircle(offsets.last, 3.5, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _dashLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = (dx * dx + dy * dy).abs();
    const dash = 6.0, gap = 4.0;
    double dist = 0;
    bool drawing = true;
    var cur = start;
    while (dist < len) {
      final step = drawing ? dash : gap;
      final next = Offset(cur.dx + dx * step / len, cur.dy + dy * step / len);
      if (drawing) canvas.drawLine(cur, next, paint);
      cur = next;
      dist += step;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(9)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
      ]),
    ),
  );
}