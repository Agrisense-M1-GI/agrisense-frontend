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
import '../irrigation/monitoring_page.dart';

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

  SeuilModel? _seuil;          // null = pas encore configuré côté backend
  double?     _humiditeAir;    // dernière valeur, premier capteur actif
  double?     _humiditeSol;    // null pour l'instant (backend ne distingue
                                // pas encore air/sol sur l'endpoint)
  double?     _temperature;    // dernière valeur, premier capteur actif
                                // (PAS de moyenne)
  int?        _batterieMin;    // batterie la plus basse, tous capteurs

  int    _capteursActifs     = 0;
  int    _capteursTotalCount = 0;
  int    _alertesActives     = 0;

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
      final mesureService  = context.read<MesureService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        seuilService.getSeuil(),
      ]);

      final capteurs = results[0] as List;
      final seuil    = results[1] as SeuilModel?;

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

      // ── Batterie la plus basse, tous capteurs confondus
      int? batterieMin;
      for (final c in capteurs) {
        final b = c.batterie as int?;
        if (b != null && (batterieMin == null || b < batterieMin)) {
          batterieMin = b;
        }
      }

      // ── Premier capteur actif → température + humidité air/sol
      double? temperature;
      double? humiditeAir;
      double? humiditeSol;
      final premierActif = capteurs.cast<dynamic>().firstWhere(
            (c) => c.etat == 'actif',
            orElse: () => null,
          );
      if (premierActif != null) {
        final id = premierActif.id as String;
        final mesures = await Future.wait([
          mesureService.getDerniereTemperature(id),
          mesureService.getDerniereHumiditeAir(id),
          mesureService.getDerniereHumiditeSol(id),
        ]);
        temperature = (mesures[0] as MesureModel?)?.valeur;
        humiditeAir = (mesures[1] as MesureModel?)?.valeur;
        humiditeSol = (mesures[2] as MesureModel?)?.valeur; // null pour l'instant
      }

      // ── Alertes dynamiques
      final List<Map<String, dynamic>> alertes = [];

      if (seuil == null) {
        alertes.add({
          'titre':   'Aucun seuil d\'humidité configuré',
          'temps':   'Action requise',
          'couleur': 'ambre',
        });
      }

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

      final alertesCount = alertesBatterie + inactifs + (seuil == null ? 1 : 0);

      setState(() {
        _seuil               = seuil;
        _humiditeAir         = humiditeAir;
        _humiditeSol         = humiditeSol;
        _temperature         = temperature;
        _batterieMin         = batterieMin;
        _capteursTotalCount  = total;
        _capteursActifs      = actifs;
        _alertesActives      = alertesCount;
        _alertesRecentes     = alertes.take(3).toList();
        _depuisBackend       = true;
        _isLoading           = false;
      });
    } catch (_) {
      setState(() {
        _prenomUtilisateur  = '';
        _champInfo          = '--';
        _initiales          = '?';
        _seuil              = null;
        _humiditeAir        = null;
        _humiditeSol        = null;
        _temperature        = null;
        _batterieMin        = null;
        _capteursActifs     = 0;
        _capteursTotalCount = 0;
        _alertesActives     = 0;
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

  Widget _buildBandeauSeuilManquant() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber600.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined,
            color: AppColors.amber800, size: 16),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Aucun seuil d\'humidité configuré. Les alertes sont désactivées.',
            style: TextStyle(fontSize: 11, color: AppColors.amber800),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MonitoringScreen())),
          child: const Text('Configurer →',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber800)),
        ),
      ]),
    );
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
              // Ajout d'un padding inférieur prenant en compte
              // la safe area et la barre de navigation inférieure.
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom + 56.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Vue d\'ensemble'),

                  if (_seuil == null) _buildBandeauSeuilManquant(),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    // Réduit l'aspect ratio pour augmenter la hauteur des cartes
                    // afin d'éviter le débordement vertical du contenu.
                    childAspectRatio: 1.00,
                    children: [
                      // CARTE 1 — Humidité air
                      MetricCard(
                        icon: Icons.water_drop_outlined,
                        iconBg: AppColors.blue100,
                        iconColor: AppColors.blue700,
                        value: _humiditeAir != null
                            ? _humiditeAir!.toStringAsFixed(1)
                            : '--',
                        unit: _humiditeAir != null ? '%' : '',
                        label: 'Humidité air',
                        badge: badgeHumidite(_humiditeAir, _seuil),
                        badgeBg: fondHumidite(_humiditeAir, _seuil),
                        badgeText: couleurHumidite(_humiditeAir, _seuil),
                      ),

                      // CARTE 2 — Humidité sol
                      // TODO: utiliser ?type=sol quand le backend l'exposera
                      MetricCard(
                        icon: Icons.grass,
                        iconBg: AppColors.amber100,
                        iconColor: AppColors.amber800,
                        value: _humiditeSol != null
                            ? _humiditeSol!.toStringAsFixed(1)
                            : '--',
                        unit: _humiditeSol != null ? '%' : '',
                        label: 'Humidité sol',
                        badge: _humiditeSol == null
                            ? 'Non disponible'
                            : badgeHumidite(_humiditeSol, _seuil),
                        badgeBg: fondHumidite(_humiditeSol, _seuil),
                        badgeText: couleurHumidite(_humiditeSol, _seuil),
                      ),

                      // CARTE 3 — Température (1er capteur actif, pas de moyenne)
                      MetricCard(
                        icon: Icons.wb_sunny_outlined,
                        iconBg: fondTemperature(_temperature),
                        iconColor: couleurTemperature(_temperature),
                        value: _temperature != null
                            ? _temperature!.toStringAsFixed(1)
                            : '--',
                        unit: _temperature != null ? '°C' : '',
                        label: 'Température',
                        badge: badgeTemperature(_temperature),
                        badgeBg: fondTemperature(_temperature),
                        badgeText: couleurTemperature(_temperature),
                      ),

                      // CARTE 4 — Capteurs actifs
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
                        subValue: _batterieMin != null
                            ? '🔋 $_batterieMin%'
                            : null,
                        badge: badgeCapteurs,
                        badgeBg: badgeCapteursBg,
                        badgeText: badgeCapteursText,
                      ),

                      // CARTE 5 — Alertes actives
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
                            painter: HumidityChartPainter(
                                seuil: _seuil?.valeurMin.toInt() ?? 60),
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