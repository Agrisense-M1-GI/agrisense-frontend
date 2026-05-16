import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'image_model.dart';
import 'details_image_page.dart';

class AnalyseIaScreen extends StatefulWidget {
  const AnalyseIaScreen({super.key});

  @override
  State<AnalyseIaScreen> createState() => _AnalyseIaScreenState();
}

class _AnalyseIaScreenState extends State<AnalyseIaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Analyse IA'),
            Text('Détections & recommandations',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.green700,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.green600,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Alertes'),
            Tab(text: 'Résumé'),
            Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AlertesTab(),
          _ResumeTab(),
          _ToutesTab(),
        ],
      ),
    );
  }
}

// ── Onglet Alertes ─────────────────────────────────────────────────────────────
class _AlertesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alertes = mockImages.where((i) => i.statut == 'alerte').toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [

        // Bandeau résumé alertes
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.red600.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: AppColors.red600.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.red600, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${alertes.length} alertes actives',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.red800)),
              const Text('Action recommandée dans les 24h',
                  style: TextStyle(fontSize: 11, color: AppColors.red800)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        const _SectionH('ANOMALIES DÉTECTÉES'),
        const SizedBox(height: 10),

        ...alertes.map((img) => GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DetailImageScreen(image: img))),
          child: _AlerteCard(image: img),
        )),

        const SizedBox(height: 16),
        const _SectionH('RECOMMANDATIONS PRIORITAIRES'),
        const SizedBox(height: 10),

        _PrioCard(
          numero: '1',
          numBg: AppColors.red600,
          titre: 'Apport en azote — Zone B',
          detail: 'Jaunissement confirmé par 2 captures successives. Apport foliaire recommandé sous 48h pour éviter une perte de rendement.',
          icone: Icons.eco_outlined,
          prioriteLabel: 'Urgent', prioriteBg: AppColors.red100, prioriteColor: AppColors.red800,
        ),
        const SizedBox(height: 8),
        _PrioCard(
          numero: '2',
          numBg: AppColors.amber600,
          titre: 'Irrigation ciblée — Zone B (C4)',
          detail: 'Sécheresse foliaire visible. Déclencher irrigation manuelle sur Zone B · C4 dans les 24h.',
          icone: Icons.water_drop_outlined,
          prioriteLabel: 'Moyen', prioriteBg: AppColors.amber100, prioriteColor: AppColors.amber800,
        ),
        const SizedBox(height: 8),
        _PrioCard(
          numero: '3',
          numBg: AppColors.green600,
          titre: 'Inspection terrain — Zone B',
          detail: 'Vérification manuelle des racines recommandée pour confirmer absence d\'atteinte fongique.',
          icone: Icons.search_outlined,
          prioriteLabel: 'Faible', prioriteBg: AppColors.green100, prioriteColor: AppColors.green700,
        ),
      ],
    );
  }
}

