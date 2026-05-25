/*import 'package:flutter/material.dart';
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
              child:  const Text(
                'US',
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
}*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../services/capteur_service.dart';
import '../../services/seuil_service.dart';
import '../../services/utilisateur_service.dart';
import '../../models/user.dart';
import '../../models/seuil.dart';
import 'notifications_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Données statiques de fallback
// ─────────────────────────────────────────────────────────────────────────────
const _nomStatique        = 'Kouam';
const _champStatique      = 'Champ Nord · Dschang · 3 min';
const _humiditeStatique   = 72;
const _temperatStatique   = 28;
const _capteursTotal      = 8;
const _capteursActifsStatic = 6;
const _alertesStatique    = 2;
const _seuilStatique      = 60;

const _alertesStatiquesData = [
  {'titre': 'Humidité critique — Zone B (48%)', 'temps': 'Il y a 12 min', 'couleur': 'rouge'},
  {'titre': 'Capteur C3 — batterie faible (18%)', 'temps': 'Il y a 1h',   'couleur': 'ambre'},
  {'titre': 'Irrigation Zone A terminée',          'temps': 'Il y a 3h',   'couleur': 'vert'},
];

// ─────────────────────────────────────────────────────────────────────────────
// DashboardScreen
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  String _prenomUtilisateur  = _nomStatique;
  String _champInfo          = _champStatique;
  String _initiales          = 'US';

  int    _humidite           = _humiditeStatique;
  int    _temperature        = _temperatStatique;
  int    _capteursActifs     = _capteursActifsStatic;
  int    _capteursTotalCount = _capteursTotal;
  int    _alertesActives     = _alertesStatique;
  int    _seuil              = _seuilStatique;

  List<Map<String, dynamic>> _alertesRecentes = [];

  bool   _isLoading         = true;
  bool   _depuisBackend     = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Chargement ────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final capteurService = context.read<CapteurService>();
      final seuilService   = context.read<SeuilService>();
      final userService    = context.read<UtilisateurService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        seuilService.getSeuil(),
        userService.getMe(),
      ]);

      final capteurs = results[0] as List;
      final  seuil    = results[1] as SeuilModel?;   // SeuilModel? peut être null
      final UserModel? user     = results[2] as UserModel?;

      // ── Utilisateur ──
      // UserModel expose directement .prenom, .nom et .initiales
      if (user != null) {
        _prenomUtilisateur = user.prenom.isNotEmpty ? user.prenom : user.nom;
        _initiales         = user.initiales; // getter déjà défini dans UserModel
        _champInfo         = 'Champ Nord · Dschang · 3 min';
      }

      // ── Capteurs ──
      final total   = capteurs.length;
      final actifs  = capteurs.where((c) => c.etat == 'actif').length;
      final alertesBatterie = capteurs.where((c) =>
          c.etat != 'inactif' && (c.batterie as int? ?? 100) <= 20).length;
      final inactifs = capteurs.where((c) => c.etat == 'inactif').length;
      final alertesCount = alertesBatterie + inactifs;

      // ── Seuil ──
      final seuilVal = (seuil?.valeurMin ?? _seuilStatique.toDouble()).toInt();

      // ── Alertes récentes dynamiques ──
      final List<Map<String, dynamic>> alertes = [];

      // Zones en alerte humidité (statiques avec seuil réel)
      final zonesAlerte = [
        {'nom': 'Zone A', 'humidite': 74},
        {'nom': 'Zone B', 'humidite': 48},
        {'nom': 'Zone C', 'humidite': 81},
        {'nom': 'Zone D', 'humidite': 65},
      ].where((z) => (z['humidite'] as int) < seuilVal);

      for (final z in zonesAlerte) {
        alertes.add({
          'titre':   'Humidité critique — ${z['nom']} (${z['humidite']}%)',
          'temps':   'Récent',
          'couleur': 'rouge',
        });
      }

      // Capteurs batterie faible
      for (final c in capteurs.where((c) =>
          c.etat != 'inactif' && (c.batterie as int? ?? 100) <= 20)) {
        alertes.add({
          'titre':   'Capteur ${c.nom} — batterie faible (${c.batterie}%)',
          'temps':   'Récent',
          'couleur': 'ambre',
        });
      }

      // Notification succès irrigation (toujours statique)
      alertes.add({
        'titre':   'Irrigation Zone A terminée',
        'temps':   'Il y a 3h',
        'couleur': 'vert',
      });

      setState(() {
        _capteursTotalCount = total > 0 ? total : _capteursTotal;
        _capteursActifs     = actifs;
        _alertesActives     = alertesCount;
        _seuil              = seuilVal;
        _alertesRecentes    = alertes.isNotEmpty ? alertes.take(3).toList()
                                                 : _alertesStatiquesData.toList();
        _depuisBackend      = true;
        _isLoading          = false;
      });
    } catch (_) {
      // Fallback statique
      setState(() {
        _prenomUtilisateur  = _nomStatique;
        _champInfo          = _champStatique;
        _initiales          = 'US';
        _humidite           = _humiditeStatique;
        _temperature        = _temperatStatique;
        _capteursActifs     = _capteursActifsStatic;
        _capteursTotalCount = _capteursTotal;
        _alertesActives     = _alertesStatique;
        _seuil              = _seuilStatique;
        _alertesRecentes    = _alertesStatiquesData.toList();
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
    final badgeCapteurs = _capteursActifs < _capteursTotalCount
        ? 'Attention'
        : 'Opérationnel';
    final badgeCapteursBg = _capteursActifs < _capteursTotalCount
        ? AppColors.amber100
        : AppColors.green100;
    final badgeCapteursText = _capteursActifs < _capteursTotalCount
        ? AppColors.amber800
        : AppColors.green700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $_prenomUtilisateur 👋',
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
          // Indicateur source données
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend ? 'Données en ligne' : 'Données locales (démo)',
                child: Icon(
                  _depuisBackend ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: _depuisBackend ? AppColors.green600 : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          // Bouton rafraîchir
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
          // Avatar utilisateur
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

                  // ── Grille métriques ───────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.20,
                    children: [
                      MetricCard(
                        icon: Icons.water_drop_outlined,
                        iconBg: AppColors.green100,
                        iconColor: AppColors.green700,
                        value: '$_humidite',
                        unit: '%',
                        label: 'Humidité moy.',
                        badge: _humidite >= _seuil ? '↑ Normal' : '↓ Critique',
                        badgeBg: _humidite >= _seuil ? AppColors.green100 : AppColors.red100,
                        badgeText: _humidite >= _seuil ? AppColors.green700 : AppColors.red800,
                      ),
                      const MetricCard(
                        icon: Icons.wb_sunny_outlined,
                        iconBg: AppColors.amber100,
                        iconColor: AppColors.amber800,
                        value: '$_temperatStatique',
                        unit: '°C',
                        label: 'Température',
                        badge: 'Élevée',
                        badgeBg: AppColors.amber100,
                        badgeText: AppColors.amber800,
                      ),
                      MetricCard(
                        icon: Icons.sensors,
                        iconBg: _capteursActifs < _capteursTotalCount
                            ? AppColors.amber100 : AppColors.green100,
                        iconColor: _capteursActifs < _capteursTotalCount
                            ? AppColors.amber800 : AppColors.green700,
                        value: '$_capteursActifs',
                        unit: '/$_capteursTotalCount',
                        label: 'Capteurs actifs',
                        badge: badgeCapteurs,
                        badgeBg: badgeCapteursBg,
                        badgeText: badgeCapteursText,
                      ),
                      MetricCard(
                        icon: Icons.warning_amber_outlined,
                        iconBg: _alertesActives > 0 ? AppColors.red100 : AppColors.green100,
                        iconColor: _alertesActives > 0 ? AppColors.red800 : AppColors.green700,
                        value: '$_alertesActives',
                        unit: '',
                        label: 'Alertes actives',
                        badge: _alertesActives > 0 ? 'Attention' : 'OK',
                        badgeBg: _alertesActives > 0 ? AppColors.red100 : AppColors.green100,
                        badgeText: _alertesActives > 0 ? AppColors.red800 : AppColors.green700,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Graphique humidité ─────────────────────────────────
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
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                              child: const Text('Voir tout',
                                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
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

                  // ── Alertes récentes ───────────────────────────────────
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
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                              child: const Text('Tout voir',
                                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._alertesRecentes.asMap().entries.map((entry) {
                          final i = entry.key;
                          final a = entry.value;
                          return AlertRow(
                            dotColor: _couleurAlerte(a['couleur'] as String),
                            title:    a['titre'] as String,
                            time:     a['temps'] as String,
                            isLast:   i == _alertesRecentes.length - 1,
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

// ─────────────────────────────────────────────────────────────────────────────
// AlertRow — inchangé, conservé ici pour compatibilité
// ─────────────────────────────────────────────────────────────────────────────
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
            : const Border(bottom: BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HumidityChartPainter — reçoit maintenant le seuil dynamique
// ─────────────────────────────────────────────────────────────────────────────
class HumidityChartPainter extends CustomPainter {
  final int seuil;
  const HumidityChartPainter({this.seuil = 60});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 25.0;

    // Axe Y labels
    final tp = TextPainter(textAlign: TextAlign.left, textDirection: TextDirection.ltr);
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

    // Ligne seuil dynamique (pointillée rouge)
    final seuilY = (1 - seuil / 100) * size.height;
    final seuilPaint = Paint()
      ..color = AppColors.red600.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double dist = leftPadding;
    bool draw = true;
    while (dist < size.width) {
      final next = (dist + (draw ? 6 : 4)).clamp(leftPadding, size.width);
      if (draw) canvas.drawLine(Offset(dist, seuilY), Offset(next, seuilY), seuilPaint);
      dist = next;
      draw = !draw;
    }

    // Courbe humidité
    final paint = Paint()
      ..color = AppColors.green600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.green600.withOpacity(0.15), AppColors.green600.withOpacity(0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final pts = [0.55, 0.45, 0.35, 0.50, 0.30, 0.42, 0.35];
    final offsets = pts.asMap().entries.map((e) =>
        Offset(leftPadding + e.key * (size.width - leftPadding) / (pts.length - 1),
               e.value * size.height)).toList();

    final fillPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) fillPath.lineTo(o.dx, o.dy);
    fillPath..lineTo(offsets.last.dx, size.height)..lineTo(offsets.first.dx, size.height)..close();
    canvas.drawPath(fillPath, fill);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) linePath.lineTo(o.dx, o.dy);
    canvas.drawPath(linePath, paint);

    // Point final
    canvas.drawCircle(offsets.last, 4,
        Paint()..color = AppColors.green600..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(HumidityChartPainter old) => old.seuil != seuil;
}