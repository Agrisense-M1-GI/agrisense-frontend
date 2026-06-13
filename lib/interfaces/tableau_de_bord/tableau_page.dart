import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../services/auth_service.dart';
import '../../services/capteur_service.dart';
import '../../services/seuil_service.dart';
import '../../models/seuil.dart';
import 'notifications_page.dart';
import '../../services/mesure_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── État — valeurs neutres par défaut (pas de statique)
  String _prenomUtilisateur = '';
  String _champInfo         = '--';
  String _initiales         = '?';
  double? _temperature;
  //int    _humidite           = 0;
  //int    _temperature        = 0;
  int    _capteursActifs     = 0;
  int    _capteursTotalCount = 0;
  int    _alertesActives     = 0;
  // Remplacez :
int _seuil = 0;

// Par :
double? _humidite;       // dernière valeur reçue
int    _seuilMin = 0;
int    _seuilMax = 0;

  List<Map<String, dynamic>> _alertesRecentes = [];

  bool _isLoading     = true;
  bool _depuisBackend = false;
  

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final auth           = context.read<AuthService>();
      final capteurService = context.read<CapteurService>();
      final seuilService   = context.read<SeuilService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        seuilService.getSeuil(),
      ]);

      final capteurs = results[0] as List;
      final seuil = results[1] as SeuilModel?;
  final seuilMin = seuil?.valeurMin.toInt() ?? 0;
  final seuilMax = seuil?.valeurMax.toInt() ?? 0;
  double? humMoy;
double? tempMoy;
if (capteurs.isNotEmpty) {
  final mesureService = context.read<MesureService>();
  final capteurIds = capteurs.map<String>((c) => c.id as String).toList();

  final humFutures  = capteurIds.map((id) => mesureService.getDerniereHumidite(id));
  final tempFutures = capteurIds.map((id) => mesureService.getDerniereTemperature(id));

  final humResults  = await Future.wait(humFutures);
  final tempResults = await Future.wait(tempFutures);

  final humsValides  = humResults.whereType<MesureModel>().map((m) => m.valeur).toList();
  final tempsValides = tempResults.whereType<MesureModel>().map((m) => m.valeur).toList();

  if (humsValides.isNotEmpty)  humMoy  = humsValides.reduce((a, b) => a + b)  / humsValides.length;
  if (tempsValides.isNotEmpty) tempMoy = tempsValides.reduce((a, b) => a + b) / tempsValides.length;
}

      // ── Utilisateur depuis AuthService directement
      final user = auth.user;
      if (user != null) {
        _prenomUtilisateur = user.prenom.isNotEmpty ? user.prenom : user.nom;
        _initiales         = user.initiales;
        _champInfo         = '--'; // pas encore dans le backend
      }

      // ── Capteurs
      final total              = capteurs.length;
      final actifs             = capteurs.where((c) => c.etat == 'actif').length;
      final alertesBatterie    = capteurs.where((c) =>
          c.etat != 'inactif' && (c.batterie as int? ?? 100) <= 20).length;
      final inactifs           = capteurs.where((c) => c.etat == 'inactif').length;
      final alertesCount       = alertesBatterie + inactifs;

      // ── Seuil
      final seuilVal = seuil != null
          ? seuil.valeurMin.toInt()
          : 0;

      // ── Alertes dynamiques
      final List<Map<String, dynamic>> alertes = [];

      for (final c in capteurs.where((c) =>
          c.etat != 'inactif' && (c.batterie as int? ?? 100) <= 20)) {
        alertes.add({
          'titre':   'Capteur ${c.nom} — batterie faible (${c.batterie}%)',
          'temps':   'Récent',
          'couleur': 'ambre',
        });
      }

      for (final c in capteurs.where((c) => c.etat == 'inactif')) {
        alertes.add({
          'titre':   'Capteur ${c.nom} — inactif',
          'temps':   'Récent',
          'couleur': 'rouge',
        });
      }

      if (alertes.isEmpty) {
        alertes.add({
          'titre':   'Aucune alerte active',
          'temps':   '',
          'couleur': 'vert',
        });
      }
// Alerte humidité hors seuil
if (humMoy != null && seuilMin > 0 && seuilMax > 0) {
  if (humMoy < seuilMin || humMoy > seuilMax) {
    alertesCount++;
    alertes.add({
      'titre':   'Humidité hors seuil — ${humMoy.toStringAsFixed(1)}% '
                 '(seuil : $seuilMin–$seuilMax%)',
      'temps':   'Maintenant',
      'couleur': 'rouge',
    });
  }
}