// ── Onglet Résumé ──────────────────────────────────────────────────────────────
class _ResumeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total    = mockImages.length;
    final alertes  = mockImages.where((i) => i.statut == 'alerte').length;
    final analysees = mockImages.where((i) => i.statut == 'analysee').length;
    final normales = mockImages.where((i) => i.statut == 'normale').length;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [

        // Statistiques globales
        const _SectionH('STATISTIQUES — 7 DERNIERS JOURS'),
        const SizedBox(height: 10),
        Row(children: [
          _StatBox(valeur: '$total',    label: 'Captures',  bg: AppColors.green100, color: AppColors.green700),
          const SizedBox(width: 9),
          _StatBox(valeur: '$alertes',  label: 'Alertes',   bg: AppColors.red100,   color: AppColors.red600),
          const SizedBox(width: 9),
          _StatBox(valeur: '$analysees',label: 'Analysées', bg: AppColors.green100, color: AppColors.green700),
          const SizedBox(width: 9),
          _StatBox(valeur: '$normales', label: 'Normales',  bg: AppColors.gray50,   color: AppColors.textMuted),
        ]),

        const SizedBox(height: 16),
        const _SectionH('SANTÉ PAR ZONE'),
        const SizedBox(height: 10),

        _ZoneSanteCard(zone: 'Zone A', score: 92, statut: 'Excellente', couleur: AppColors.green600,
            detail: 'Végétation dense et homogène. Aucune anomalie détectée.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone: 'Zone B', score: 38, statut: 'Critique', couleur: AppColors.red600,
            detail: 'Jaunissement + sécheresse foliaire détectés. Action requise.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone: 'Zone C', score: 85, statut: 'Bonne', couleur: AppColors.green600,
            detail: 'Quelques irrégularités mineures. Surveillance continue.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone: 'Zone D', score: 60, statut: 'Modérée', couleur: AppColors.amber600,
            detail: 'Capteur C7 en batterie faible. Données partielles.'),

        const SizedBox(height: 16),
        const _SectionH('MODÈLE IA — PERFORMANCE'),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: [
            _IaMetric(label: 'Précision détection anomalies', value: '87%', bar: 0.87, color: AppColors.green600),
            const SizedBox(height: 12),
            _IaMetric(label: 'Confiance moyenne des analyses', value: '84%', bar: 0.84, color: AppColors.green600),
            const SizedBox(height: 12),
            _IaMetric(label: 'Images analysées (7j)', value: '6/8', bar: 0.75, color: AppColors.amber600),
            const SizedBox(height: 12),
            _IaMetric(label: 'Taux de faux positifs', value: '< 5%', bar: 0.05, color: AppColors.green600, inverse: true),
          ]),
        ),

        const SizedBox(height: 16),
        const _SectionH('TENDANCE HUMIDITÉ — CHAMP NORD'),
        const SizedBox(height: 10),
        Container(
          height: 120,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: CustomPaint(
            painter: _TendancePainter(),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj']
              .map((d) => Text(d, style: TextStyle(fontSize: 9,
                  color: d == 'Auj' ? AppColors.green700 : AppColors.textMuted,
                  fontWeight: d == 'Auj' ? FontWeight.w500 : FontWeight.normal)))
              .toList()),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Onglet Toutes ──────────────────────────────────────────────────────────────
class _ToutesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _SectionH('TOUTES LES ANALYSES'),
        const SizedBox(height: 10),
        ...mockImages.where((i) => i.statut != 'normale').map((img) =>
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailImageScreen(image: img))),
            child: _AnalyseListTile(image: img),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionH('CAPTURES NORMALES'),
        const SizedBox(height: 10),
        ...mockImages.where((i) => i.statut == 'normale').map((img) =>
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailImageScreen(image: img))),
            child: _AnalyseListTile(image: img),
          ),
        ),
      ],
    );
  }
}

// ── Widgets composants ────────────────────────────────────────────────────────
class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
          color: AppColors.textMuted, letterSpacing: 0.8));
}

class _AlerteCard extends StatelessWidget {
  final CaptureImage image;
  const _AlerteCard({required this.image});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red600.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(13), bottomLeft: Radius.circular(13)),
          child: SizedBox(width: 80, height: 90,
            child: Image.network(image.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.red100,
                  child: const Center(child: Icon(Icons.grass, color: AppColors.red600, size: 28))),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${image.capteurId} — ${image.zone}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.red100, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Alerte', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.red800)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(image.anomalie ?? 'Anomalie détectée',
                  style: const TextStyle(fontSize: 11, color: AppColors.red600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('${image.date} · ${image.heure}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              if (image.confiance > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.psychology_outlined, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('Confiance ${image.confiance}%',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ]),
              ],
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
        ),
      ]),
    );
  }
}

class _PrioCard extends StatelessWidget {
  final String numero, titre, detail, prioriteLabel;
  final Color numBg, prioriteBg, prioriteColor;
  final IconData icone;
  const _PrioCard({
    required this.numero, required this.numBg,
    required this.titre, required this.detail,
    required this.icone, required this.prioriteLabel,
    required this.prioriteBg, required this.prioriteColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: numBg, shape: BoxShape.circle),
        child: Center(child: Text(numero,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(titre,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: prioriteBg, borderRadius: BorderRadius.circular(20)),
            child: Text(prioriteLabel,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: prioriteColor)),
          ),
        ]),
        const SizedBox(height: 5),
        Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
      ])),
    ]),
  );
}

class _StatBox extends StatelessWidget {
  final String valeur, label;
  final Color bg, color;
  const _StatBox({required this.valeur, required this.label, required this.bg, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(valeur, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color)),
      Text(label,  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ]),
  ));
}

