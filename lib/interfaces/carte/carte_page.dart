import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../services/champ_service.dart';
import '../../services/capteur_service.dart';
import 'detail_capteur_page.dart';
import 'parametre_champ_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Données statiques de fallback (affichées si le backend est inaccessible)
// ─────────────────────────────────────────────────────────────────────────────
const _capteursStatiques = [
  {'id': 'C1', 'zone': 'Zone A', 'humidite': 74, 'batterie': 87, 'statut': 'actif',    'surface': '0.8 ha', 'lat': 0.12, 'lng': 0.18},
  {'id': 'C2', 'zone': 'Zone A', 'humidite': 69, 'batterie': 72, 'statut': 'actif',    'surface': '0.7 ha', 'lat': 0.30, 'lng': 0.38},
  {'id': 'C3', 'zone': 'Zone B', 'humidite': 48, 'batterie': 61, 'statut': 'alerte',   'surface': '1.1 ha', 'lat': 0.10, 'lng': 0.62},
  {'id': 'C4', 'zone': 'Zone B', 'humidite': 61, 'batterie': 55, 'statut': 'actif',    'surface': '0.9 ha', 'lat': 0.32, 'lng': 0.75},
  {'id': 'C5', 'zone': 'Zone C', 'humidite': 81, 'batterie': 91, 'statut': 'actif',    'surface': '1.2 ha', 'lat': 0.60, 'lng': 0.20},
  {'id': 'C6', 'zone': 'Zone C', 'humidite': 77, 'batterie': 63, 'statut': 'actif',    'surface': '0.8 ha', 'lat': 0.72, 'lng': 0.42},
  {'id': 'C7', 'zone': 'Zone D', 'humidite': 65, 'batterie': 22, 'statut': 'batterie', 'surface': '0.9 ha', 'lat': 0.58, 'lng': 0.68},
  {'id': 'C8', 'zone': 'Zone D', 'humidite': 0,  'batterie': 0,  'statut': 'inactif',  'surface': '0.5 ha', 'lat': 0.78, 'lng': 0.80},
];

const _champsStatiques = [
  {'nom': 'Champ Nord', 'superficie': 4.2},
];

// ─────────────────────────────────────────────────────────────────────────────
// CarteScreen
// ─────────────────────────────────────────────────────────────────────────────
class CarteScreen extends StatefulWidget {
  const CarteScreen({super.key});

  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

class _CarteScreenState extends State<CarteScreen> {
  int _selectedCapteur = 0;

  // Les listes travaillent toujours avec Map<String, dynamic>
  // → même format que les données statiques ET que l'API (après conversion)
  List<Map<String, dynamic>> capteurs = [];
  List<Map<String, dynamic>> champs   = [];

