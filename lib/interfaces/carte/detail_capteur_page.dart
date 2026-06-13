import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import '../../services/capteur_service.dart';

class DetailCapteurScreen extends StatefulWidget {
  final Map<String, dynamic> capteur;

  const DetailCapteurScreen({
    super.key,
    required this.capteur,
  });

  @override
  State<DetailCapteurScreen> createState() => _DetailCapteurScreenState();
}

class _DetailCapteurScreenState extends State<DetailCapteurScreen> {
  Map<String, dynamic>? capteurData;
  bool isLoading = true;

  // Retourne les données chargées si disponibles, sinon les données passées en paramètre
  Map<String, dynamic> get _capteur => capteurData ?? widget.capteur;

  Future<void> fetchCapteur() async {
    // Récupère l'UUID réel du capteur (stocké dans 'uuid' lors du mapping dans carte_page)
    final uuid = widget.capteur['uuid'] as String? ?? widget.capteur['id'] as String?;
    if (uuid == null || uuid.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final capteurService = context.read<CapteurService>();
      final capteurModel = await capteurService.getCapteur(uuid);

      // Convertit le modèle en map pour rester compatible avec le reste de la page
      setState(() {
        capteurData = {
          ...widget.capteur, // conserve id court (C1, C2...), zone, statut, humidite
          'batterie':           capteurModel.batterie ?? widget.capteur['batterie'],
          'etat':               capteurModel.etat,
          'type_capteur':       capteurModel.typeCapteur ?? widget.capteur['type_capteur'],
          'surface_couverte':   capteurModel.surfaceCouverte ?? widget.capteur['surface_couverte'],
          'derniere_connexion': capteurModel.derniereConnexion
              ?? widget.capteur['derniere_connexion'],
        };
        isLoading = false;
      });
    } catch (_) {
      // Fallback sur les données passées depuis carte_page
      setState(() {
        capteurData = widget.capteur;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCapteur();
  }

  // Les getters utilisent _capteur (données chargées ou fallback)
  Color get _couleur {
    switch (_capteur['statut']) {
      case 'actif':
        return AppColors.green600;
      case 'alerte':
        return AppColors.red600;
      case 'batterie':
        return AppColors.amber600;
      default:
        return const Color(0xFFB4B2A9);
    }
  }

  Color get _bg {
    switch (_capteur['statut']) {
      case 'actif':
        return AppColors.green100;
      case 'alerte':
        return AppColors.red100;
      case 'batterie':
        return AppColors.amber100;
      default:
        return AppColors.gray50;
    }
  }

  String get _label {
    switch (_capteur['statut']) {
      case 'actif':
        return 'Actif';
      case 'alerte':
        return 'Alerte humidité';
      case 'batterie':
        return 'Batterie faible';
      default:
        return 'Inactif';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affiche un loader pendant le chargement
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Utilise le getter _capteur (données chargées ou fallback)
    final capteur = _capteur;
    final bool isAlerte = capteur['statut'] == 'alerte';
    final bool isBatterie = capteur['statut'] == 'batterie';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${capteur['id']} — ${capteur['zone']}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusPill(label: _label, bg: _bg, textColor: _couleur),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image du champ associée au capteur ────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _imageUrl(capteur),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: AppColors.green100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.green600,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.green100,
                        child: const Center(
                          child: Icon(
                            Icons.grass,
                            color: AppColors.green600,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    // Badge zone
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${capteur['id']} · ${capteur['zone']} · ${capteur['surface']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Alerte overlay si critique
                    if (isAlerte)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red600.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Humidité critique !',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Métriques clés ────────────────────────────────────────────
            Row(
              children: [
                _MetricTile(
                  icon: Icons.water_drop_outlined,
                  iconBg: isAlerte ? AppColors.red100 : AppColors.green100,
                  iconColor:
                      isAlerte ? AppColors.red600 : AppColors.green700,
                  label: 'Humidité',
                  value: '${capteur['humidite'] ?? 0}%',
                  valueColor:
                      isAlerte ? AppColors.red600 : AppColors.text,
                ),
                const SizedBox(width: 9),
                _MetricTile(
                  icon: Icons.battery_charging_full,
                  iconBg:
                      isBatterie ? AppColors.amber100 : AppColors.green100,
                  iconColor:
                      isBatterie ? AppColors.amber600 : AppColors.green700,
                  label: 'Batterie',
                  value: '${capteur['batterie'] ?? 0}%',
                  valueColor:
                      isBatterie ? AppColors.amber600 : AppColors.text,
                ),
                const SizedBox(width: 9),
                const _MetricTile(
                  icon: Icons.wifi,
                  iconBg: AppColors.green100,
                  iconColor: AppColors.green700,
                  label: 'Signal',
                  value: 'Fort',
                  valueColor: AppColors.text,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Alerte si humidité critique ───────────────────────────────
            if (isAlerte) ...[
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.red100,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.red600.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.red600,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Humidité critique détectée',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Le taux d\'humidité est en dessous du seuil de 60%. '
                            'Une irrigation immédiate est recommandée.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.red800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Alerte si batterie faible ─────────────────────────────────
            if (isBatterie) ...[
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.amber600.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.battery_alert,
                      color: AppColors.amber600,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batterie faible',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.amber800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'La batterie du capteur est à 22%. '
                            'Planifiez un rechargement dans les 48h.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.amber800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Historique humidité (mini graphe) ─────────────────────────
            const SectionLabel('Humidité — 7 derniers jours'),
            AppCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 90,
                    child: CustomPaint(
                      painter: _MiniChartPainter(statut: capteur['statut']),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Auj']
                        .map(
                          (d) => Text(
                            d,
                            style: TextStyle(
                              fontSize: 9,
                              color: d == 'Auj'
                                  ? AppColors.green700
                                  : AppColors.textMuted,
                              fontWeight: d == 'Auj'
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Informations capteur ──────────────────────────────────────
            const SectionLabel('Informations du capteur'),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(label: 'Identifiant', value: capteur['id'] ?? '—'),
                  _InfoRow(label: 'Zone', value: capteur['zone'] ?? '—'),
                  _InfoRow(
                    label: 'Surface couverte',
                    value: capteur['surface'] ?? '—',
                  ),
                  const _InfoRow(
                    label: 'Dernière mesure',
                    value: 'Il y a 3 min',
                  ),
                  const _InfoRow(
                    label: 'Fréquence mesure',
                    value: 'Toutes les 5 min',
                  ),
                  const _InfoRow(
                    label: 'Modèle',
                    value: 'AgriSensor Pro v2',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Bouton action ─────────────────────────────────────────────
            /*SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.water_drop, size: 16),
                label: Text(
                  isAlerte
                      ? 'Lancer l\'irrigation sur ${capteur['zone']}'
                      : 'Voir l\'historique complet',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAlerte ? AppColors.red600 : AppColors.green600,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Prendre une image maintenant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green700,
                  side: const BorderSide(color: AppColors.green600, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),*/

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Accepte explicitement le map capteur pour éviter toute ambiguïté
  String _imageUrl(Map<String, dynamic> capteur) {
    final urls = [
      'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=700&q=80',
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=700&q=80',
      'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=700&q=80',
      'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=700&q=80',
    ];
    final id = capteur['id'] as String? ?? 'C1';
    final idx = int.tryParse(id.replaceAll('C', '')) ?? 1;
    return urls[(idx - 1) % urls.length];
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor, valueColor;
  final String label, value;

  const _MetricTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F5EB), width: 0.5),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final String statut;

  const _MiniChartPainter({required this.statut});

  @override
  void paint(Canvas canvas, Size size) {
    final color = statut == 'alerte'
        ? AppColors.red600
        : statut == 'batterie'
            ? AppColors.amber600
            : AppColors.green600;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.18), color.withOpacity(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final rawPts = statut == 'alerte'
        ? [0.45, 0.40, 0.38, 0.42, 0.35, 0.30, 0.28]
        : statut == 'batterie'
            ? [0.50, 0.48, 0.45, 0.50, 0.42, 0.40, 0.38]
            : [0.40, 0.35, 0.30, 0.38, 0.25, 0.32, 0.28];

    final pts = rawPts
        .asMap()
        .entries
        .map(
          (e) => Offset(
            e.key * size.width / (rawPts.length - 1),
            e.value * size.height,
          ),
        )
        .toList();

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }

    final fillPath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      fillPath.lineTo(pts[i].dx, pts[i].dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    // Lignes de grille
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDE4)
      ..strokeWidth = 0.5;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, y * size.height),
        Offset(size.width, y * size.height),
        gridPaint,
      );
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, paint);

    // Point final (dernier relevé)
    canvas.drawCircle(
      pts.last,
      4,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pts.last,
      4,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}