class _ZoneSanteCard extends StatelessWidget {
  final String zone, statut, detail;
  final int score;
  final Color couleur;
  const _ZoneSanteCard({required this.zone, required this.score, required this.statut, required this.couleur, required this.detail});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(zone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
        Row(children: [
          Text('$score/100', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: couleur)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statut, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: couleur)),
          ),
        ]),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: score / 100,
          minHeight: 6,
          backgroundColor: const Color(0xFFE8EDE4),
          valueColor: AlwaysStoppedAnimation<Color>(couleur),
        ),
      ),
      const SizedBox(height: 7),
      Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
    ]),
  );
}

class _IaMetric extends StatelessWidget {
  final String label, value;
  final double bar;
  final Color color;
  final bool inverse;
  const _IaMetric({required this.label, required this.value, required this.bar, required this.color, this.inverse = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: bar,
          minHeight: 4,
          backgroundColor: const Color(0xFFE8EDE4),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ])),
  ]);
}

class _AnalyseListTile extends StatelessWidget {
  final CaptureImage image;
  const _AnalyseListTile({required this.image});
  @override
  Widget build(BuildContext context) {
    final isAlerte   = image.statut == 'alerte';
    final isAnalysee = image.statut == 'analysee';
    final badgeBg    = isAlerte ? AppColors.red100 : isAnalysee ? AppColors.green100 : AppColors.gray50;
    final badgeColor = isAlerte ? AppColors.red800 : isAnalysee ? AppColors.green700 : AppColors.textMuted;
    final badgeLabel = isAlerte ? 'Alerte' : isAnalysee ? 'Analysée' : 'Normale';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(width: 56, height: 56,
            child: Image.network(image.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.green100,
                  child: const Center(child: Icon(Icons.grass, color: AppColors.green600, size: 22)))),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${image.capteurId} — ${image.zone}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(badgeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: badgeColor)),
            ),
          ]),
          const SizedBox(height: 3),
          Text('${image.date} · ${image.heure}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          if (image.anomalie != null) ...[
            const SizedBox(height: 3),
            Text(image.anomalie!, style: const TextStyle(fontSize: 11, color: AppColors.red600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (image.confiance > 0) ...[
            const SizedBox(height: 3),
            Text('IA · ${image.confiance}% de confiance',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ])),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
      ]),
    );
  }
}

// ── Peintre tendance humidité ──────────────────────────────────────────────────
class _TendancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDE4)
      ..strokeWidth = 0.5;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, y * size.height), Offset(size.width, y * size.height), gridPaint);
    }

    final pts = [0.38, 0.32, 0.28, 0.42, 0.25, 0.30, 0.27];
    final ptsAlerte = [0.70, 0.72, 0.68, 0.65, 0.60, 0.55, 0.52];

    _drawLine(canvas, size, pts, AppColors.green600);
    _drawLine(canvas, size, ptsAlerte, AppColors.red600, dashed: true);

    // Légende
    _drawLegendDot(canvas, size, AppColors.green600, 'Zone A/C', 0);
    _drawLegendDot(canvas, size, AppColors.red600, 'Zone B', 70);
  }

  void _drawLine(Canvas canvas, Size size, List<double> pts, Color color, {bool dashed = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.12), color.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final points = pts.asMap().entries.map((e) =>
        Offset(e.key * size.width / (pts.length - 1), e.value * size.height)).toList();

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) fillPath.lineTo(points[i].dx, points[i].dy);
    fillPath..lineTo(points.last.dx, size.height)..lineTo(points.first.dx, size.height)..close();
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) linePath.lineTo(points[i].dx, points[i].dy);
    canvas.drawPath(linePath, paint);

    canvas.drawCircle(points.last, 3.5, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawLegendDot(Canvas canvas, Size size, Color color, String label, double xOffset) {
    canvas.drawCircle(Offset(xOffset + 6, 8), 4, Paint()..color = color..style = PaintingStyle.fill);
    (TextPainter(
      text: TextSpan(text: '  $label', style: TextStyle(color: color, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout()).paint(canvas, Offset(xOffset + 8, 2));
  }

  @override
  bool shouldRepaint(_) => false;
}