  bool isLoading = true;
  bool _depuisBackend = false; // indique si les données viennent du serveur

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ── Chargement : API en priorité, fallback statique sinon ─────────────────
  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final capteurService = context.read<CapteurService>();
      final champService   = context.read<ChampService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        champService.getChamps(),
      ]);

      final capteursApi = results[0] as List;
      final champsApi   = results[1] as List;

      // Conversion CapteurModel → Map (même format que statique)
      final capteursMap = capteursApi.map((c) {
        final statut = _statutDepuisApi(c.etat, c.batterie as int? ?? 0);
        return <String, dynamic>{
          'id':       c.id,
          'zone':     c.nom,
          'humidite': 0,               // absent de l'API → 0 par défaut
          'batterie': c.batterie ?? 0,
          'statut':   statut,
          'surface':  '${c.surfaceCouverte ?? '—'} ha',
          'lat':      (c.latitude  as double? ?? 0.0) % 1.0,
          'lng':      (c.longitude as double? ?? 0.0) % 1.0,
          // champs supplémentaires pour DetailCapteurScreen
          'nom':               c.nom,
          'type_capteur':      c.typeCapteur,
          'surface_couverte':  c.surfaceCouverte,
          'derniere_connexion': c.derniereConnexion,
        };
      }).toList();

      final champsMap = champsApi.map((c) => <String, dynamic>{
        'nom':        c.nom,
        'superficie': c.superficie,
        // on garde l'objet complet pour ParametreChampScreen
        '_model': c,
      }).toList();

      setState(() {
        capteurs       = capteursMap.isNotEmpty ? capteursMap : List<Map<String, dynamic>>.from(_capteursStatiques);
        champs         = champsMap.isNotEmpty   ? champsMap   : List<Map<String, dynamic>>.from(_champsStatiques);
        _depuisBackend = capteursMap.isNotEmpty;
        _selectedCapteur = 0;
        isLoading      = false;
      });
    } catch (_) {
      // Backend inaccessible → données statiques
      setState(() {
        capteurs       = List<Map<String, dynamic>>.from(_capteursStatiques);
        champs         = List<Map<String, dynamic>>.from(_champsStatiques);
        _depuisBackend = false;
        _selectedCapteur = 0;
        isLoading      = false;
      });
    }
  }

  // Dérive le statut depuis etat + batterie (champs réels de l'API)
  String _statutDepuisApi(String? etat, int batterie) {
    if (etat == 'inactif') return 'inactif';
    if (batterie <= 20)    return 'batterie';
    return 'actif';
  }

  // ── Helpers couleur / label ───────────────────────────────────────────────
  Color _couleurStatut(String s) {
    switch (s) {
      case 'actif':    return AppColors.green600;
      case 'alerte':   return AppColors.red600;
      case 'batterie': return AppColors.amber600;
      default:         return const Color(0xFFB4B2A9);
    }
  }

  Color _bgStatut(String s) {
    switch (s) {
      case 'actif':    return AppColors.green100;
      case 'alerte':   return AppColors.red100;
      case 'batterie': return AppColors.amber100;
      default:         return AppColors.gray50;
    }
  }

  String _labelStatut(String s) {
    switch (s) {
      case 'actif':    return 'Actif';
      case 'alerte':   return 'Alerte';
      case 'batterie': return 'Batterie';
      default:         return 'Inactif';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final mapH    = MediaQuery.of(context).size.height * 0.42;
    final champ   = champs.isNotEmpty ? champs.first : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Carte du champ'),
            Text(
              champ != null
                  ? '${champ['nom']} · ${champ['superficie']} ha · ${capteurs.length} capteurs'
                  : '${capteurs.length} capteurs',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          // Indicateur de source (backend ou statique)
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend ? 'Données en ligne' : 'Données locales (demo)',
                child: Icon(
                  _depuisBackend ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: _depuisBackend ? AppColors.green600 : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          // Bouton rafraîchir
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh, color: AppColors.green700, size: 17),
            ),
          ),
          // Bouton paramètres
          IconButton(
            onPressed: champs.isEmpty ? null : () {
              // Si données API disponibles, passe le ChampModel
              // Sinon navigue sans paramètre obligatoire (ParametreChampScreen simple)
              final model = champ?['_model'];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => model != null
                      ? ParametreChampScreen(champ: model)
                      : const ParametreChampScreen(),
                ),
              );
            },
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.tune, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ══════════════ CARTE ══════════════
                SizedBox(
                  height: mapH,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://media.istockphoto.com/id/503435699/photo/corn-field-in-the-evening-light.jpg?s=170667a&w=0&k=20&c=igER6vT2XhJt-hsnBLIVVFcAyIdtBPL7CsuIwNM-bJ0=',
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFF7AAA40),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4A8012), Color(0xFF8AB855)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.landscape, color: Colors.white54, size: 64),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.18),
                                Colors.transparent,
                                Colors.black.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(child: CustomPaint(painter: _ZonesPainter())),
                      ..._buildCapteurPins(screenW, mapH),

                      // Légende
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.93),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Légende',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                              const SizedBox(height: 5),
                              _LegendItem(color: AppColors.green600, label: 'Actif'),
                              _LegendItem(color: AppColors.red600,   label: 'Alerte'),
                              _LegendItem(color: AppColors.amber600, label: 'Batterie'),
                              _LegendItem(color: const Color(0xFFB4B2A9), label: 'Inactif'),
                            ],
                          ),
                        ),
                      ),

                      // Popup capteur sélectionné
                      if (capteurs.isNotEmpty)
                        Positioned(
                          bottom: 10, left: 10, right: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailCapteurScreen(capteur: capteurs[_selectedCapteur]),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: _bgStatut(capteurs[_selectedCapteur]['statut']),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(Icons.sensors,
                                        color: _couleurStatut(capteurs[_selectedCapteur]['statut']), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${capteurs[_selectedCapteur]['id']} — ${capteurs[_selectedCapteur]['zone']}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Humidité ${capteurs[_selectedCapteur]['humidite']}% · '
                                          'Batterie ${capteurs[_selectedCapteur]['batterie']}% · '
                                          '${capteurs[_selectedCapteur]['surface']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusPill(
                                    label: _labelStatut(capteurs[_selectedCapteur]['statut']),
                                    bg: _bgStatut(capteurs[_selectedCapteur]['statut']),
                                    textColor: _couleurStatut(capteurs[_selectedCapteur]['statut']),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ══════════════ LISTE ══════════════
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ÉTAT DES CAPTEURS',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted, letterSpacing: 0.8)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.green100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${capteurs.where((e) => e['statut'] == 'actif').length}/${capteurs.length} actifs',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.green700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: capteurs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 7),
                          itemBuilder: (context, i) => _CapteurListTile(
                            capteur: capteurs[i],
                            isSelected: _selectedCapteur == i,
                            couleur: _couleurStatut(capteurs[i]['statut']),
                            bg: _bgStatut(capteurs[i]['statut']),
                            label: _labelStatut(capteurs[i]['statut']),
                            onTap: () {
                              setState(() => _selectedCapteur = i);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailCapteurScreen(capteur: capteurs[i]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildCapteurPins(double screenW, double mapH) {
    return capteurs.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      final isSelected = _selectedCapteur == i;
      final left = (c['lng'] as double) * (screenW - 60);
      final top  = (c['lat'] as double) * (mapH - 120);

      return Positioned(
        left: left.clamp(10.0, screenW - 60),
        top:  top.clamp(10.0, mapH - 120),
        child: GestureDetector(
          onTap: () => setState(() => _selectedCapteur = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:  isSelected ? 46 : 34,
            height: isSelected ? 46 : 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _couleurStatut(c['statut']),
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _couleurStatut(c['statut']).withOpacity(0.4),
                  blurRadius: isSelected ? 14 : 4,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                c['id'],
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: FontWeight.w700,
                  color: _couleurStatut(c['statut']),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CapteurListTile
// ─────────────────────────────────────────────────────────────────────────────
class _CapteurListTile extends StatelessWidget {
  final Map<String, dynamic> capteur;
  final bool isSelected;
  final Color couleur, bg;
  final String label;
  final VoidCallback onTap;

  const _CapteurListTile({
    required this.capteur,
    required this.isSelected,
    required this.couleur,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isSelected ? bg : AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? couleur : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              child: Center(
                child: Text(capteur['id'],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${capteur['id']} — ${capteur['zone']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
                  Text('Hum. ${capteur['humidite']}% · ${capteur['surface']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(label: label, bg: bg, textColor: couleur),
                const SizedBox(height: 5),
                Row(
                  children: [
                    SizedBox(
                      width: 44, height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (capteur['batterie'] as int) / 100,
                          backgroundColor: const Color(0xFFE8EDE4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            capteur['batterie'] > 40
                                ? AppColors.green600
                                : capteur['batterie'] > 20
                                    ? AppColors.amber600
                                    : AppColors.red600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${capteur['batterie']}%',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ZonesPainter
// ─────────────────────────────────────────────────────────────────────────────
class _ZonesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final zones = [
      Path()..moveTo(0, 0)..lineTo(size.width * .5, 0)..lineTo(size.width * .5, size.height * .5)..lineTo(0, size.height * .5)..close(),
      Path()..moveTo(size.width * .5, 0)..lineTo(size.width, 0)..lineTo(size.width, size.height * .5)..lineTo(size.width * .5, size.height * .5)..close(),
      Path()..moveTo(0, size.height * .5)..lineTo(size.width * .5, size.height * .5)..lineTo(size.width * .5, size.height)..lineTo(0, size.height)..close(),
      Path()..moveTo(size.width * .5, size.height * .5)..lineTo(size.width, size.height * .5)..lineTo(size.width, size.height)..lineTo(size.width * .5, size.height)..close(),
    ];

    for (final p in zones) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, stroke);
    }

    final ts = TextStyle(
      color: Colors.white.withOpacity(0.88),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
    );
    final labels  = ['Zone A', 'Zone B', 'Zone C', 'Zone D'];
    final offsets = [
      Offset(size.width * .06, size.height * .04),
      Offset(size.width * .57, size.height * .04),
      Offset(size.width * .06, size.height * .54),
      Offset(size.width * .57, size.height * .54),
    ];
    for (int i = 0; i < 4; i++) {
      (TextPainter(text: TextSpan(text: labels[i], style: ts), textDirection: TextDirection.ltr)..layout())
          .paint(canvas, offsets[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _LegendItem
// ─────────────────────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 9, height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text)),
          ],
        ),
      );
}