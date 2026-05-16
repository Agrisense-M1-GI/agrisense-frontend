import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'irrigation_models.dart';

class HistoriqueHumiditeScreen extends StatefulWidget {
  const HistoriqueHumiditeScreen({super.key});

  @override
  State<HistoriqueHumiditeScreen> createState() => _HistoriqueHumiditeScreenState();
}

class _HistoriqueHumiditeScreenState extends State<HistoriqueHumiditeScreen> {
  String _periode = '7 jours';
  String _zoneActive = 'Toutes';

  final List<String> _periodes = ['7 jours', '30 jours', '3 mois'];
  final List<String> _zones = ['Toutes', 'Zone A', 'Zone B', 'Zone C', 'Zone D'];

  final Map<String, Color> _zoneColors = {
    'Zone A': AppColors.green600,
    'Zone B': AppColors.red600,
    'Zone C': AppColors.amber600,
    'Zone D': const Color(0xFF4A90D9),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Historique humidité'),
            Text('Évolution par zone', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // Sélecteur période
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _periode,
                  isDense: true,
                  icon: const Icon(Icons.expand_more, color: AppColors.green700, size: 16),
                  style: const TextStyle(fontSize: 11, color: AppColors.green700,
                      fontWeight: FontWeight.w500),
                  onChanged: (v) => setState(() => _periode = v!),
                  items: _periodes.map((p) =>
                      DropdownMenuItem(value: p, child: Text(p))).toList(),
                ),
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

            // ── Statistiques résumées ─────────────────────────────────
            Row(children: [
              _MiniStat(valeur: '72%', label: 'Moyenne',   bg: AppColors.green100,  color: AppColors.green700),
              const SizedBox(width: 8),
              _MiniStat(valeur: '88%', label: 'Maximum',   bg: AppColors.green100,  color: AppColors.green700),
              const SizedBox(width: 8),
              _MiniStat(valeur: '46%', label: 'Minimum',   bg: AppColors.red100,    color: AppColors.red800),
              const SizedBox(width: 8),
              _MiniStat(valeur: '2',   label: 'Alertes',   bg: AppColors.amber100,  color: AppColors.amber800),
            ]),

            const SizedBox(height: 16),

            // ── Filtre zone ───────────────────────────────────────────
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _zones.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final z = _zones[i];
                  final sel = _zoneActive == z;
                  final color = z == 'Toutes' ? AppColors.green600 : _zoneColors[z]!;
                  return GestureDetector(
                    onTap: () => setState(() => _zoneActive = z),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.15) : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? color : AppColors.border,
                            width: sel ? 1.5 : 0.5),
                      ),
                      child: Text(z, style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                          color: sel ? color : AppColors.textMuted)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Graphique principal ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Taux d\'humidité — $_periode',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.text)),
                    // Légende compacte
                    Row(children: _zoneColors.entries
                        .where((e) => _zoneActive == 'Toutes' || e.key == _zoneActive)
                        .map((e) => Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(e.key.replaceAll('Zone ', ''),
                                style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          ]),
                        )).toList()),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _HumiditeChartPainter(
                          zoneActive: _zoneActive,
                          zoneColors: _zoneColors),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj']
                        .map((d) => Text(d, style: TextStyle(fontSize: 9,
                            color: d == 'Auj' ? AppColors.green700 : AppColors.textMuted,
                            fontWeight: d == 'Auj' ? FontWeight.w500 : FontWeight.normal)))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Détail par zone ───────────────────────────────────────
            _SectionH('DÉTAIL PAR ZONE'),
            const SizedBox(height: 10),

            ...zonesIrrigation.map((z) => _ZoneDetailCard(
                zone: z,
                color: _zoneColors[z.nom] ?? AppColors.green600,
                pts: humiditeParZone[z.nom]!)),

            const SizedBox(height: 14),

            // ── Ligne seuil info ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.red100.withOpacity(0.6),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.red600.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.red100, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.warning_amber_outlined,
                      color: AppColors.red600, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seuil critique : 60%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                            color: AppColors.red800)),
                    Text('Zone B est en dessous du seuil depuis 3 jours. Irrigation immédiate recommandée.',
                        style: TextStyle(fontSize: 11, color: AppColors.red800, height: 1.4)),
                  ],
                )),
              ]),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────
class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
          color: AppColors.textMuted, letterSpacing: 0.8));
}

class _MiniStat extends StatelessWidget {
  final String valeur, label;
  final Color bg, color;
  const _MiniStat({required this.valeur, required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(valeur, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  ));
}

class _ZoneDetailCard extends StatelessWidget {
  final ZoneIrrigation zone;
  final Color color;
  final List<double> pts;
  const _ZoneDetailCard({required this.zone, required this.color, required this.pts});