// Alerte température (basée sur valeurMax du seuil température si vous l'avez,
// sinon gardez le seuil hardcodé à 35°C ou passez-le depuis le backend)
if (tempMoy != null && tempMoy > 35) {
  alertesCount++;
  alertes.add({
    'titre':   'Température élevée — ${tempMoy.toStringAsFixed(1)}°C',
    'temps':   'Maintenant',
    'couleur': 'ambre',
  });
}
      // Température — dernière mesure de chaque capteur actif, en parallèle
//double? tempMoy;
if (capteurs.isNotEmpty) {
  final mesureService = context.read<MesureService>();
  final capteurIds    = capteurs.map<String>((c) => c.id as String).toList();

  final tempResults = await Future.wait(
    capteurIds.map((id) => mesureService.getDerniereTemperature(id)),
  );

  final tempsValides = tempResults
      .whereType<MesureModel>()
      .map((m) => m.valeur)
      .toList();

  if (tempsValides.isNotEmpty) {
    tempMoy = tempsValides.reduce((a, b) => a + b) / tempsValides.length;
  }
}

      setState(() {
        _capteursTotalCount = total;
        _capteursActifs     = actifs;
        _alertesActives     = alertesCount;
        _seuil              = seuilVal;
        _alertesRecentes    = alertes.take(3).toList();
        _depuisBackend      = true;
        _isLoading          = false;
        _temperature = tempMoy;
      });
    } catch (_) {
      setState(() {
        _prenomUtilisateur  = '';
        _champInfo          = '--';
        _initiales          = '?';
        _humidite           = 0;
        _temperature        = 0;
        _capteursActifs     = 0;
        _capteursTotalCount = 0;
        _alertesActives     = 0;
        _seuil              = 0;
        _alertesRecentes    = [];
        _depuisBackend      = false;
        _isLoading          = false;
      });
    }
  }

  Color _couleurAlerte(String c) {
    switch (c) {
      case 'rouge': return AppColors.red600;
      case 'ambre': return AppColors.amber600;
      default:      return AppColors.green600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeCapteurs = _capteursTotalCount == 0
        ? '--'
        : _capteursActifs < _capteursTotalCount ? 'Attention' : 'Opérationnel';
    final badgeCapteursBg = _capteursActifs < _capteursTotalCount
        ? AppColors.amber100 : AppColors.green100;
    final badgeCapteursText = _capteursActifs < _capteursTotalCount
        ? AppColors.amber800 : AppColors.green700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _prenomUtilisateur.isNotEmpty
                  ? 'Bonjour, $_prenomUtilisateur '
                  : 'Bonjour ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            Text(
              _champInfo,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend
                    ? 'Données en ligne'
                    : 'Données locales (démo)',
                child: Icon(
                  _depuisBackend
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: _depuisBackend
                      ? AppColors.green600
                      : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh,
                      color: AppColors.green700, size: 17),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.green200,
              child: Text(
                _initiales,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.green700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    children: [
                      // Humidité — pas encore dans le backend → '--'
                      MetricCard(
                        icon: Icons.water_drop_outlined,
                        iconBg: AppColors.green100,
                        iconColor: AppColors.green700,
                        value: _seuil > 0 ? '$_seuil' : '--',
                        unit: _seuil > 0 ? '%' : '',
                        label: 'Seuil humidité',
                        badge: _seuil > 0 ? '↑ Normal' : '--',
                        badgeBg: AppColors.green100,
                        badgeText: AppColors.green700,
                      ),
                      // Température — pas encore dans le backend → '--'
                      /*MetricCard(
                        icon: Icons.wb_sunny_outlined,
                        iconBg: AppColors.amber100,
                        iconColor: AppColors.amber800,
                        value: '--',
                        unit: '°C',
                        label: 'Température',
                        badge: '--',
                        badgeBg: AppColors.amber100,
                        badgeText: AppColors.amber800,
                      ),*/
                      MetricCard(
  icon: Icons.wb_sunny_outlined,
  iconBg:    (_temperature == null || _temperature! <= 35)
      ? AppColors.amber100 : AppColors.red100,
  iconColor: (_temperature == null || _temperature! <= 35)
      ? AppColors.amber800 : AppColors.red800,
  value: _temperature != null
      ? _temperature!.toStringAsFixed(1) : '--',
  unit:  _temperature != null ? '°C' : '',
  label: 'Température moy.',
  badge: _temperature == null ? '--'
      : _temperature! > 35 ? ' Élevée'
      : _temperature! < 15 ? ' Basse'
      : '✓ Normale',
  badgeBg:   (_temperature == null || _temperature! <= 35)
      ? AppColors.amber100 : AppColors.red100,
  badgeText: (_temperature == null || _temperature! <= 35)
      ? AppColors.amber800 : AppColors.red800,
),
                      MetricCard(
                        icon: Icons.sensors,
                        iconBg: _capteursActifs < _capteursTotalCount
                            ? AppColors.amber100 : AppColors.green100,
                        iconColor: _capteursActifs < _capteursTotalCount
                            ? AppColors.amber800 : AppColors.green700,
                        value: _capteursTotalCount > 0
                            ? '$_capteursActifs'
                            : '--',
                        unit: _capteursTotalCount > 0
                            ? '/$_capteursTotalCount'
                            : '',
                        label: 'Capteurs actifs',
                        badge: badgeCapteurs,
                        badgeBg: badgeCapteursBg,
                        badgeText: badgeCapteursText,
                      ),
                      MetricCard(
                        icon: Icons.warning_amber_outlined,
                        iconBg: _alertesActives > 0
                            ? AppColors.red100 : AppColors.green100,
                        iconColor: _alertesActives > 0
                            ? AppColors.red800 : AppColors.green700,
                        value: '$_alertesActives',
                        unit: '',
                        label: 'Alertes actives',
                        badge: _alertesActives > 0 ? 'Attention' : 'OK',
                        badgeBg: _alertesActives > 0
                            ? AppColors.red100 : AppColors.green100,
                        badgeText: _alertesActives > 0
                            ? AppColors.red800 : AppColors.green700,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Humidité sur 7 jours',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text)),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen())),
                              child: const Text('Voir tout',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.green700)),
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
                            painter: HumidityChartPainter(seuil: _seuil),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Auj']
                              .map((d) => Text(d,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: d == 'Auj'
                                          ? AppColors.green700
                                          : AppColors.textMuted)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Alertes récentes',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text)),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen())),
                              child: const Text('Tout voir',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.green700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_alertesRecentes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Aucune donnée disponible',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted)),
                          )
                        else
                          ..._alertesRecentes.asMap().entries.map((entry) {
                            final i = entry.key;
                            final a = entry.value;
                            return AlertRow(
                              dotColor:
                                  _couleurAlerte(a['couleur'] as String),
                              title: a['titre'] as String,
                              time:  a['temps'] as String,
                              isLast: i == _alertesRecentes.length - 1,
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

// ── AlertRow ──────────────────────────────────────────────────────────────────
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
                bottom:
                    BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── HumidityChartPainter ──────────────────────────────────────────────────────
class HumidityChartPainter extends CustomPainter {
  final int seuil;
  const HumidityChartPainter({this.seuil = 60});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 25.0;

    final tp = TextPainter(
        textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    for (int i = 0; i < 3; i++) {
      final pct = [75, 50, 25][i];
      final y   = (i + 1) * size.height / 4;
      tp.text = TextSpan(
        text: '$pct%',
        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    final seuilY = (1 - seuil / 100) * size.height;
    final seuilPaint = Paint()
      ..color = AppColors.red600.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double dist = leftPadding;
    bool draw = true;
    while (dist < size.width) {
      final next =
          (dist + (draw ? 6 : 4)).clamp(leftPadding, size.width);
      if (draw)
        canvas.drawLine(
            Offset(dist, seuilY), Offset(next, seuilY), seuilPaint);
      dist = next;
      draw = !draw;
    }

    final paint = Paint()
      ..color = AppColors.green600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.green600.withOpacity(0.15),
          AppColors.green600.withOpacity(0)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final pts = [0.55, 0.45, 0.35, 0.50, 0.30, 0.42, 0.35];
    final offsets = pts
        .asMap()
        .entries
        .map((e) => Offset(
            leftPadding +
                e.key *
                    (size.width - leftPadding) /
                    (pts.length - 1),
            e.value * size.height))
        .toList();

    final fillPath = Path()
      ..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fillPath.lineTo(o.dx, o.dy);
    fillPath
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fill);

    final linePath = Path()
      ..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) linePath.lineTo(o.dx, o.dy);
    canvas.drawPath(linePath, paint);

    canvas.drawCircle(
        offsets.last,
        4,
        Paint()
          ..color = AppColors.green600
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(HumidityChartPainter old) => old.seuil != seuil;
}