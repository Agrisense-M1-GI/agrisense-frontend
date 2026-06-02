/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/seuil.dart';
import '../../services/seuil_service.dart';
import '../../services/capteur_service.dart';
import '../../models/irrigation.dart';
import 'lancer_irrigation_page.dart';
import 'historique_humidite_page.dart';
import 'historique_irrigation_page.dart';
import '../tableau_de_bord/notifications_page.dart';
import 'programmation_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IrrigationScreen
//
// Données temps réel (si backend disponible) :
//   GET /api/seuils    → seuil humidité critique + mode auto
//   GET /api/capteurs  → humidité et statut de chaque zone
//
// Données statiques (toujours) :
//   sessionsHistorique, zonesIrrigation (structure)
//   humidite par zone si capteurs indisponibles
// ─────────────────────────────────────────────────────────────────────────────

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  bool _autoMode       = irrigationAutoStatique;
  double _seuilCritique = seuilHumiditeStatique;
  List<ZoneIrrigation> _zones = List.from(zonesIrrigationStatiques);

  bool _isLoading      = true;
  bool _depuisBackend  = false; // true = données API, false = statiques

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Chargement API ────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final seuilService   = context.read<SeuilService>();
      final capteurService = context.read<CapteurService>();

      // Les deux en parallèle
      final results = await Future.wait([
        seuilService.getSeuil(),
        capteurService.getCapteurs(),
      ]);

      final seuil   = results[0] as SeuilModel?;
      final capteurs = results[1] as List;

      // ── Seuil ──
      final double seuilVal    = seuil?.seuilCritique ?? seuilHumiditeStatique;
      final bool   autoVal     = seuil?.irrigationAuto ?? irrigationAutoStatique;

      // ── Zones : on enrichit les statiques avec l'humidité des capteurs ──
      // L'API capteur n'a pas de champ humidite → on garde les valeurs statiques
      // mais on recalcule le statut alerte avec le seuil réel du backend
      final zonesAvecSeuil = zonesIrrigationStatiques
          .map((z) => z.withSeuil(seuilVal.toInt()))
          .toList();

      // Mise à jour de la variable globale (utilisée par LancerIrrigationScreen)
      zonesIrrigation = zonesAvecSeuil;

      setState(() {
        _seuilCritique = seuilVal;
        _autoMode      = autoVal;
        _zones         = zonesAvecSeuil;
        _depuisBackend = seuil != null;
        _isLoading     = false;
      });
    } catch (_) {
      // Backend inaccessible → données 100% statiques
      setState(() {
        _seuilCritique = seuilHumiditeStatique;
        _autoMode      = irrigationAutoStatique;
        _zones         = List.from(zonesIrrigationStatiques);
        _depuisBackend = false;
        _isLoading     = false;
      });
    }
  }

  // ── Toggle mode auto avec sync backend ───────────────────────────────────
  Future<void> _toggleAutoMode(bool val) async {
    setState(() => _autoMode = val);

    if (_depuisBackend) {
      try {
        final seuilService = context.read<SeuilService>();
        await seuilService.saveSeuil(
          valeurMin:      _seuilCritique,
          valeurMax:      _seuilCritique + 30,
          irrigationAuto: val,
        );
      } catch (_) {
        // Si ça échoue, on remet l'ancienne valeur
        setState(() => _autoMode = !val);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de sauvegarder le mode auto')),
          );
        }
      }
    }
  }

  // ── Humidité moyenne des zones ────────────────────────────────────────────
  double get _humiditemoyenne =>
      _zones.isEmpty ? 0 : _zones.map((z) => z.humidite).reduce((a, b) => a + b) / _zones.length;

  @override
  Widget build(BuildContext context) {
    final alertes = _zones.where((z) => z.statut == 'alerte').length;

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
          // ── Indicateur source données ──
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Tooltip(
                message: _depuisBackend ? 'Seuil en ligne' : 'Données locales (démo)',
                child: Icon(
                  _depuisBackend ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: _depuisBackend ? AppColors.green600 : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          // ── Bouton rafraîchir ──
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh, color: AppColors.green700, size: 17),
            ),
          ),
          // ── Badge alertes ──
          if (alertes > 0)
            Stack(children: [
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                icon: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.red800, size: 17),
                ),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppColors.red600, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$alertes',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          // ── Bouton programmation ──
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProgrammationScreen())),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.schedule, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Métriques haut ───────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Humidité moyenne',
                              style: TextStyle(fontSize: 10, color: AppColors.green600, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('${_humiditemoyenne.toInt()}%',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.green800)),
                          Text('Seuil défini : ${_seuilCritique.toInt()}%',
                              style: const TextStyle(fontSize: 10, color: AppColors.green600)),
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

                  // ── Mode automatique ─────────────────────────────────────
                  AppCard(
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Mode automatique',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                          Text(
                            _depuisBackend ? 'Synchronisé avec le serveur' : 'Déclenche selon le seuil d\'humidité',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ]),
                        Switch(
                          value: _autoMode,
                          onChanged: _toggleAutoMode,
                          activeColor: AppColors.green600,
                        ),
                      ]),
                      const Divider(height: 20, thickness: 0.5, color: Color(0xFFE8EDE4)),
                      Row(children: [
                        _StatChip(label: 'Quantité', value: '50 L'),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Durée', value: '20 min'),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Seuil min', value: '${_seuilCritique.toInt()}%'),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // ── Boutons principaux ───────────────────────────────────
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

                  // ── Zones surveillées ────────────────────────────────────
                  const SectionLabel('Zones surveillées'),
                  AppCard(
                    child: Column(
                      children: _zones.asMap().entries.map((entry) {
                        final i = entry.key;
                        final z = entry.value;
                        return _ZoneIrrigRow(
                          zone: z,
                          isLast: i == _zones.length - 1,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => LancerIrrigationScreen(zonePreselect: z.nom))),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Mini graphe humidité ─────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoriqueHumiditeScreen())),
                    child: AppCard(
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Humidité — 7 jours',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                          Text('Voir détails',
                              style: const TextStyle(fontSize: 11, color: AppColors.green700)),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: CustomPaint(
                            painter: _MiniHumiditeChart(seuilCritique: _seuilCritique),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj']
                              .map((d) => Text(d, style: TextStyle(
                                  fontSize: 9,
                                  color: d == 'Auj' ? AppColors.green700 : AppColors.textMuted,
                                  fontWeight: d == 'Auj' ? FontWeight.w500 : FontWeight.normal)))
                              .toList(),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Sessions récentes (toujours statiques) ───────────────
                  /*Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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

                  const SizedBox(height: 8),*/
                ], 
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ZoneIrrigRow
// ─────────────────────────────────────────────────────────────────────────────
class _ZoneIrrigRow extends StatelessWidget {
  final ZoneIrrigation zone;
  final bool isLast;
  final VoidCallback onTap;
  const _ZoneIrrigRow({required this.zone, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = zoneStatutColor(zone.statut);
    final bg    = zoneStatutBg(zone.statut);
    final label = zoneStatutLabel(zone.statut);
    final icon  = zoneStatutIcon(zone.statut);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
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

// ─────────────────────────────────────────────────────────────────────────────
// _SessionMiniTile
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// _MiniHumiditeChart — reçoit maintenant le seuil dynamique
// ─────────────────────────────────────────────────────────────────────────────
class _MiniHumiditeChart extends CustomPainter {
  final double seuilCritique;
  const _MiniHumiditeChart({required this.seuilCritique});

  @override
  void paint(Canvas canvas, Size size) {
    // Grille
    final grid = Paint()..color = const Color(0xFFE8EDE4)..strokeWidth = 0.5;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, y * size.height), Offset(size.width, y * size.height), grid);
    }
    // Ligne seuil dynamique
    final seuilPaint = Paint()
      ..color = AppColors.red600.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final seuilY = (1 - seuilCritique / 100) * size.height;
    _dashLine(canvas, Offset(0, seuilY), Offset(size.width, seuilY), seuilPaint);

    // Courbes zones (données statiques)
    _drawCurve(canvas, size, [68,72,70,74,71,73,74].map((v) => v/100.0).toList(), AppColors.green600);
    _drawCurve(canvas, size, [62,58,54,50,48,46,48].map((v) => v/100.0).toList(), AppColors.red600);
  }

  void _drawCurve(Canvas canvas, Size size, List<double> pts, Color color) {
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
  bool shouldRepaint(_MiniHumiditeChart old) => old.seuilCritique != seuilCritique;
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatChip
// ─────────────────────────────────────────────────────────────────────────────
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
}*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/seuil.dart';
import '../../models/capteur.dart';
import '../../services/seuil_service.dart';
import '../../services/capteur_service.dart';
import '../tableau_de_bord/notifications_page.dart';
import 'historique_humidite_page.dart';
import 'historique_irrigation_page.dart';
import 'programmation_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IrrigationScreen
// ─────────────────────────────────────────────────────────────────────────────
class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  SeuilModel?          _seuil;
  List<CapteurModel>   _capteurs     = [];
  bool                 _isLoading    = true;
  bool                 _depuisBackend = false;

  // Seuil température critique (local, pas encore en backend)
  double _tempCritique = 35.0;

  // Valeurs seuil éditables
  double _seuilMin = 30.0;
  double _seuilMax = 70.0;
  bool   _irrigationAuto = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Chargement ────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final seuilService   = context.read<SeuilService>();
      final capteurService = context.read<CapteurService>();

      final results = await Future.wait([
        seuilService.getSeuil(),
        capteurService.getCapteurs(),
      ]);

      final seuil   = results[0] as SeuilModel?;
      final capteurs = results[1] as List<CapteurModel>;

      setState(() {
        _seuil    = seuil;
        _capteurs = capteurs;
        if (seuil != null) {
          _seuilMin      = seuil.valeurMin;
          _seuilMax      = seuil.valeurMax;
          _irrigationAuto = seuil.irrigationAuto;
        }
        _depuisBackend = true;
        _isLoading     = false;
      });
    } catch (_) {
      setState(() {
        _depuisBackend = false;
        _isLoading     = false;
      });
    }
  }

  // ── Humidité moyenne des capteurs ─────────────────────────────────────────
  double get _humiditemoy {
    if (_capteurs.isEmpty) return 0;
    // Les capteurs n'ont pas de champ humidité dans le modèle actuel
    // On affiche le nombre actifs / total comme indicateur
    return 0;
  }

  int get _capteursActifs => _capteurs.where((c) => c.etat == 'actif').length;
  int get _capteursAlerte => _capteurs.where((c) => (c.batterie ?? 100) <= 20).length;

  // ── Sauvegarder seuil ─────────────────────────────────────────────────────
  Future<void> _saveSeuil() async {
    if (_seuilMin >= _seuilMax) {
      _showError('Le seuil minimum doit être inférieur au maximum.');
      return;
    }
    try {
      final seuilService = context.read<SeuilService>();
      await seuilService.saveSeuil(
        valeurMin:      _seuilMin,
        valeurMax:      _seuilMax,
        irrigationAuto: _irrigationAuto,
      );
      if (!mounted) return;
      _showSuccess('Seuils sauvegardés avec succès !');
      _loadData();
    } catch (e) {
      _showError('Erreur : $e');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: AppColors.green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ));
  }

  // ── Lancer irrigation ─────────────────────────────────────────────────────
  Future<void> _lancerIrrigation(CapteurModel? capteur) async {
    final tous = capteur == null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tous ? 'Irriguer tous les capteurs' : 'Irriguer ${capteur!.nom}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: Text(
          tous
              ? 'Lancer l\'irrigation sur tous les ${_capteurs.length} capteurs actifs ?'
              : 'Lancer l\'irrigation sur le capteur "${capteur!.nom}" ?',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Simulation du lancement (à brancher sur votre backend quand disponible)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _showSuccess(tous
        ? 'Irrigation lancée sur tous les capteurs !'
        : 'Irrigation lancée sur ${capteur!.nom} !');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Irrigation'),
            Text('Contrôle & seuils',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend ? 'Données en ligne' : 'Données locales',
                child: Icon(
                  _depuisBackend ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: _depuisBackend ? AppColors.green600 : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100, borderRadius: BorderRadius.circular(9)),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh, color: AppColors.green700, size: 17),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProgrammationScreen())),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.schedule, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.green600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Résumé capteurs ──────────────────────────────────
                    _buildResumeCapteurs(),
                    const SizedBox(height: 16),

                    // ── Seuils d'humidité ────────────────────────────────
                    _buildSeuilHumidite(),
                    const SizedBox(height: 16),

                    // ── Température critique ─────────────────────────────
                    _buildTempCritique(),
                    const SizedBox(height: 16),

                    // ── Irrigation manuelle ──────────────────────────────
                    _buildIrrigationManuelle(),
                    const SizedBox(height: 16),

                    // ── Historique ───────────────────────────────────────
                    _buildHistorique(),
                    const SizedBox(height: 16),

                    // ── Irrigation auto (perspectives) ───────────────────
                    _buildAutoSection(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Résumé capteurs ────────────────────────────────────────────────────────
  Widget _buildResumeCapteurs() {
    return Row(children: [
      Expanded(child: _StatCard(
        icon: Icons.sensors,
        iconBg: AppColors.green100,
        iconColor: AppColors.green700,
        value: '$_capteursActifs/${_capteurs.length}',
        label: 'Capteurs actifs',
        badge: _capteursActifs == _capteurs.length ? 'OK' : 'Attention',
        badgeBg: _capteursActifs == _capteurs.length ? AppColors.green100 : AppColors.amber100,
        badgeText: _capteursActifs == _capteurs.length ? AppColors.green700 : AppColors.amber800,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        icon: Icons.battery_alert_outlined,
        iconBg: _capteursAlerte > 0 ? AppColors.red100 : AppColors.green100,
        iconColor: _capteursAlerte > 0 ? AppColors.red800 : AppColors.green700,
        value: '$_capteursAlerte',
        label: 'Batterie faible',
        badge: _capteursAlerte > 0 ? 'Alerte' : 'OK',
        badgeBg: _capteursAlerte > 0 ? AppColors.red100 : AppColors.green100,
        badgeText: _capteursAlerte > 0 ? AppColors.red800 : AppColors.green700,
      )),
    ]);
  }

  // ── Seuils humidité ────────────────────────────────────────────────────────
  Widget _buildSeuilHumidite() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Seuils d\'humidité',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
            child: const Text('Configurable',
                style: TextStyle(fontSize: 10, color: AppColors.green700, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Définissez les seuils min/max d\'humidité de votre champ.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 16),

        // Seuil min
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Seuil minimum',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.red100, borderRadius: BorderRadius.circular(20)),
            child: Text('${_seuilMin.round()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                    color: AppColors.red800)),
          ),
        ]),
        SliderTheme(
          data: _sliderTheme(context, AppColors.red600),
          child: Slider(
            value: _seuilMin,
            min: 10, max: 60, divisions: 50,
            onChanged: (v) => setState(() => _seuilMin = v > _seuilMax - 5 ? _seuilMax - 5 : v),
          ),
        ),

        // Seuil max
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Seuil maximum',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
            child: Text('${_seuilMax.round()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                    color: AppColors.green700)),
          ),
        ]),
        SliderTheme(
          data: _sliderTheme(context, AppColors.green600),
          child: Slider(
            value: _seuilMax,
            min: 40, max: 95, divisions: 55,
            onChanged: (v) => setState(() => _seuilMax = v < _seuilMin + 5 ? _seuilMin + 5 : v),
          ),
        ),

        const SizedBox(height: 8),

        // Info visuelle
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _InfoPill(label: 'Min', value: '${_seuilMin.round()}%', color: AppColors.red600),
            const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
            _InfoPill(label: 'Optimal', value: 'Entre ${_seuilMin.round()}% et ${_seuilMax.round()}%',
                color: AppColors.green600),
            const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
            _InfoPill(label: 'Max', value: '${_seuilMax.round()}%', color: AppColors.amber800),
          ]),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveSeuil,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Sauvegarder les seuils'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Température critique ───────────────────────────────────────────────────
  Widget _buildTempCritique() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Température critique',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.amber100, borderRadius: BorderRadius.circular(20)),
            child: Text('${_tempCritique.round()}°C',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: AppColors.amber800)),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Vous serez alerté si la température dépasse ce seuil.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        SliderTheme(
          data: _sliderTheme(context, AppColors.amber600),
          child: Slider(
            value: _tempCritique,
            min: 25, max: 50, divisions: 25,
            onChanged: (v) => setState(() => _tempCritique = v),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('25°C', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          Text('50°C', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.amber100.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.notifications_outlined, color: AppColors.amber800, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Alerte si température ≥ ${_tempCritique.round()}°C',
              style: const TextStyle(fontSize: 11, color: AppColors.amber800),
            )),
          ]),
        ),
      ]),
    );
  }

  // ── Irrigation manuelle ────────────────────────────────────────────────────
  Widget _buildIrrigationManuelle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Irrigation manuelle'),

      // Bouton tous les capteurs
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _capteurs.isEmpty ? null : () => _lancerIrrigation(null),
          icon: const Icon(Icons.water_drop, size: 16),
          label: Text(_capteurs.isEmpty
              ? 'Aucun capteur disponible'
              : 'Irriguer tous les capteurs (${_capteurs.length})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green600,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.green200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      if (_capteurs.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Ou par capteur individuel :',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        ..._capteurs.map((c) => _CapteurIrrigCard(
          capteur: c,
          seuilMin: _seuilMin,
          onIrriguer: () => _lancerIrrigation(c),
        )),
      ],

      if (_capteurs.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amber100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.amber800, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Aucun capteur configuré. Ajoutez des capteurs depuis la page Carte.',
              style: TextStyle(fontSize: 11, color: AppColors.amber800),
            )),
          ]),
        ),
    ]);
  }

  // ── Historique ─────────────────────────────────────────────────────────────
  Widget _buildHistorique() {
    return AppCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Historique',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoriqueHumiditeScreen())),
              child: const Text('Humidité',
                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoriqueIrrigationScreen())),
              child: const Text('Irrigation',
                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 90,
          decoration: BoxDecoration(
              color: AppColors.green50, borderRadius: BorderRadius.circular(10)),
          child: CustomPaint(
            painter: _MiniChart(seuilMin: _seuilMin, seuilMax: _seuilMax),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj'].map((d) =>
              Text(d, style: TextStyle(fontSize: 9,
                  color: d == 'Auj' ? AppColors.green700 : AppColors.textMuted,
                  fontWeight: d == 'Auj' ? FontWeight.w500 : FontWeight.normal)))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _LegendDot(color: AppColors.green600, label: 'Humidité'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.red600, label: 'Seuil min'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.amber600, label: 'Seuil max'),
        ]),
      ]),
    );
  }

  // ── Irrigation auto (perspectives) ─────────────────────────────────────────
  Widget _buildAutoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: AppColors.green100, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.auto_mode, color: AppColors.green600, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Irrigation automatique',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
          Text('Fonctionnalité disponible prochainement.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.amber100, borderRadius: BorderRadius.circular(20)),
          child: const Text('Bientôt',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                  color: AppColors.amber800)),
        ),
      ]),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context, Color color) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        activeTrackColor: color,
        inactiveTrackColor: const Color(0xFFE8EDE4),
        thumbColor: color,
        overlayColor: color.withOpacity(0.15),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CapteurIrrigCard