  @override
  Widget build(BuildContext context) {
    final moy  = (pts.reduce((a, b) => a + b) / pts.length).round();
    final min  = pts.reduce((a, b) => a < b ? a : b).round();
    final max  = pts.reduce((a, b) => a > b ? a : b).round();
    final isAlerte = zone.humidite < 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isAlerte ? AppColors.red600.withOpacity(0.3) : AppColors.border,
            width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(zone.nom,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAlerte ? AppColors.red100 : AppColors.green100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(isAlerte ? 'Alerte' : 'Normal',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: isAlerte ? AppColors.red800 : AppColors.green700)),
          ),
        ]),
        const SizedBox(height: 10),
        // Mini sparkline
        SizedBox(
          height: 40,
          child: CustomPaint(
            painter: _SparklinePainter(pts: pts.map((v) => v / 100.0).toList(), color: color),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _StatPill(label: 'Moy.', value: '$moy%', color: color),
          const SizedBox(width: 8),
          _StatPill(label: 'Min',  value: '$min%', color: isAlerte ? AppColors.red600 : color),
          const SizedBox(width: 8),
          _StatPill(label: 'Max',  value: '$max%', color: color),
          const Spacer(),
          Text('Capteur ${zone.capteurId}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text('$label $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
  );
}

// ── Peintre sparkline ─────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> pts;
  final Color color;
  const _SparklinePainter({required this.pts, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 1.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill  = Paint()..shader = LinearGradient(
        colors: [color.withOpacity(0.18), color.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))..style = PaintingStyle.fill;

    final offsets = pts.asMap().entries
        .map((e) => Offset(e.key * size.width / (pts.length - 1), (1 - e.value) * size.height))
        .toList();

    final fp = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fp.lineTo(o.dx, o.dy);
    fp..lineTo(offsets.last.dx, size.height)..lineTo(offsets.first.dx, size.height)..close();
    canvas.drawPath(fp, fill);

    final lp = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) lp.lineTo(o.dx, o.dy);
    canvas.drawPath(lp, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Peintre graphique principal ───────────────────────────────────────────────
class _HumiditeChartPainter extends CustomPainter {
  final String zoneActive;
  final Map<String, Color> zoneColors;

  const _HumiditeChartPainter({required this.zoneActive, required this.zoneColors});

  @override
  void paint(Canvas canvas, Size size) {
    // Grille
    final grid = Paint()..color = const Color(0xFFE8EDE4)..strokeWidth = 0.5;
    for (final frac in [0.2, 0.4, 0.6, 0.8]) {
      canvas.drawLine(Offset(0, frac * size.height), Offset(size.width, frac * size.height), grid);
    }
    // Axe Y labels
    for (final (frac, label) in [(0.0,'100%'),(0.25,'75%'),(0.5,'50%'),(0.75,'25%')]) {
      (TextPainter(
        text: TextSpan(text: label, style: const TextStyle(fontSize: 8, color: Color(0xFF9AAA9A))),
        textDirection: TextDirection.ltr,
      )..layout()).paint(canvas, Offset(2, frac * size.height + 2));
    }
    // Ligne seuil 60%
    final seuil = Paint()..color = AppColors.red600.withOpacity(0.5)..strokeWidth = 1;
    final seuilY = (1 - 0.6) * size.height;
    _dash(canvas, Offset(0, seuilY), Offset(size.width, seuilY), seuil);
    (TextPainter(
      text: const TextSpan(text: 'Seuil', style: TextStyle(fontSize: 8, color: AppColors.red600)),
      textDirection: TextDirection.ltr,
    )..layout()).paint(canvas, Offset(size.width - 28, seuilY - 12));

    // Courbes
    final toShow = zoneActive == 'Toutes'
        ? humiditeParZone.entries.toList()
        : humiditeParZone.entries.where((e) => e.key == zoneActive).toList();

    for (final entry in toShow) {
      final color = zoneColors[entry.key] ?? AppColors.green600;
      _drawCurve(canvas, size, entry.value.map((v) => v / 100.0).toList(), color,
          dashed: entry.key == 'Zone B');
    }
  }

  void _drawCurve(Canvas canvas, Size size, List<double> pts, Color color, {bool dashed = false}) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill  = Paint()..shader = LinearGradient(
        colors: [color.withOpacity(0.12), color.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))..style = PaintingStyle.fill;

    final offsets = pts.asMap().entries
        .map((e) => Offset(e.key * size.width / (pts.length - 1), (1 - e.value) * size.height))
        .toList();

    final fp = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fp.lineTo(o.dx, o.dy);
    fp..lineTo(offsets.last.dx, size.height)..lineTo(offsets.first.dx, size.height)..close();
    canvas.drawPath(fp, fill);

    final lp = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) lp.lineTo(o.dx, o.dy);
    canvas.drawPath(lp, paint);

    canvas.drawCircle(offsets.last, 4,
        Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(offsets.last, 4,
        Paint()..color = AppColors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _dash(Canvas canvas, Offset a, Offset b, Paint p) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = (dx * dx + dy * dy);
    double dist = 0; bool draw = true; var cur = a;
    while (dist < len) {
      const step = 6.0;
      final nxt = Offset(cur.dx + dx * step / len, cur.dy + dy * step / len);
      if (draw) canvas.drawLine(cur, nxt, p);
      cur = nxt; dist += step; draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_) => true;
}