// ─────────────────────────────────────────────────────────────────────────────
class _CapteurIrrigCard extends StatelessWidget {
  final CapteurModel capteur;
  final double seuilMin;
  final VoidCallback onIrriguer;

  const _CapteurIrrigCard({
    required this.capteur,
    required this.seuilMin,
    required this.onIrriguer,
  });

  @override
  Widget build(BuildContext context) {
    final isActif  = capteur.etat == 'actif';
    final batterie = capteur.batterie ?? 100;
    final batColor = batterie > 40 ? AppColors.green600
        : batterie > 20 ? AppColors.amber600
        : AppColors.red600;

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
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isActif ? AppColors.green100 : AppColors.gray50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.sensors,
              color: isActif ? AppColors.green600 : AppColors.textMuted, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(capteur.nom,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          Row(children: [
            Icon(Icons.battery_full, size: 12, color: batColor),
            const SizedBox(width: 3),
            Text('$batterie%',
                style: TextStyle(fontSize: 11, color: batColor)),
            const SizedBox(width: 8),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isActif ? AppColors.green600 : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(isActif ? 'Actif' : 'Inactif',
                style: TextStyle(fontSize: 11,
                    color: isActif ? AppColors.green700 : AppColors.textMuted)),
          ]),
        ])),
        ElevatedButton(
          onPressed: isActif ? onIrriguer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green600,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.green200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          child: const Text('Irriguer'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets atomiques
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String value, unit, label, badge;
  final Color badgeBg, badgeText;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    this.unit = '',
    required this.label,
    required this.badge,
    required this.badgeBg,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: badgeText)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.text)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
  ]);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniChart
// ─────────────────────────────────────────────────────────────────────────────
class _MiniChart extends CustomPainter {
  final double seuilMin, seuilMax;
  const _MiniChart({required this.seuilMin, required this.seuilMax});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 0.0;

    // Ligne seuil min (rouge pointillée)
    _dashLine(canvas, size, seuilMin / 100, AppColors.red600.withOpacity(0.5));
    // Ligne seuil max (ambre pointillée)
    _dashLine(canvas, size, seuilMax / 100, AppColors.amber600.withOpacity(0.5));

    // Courbe humidité (statique pour illustration)
    final pts = [0.65, 0.72, 0.68, 0.75, 0.70, 0.65, 0.72];
    _drawCurve(canvas, size, pts, AppColors.green600, leftPad);
  }

  void _dashLine(Canvas canvas, Size size, double frac, Color color) {
    final y = (1 - frac) * size.height;
    final paint = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    double x = 0; bool draw = true;
    while (x < size.width) {
      final nx = (x + (draw ? 6 : 4)).clamp(0.0, size.width);
      if (draw) canvas.drawLine(Offset(x, y), Offset(nx, y), paint);
      x = nx; draw = !draw;
    }
  }

  void _drawCurve(Canvas canvas, Size size, List<double> pts, Color color, double lp) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill  = Paint()
      ..shader = LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final offsets = pts.asMap().entries.map((e) =>
        Offset(lp + e.key * (size.width - lp) / (pts.length - 1),
               (1 - e.value) * size.height)).toList();

    final fp = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fp.lineTo(o.dx, o.dy);
    fp..lineTo(offsets.last.dx, size.height)..lineTo(offsets.first.dx, size.height)..close();
    canvas.drawPath(fp, fill);

    final lp2 = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) lp2.lineTo(o.dx, o.dy);
    canvas.drawPath(lp2, paint);

    canvas.drawCircle(offsets.last, 4, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MiniChart old) => old.seuilMin != seuilMin || old.seuilMax != seuilMax;
}