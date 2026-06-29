
// lib/interfaces/images/images_page.dart
/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/image.dart';
import '../../models/capteur.dart';
import '../../services/image_service.dart';
import '../../services/capteur_service.dart';
import 'analyse_ia_page.dart';
import '../../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImagesScreen
// ─────────────────────────────────────────────────────────────────────────────
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  List<CapteurModel> _capteurs      = [];
  List<CaptureImage> _images        = [];
  String?            _capteurSelId;
  String             _filtre        = 'Toutes';
  bool               _isLoading     = true;
  bool               _depuisBackend = false;

  final List<String> _filtres = ['Toutes', 'Alertes', 'Analysées', 'Normales'];

  /*@override
  void initState() {
    super.initState();
    _loadAll();
  }*/
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAll();
  });
}
 
  // ── Chargement ────────────────────────────────────────────────────────────
  Future<void> _loadAll({int retryCount = 0, int maxRetries = 3}) async {
    setState(() => _isLoading = true);

    try {
      final capteurService = context.read<CapteurService>();
      final imageService   = context.read<ImageService>();

      // 1. Charger les capteurs depuis le backend
      final capteurs = await capteurService.getCapteurs();

      // 2. Charger les images de tous les capteurs en parallèle
      final capteurIds = capteurs.map((c) => c.id).toList();
      final imagesApi  = await imageService.getImagesMultiCapteurs(capteurIds);

      // 3. Convertir ImageApi → CaptureImage avec nom du capteur
      final capteurMap = {for (final c in capteurs) c.id: c};
      final images = imagesApi.map((img) {
        final c = capteurMap[img.noeudCapteurId];
        return img.toCaptureImage(
          nomCapteur: c?.nom ?? img.noeudCapteurId.substring(0, 8),
          zone:       c?.nom ?? '',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _capteurs      = capteurs;
        _images        = images;
        _capteurSelId  = capteurs.isNotEmpty ? capteurs.first.id : null;
        _depuisBackend = true;
        _isLoading     = false;
      });
    } catch (e) {
      // Réessayer automatiquement si première tentative échoue
      if (retryCount < maxRetries && !_depuisBackend) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _loadAll(retryCount: retryCount + 1, maxRetries: maxRetries);
        }
      } else {
        // Fallback mock si tous les retries ont échoué
        if (!mounted) return;
        setState(() {
          _capteurs      = [];
          _images        = List.from(mockImages);
          _capteurSelId  = null;
          _depuisBackend = false;
          _isLoading     = false;
        });
      }
    }
  }

  // ── Images filtrées ───────────────────────────────────────────────────────
  List<CaptureImage> get _imgsFiltrees {
    List<CaptureImage> base = _images;

    // Filtre par capteur sélectionné
    if (_capteurSelId != null && _depuisBackend) {
      base = base.where((i) => i.capteurId == _capteurSelId).toList();
    }

    // Filtre par statut
    switch (_filtre) {
      case 'Alertes':   return base.where((i) => i.statut == 'alerte').toList();
      case 'Analysées': return base.where((i) => i.statut == 'analysee').toList();
      case 'Normales':  return base.where((i) => i.statut == 'normale').toList();
      default:          return base;
    }
  }

  int get _alertes => _images.where((i) => i.statut == 'alerte').length;

  // ── Demander image à un capteur ───────────────────────────────────────────
  Future<void> _demanderImage(CapteurModel capteur) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Capturer — ${capteur.nom}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(
                color: AppColors.green100, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: AppColors.green700, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            'Déclencher la caméra du capteur "${capteur.nom}" ?\n\n'
            'L\'image apparaîtra automatiquement dans le flux dès réception.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.camera_alt, size: 15),
            label: const Text('Déclencher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // TODO: envoyer commande MQTT/WebSocket au capteur physique
    // Le capteur appellera POST /images quand la photo sera prise
    // On recharge après 3s pour simuler la réception
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 10),
        Text('Demande d\'image envoyée au ${capteur.nom}...'),
      ]),
      backgroundColor: AppColors.green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 3),
    ));

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _loadAll();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Images & capteurs'),
            Row(children: [
              const Text('Analyse visuelle du champ',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              if (!_isLoading)
                Icon(
                  _depuisBackend
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 12,
                  color: _depuisBackend
                      ? AppColors.green600
                      : AppColors.textMuted,
                ),
            ]),
          ],
        ),
        actions: [
          // Badge alertes
          if (_alertes > 0)
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
                  child: Center(child: Text('$_alertes',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w700))),
                ),
              ),
            ]),
          // Rafraîchir
          IconButton(
            onPressed: _isLoading ? null : _loadAll,
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.green700))
                  : const Icon(Icons.refresh,
                      color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.green600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Mode hors ligne ──────────────────────────────────
                    if (!_depuisBackend)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.amber100.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.amber600.withOpacity(0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.cloud_off_outlined,
                              color: AppColors.amber800, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            'Backend inaccessible — images de démonstration affichées.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.amber800),
                          )),
                        ]),
                      ),

                    // ── Bandeau alertes ──────────────────────────────────
                    if (_alertes > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.red100,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: AppColors.red600.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.red600, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            '$_alertes alerte${_alertes > 1 ? "s" : ""} IA — '
                            'vérification terrain recommandée.',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.red800),
                          )),
                        ]),
                      ),

                    // ── Sélecteur capteur ────────────────────────────────
                    if (_capteurs.isNotEmpty) ...[
                      const SectionLabel('Capteurs multimédias'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capteurs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 7),
                          itemBuilder: (_, i) {
                            final c   = _capteurs[i];
                            final sel = _capteurSelId == c.id;
                            final isActif = c.etat == 'actif';
                            // Nombre d'images non traitées pour ce capteur
                            final nonTraitees = _images
                                .where((img) =>
                                    img.capteurId == c.id &&
                                    img.statut == 'normale')
                                .length;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _capteurSelId = c.id),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? (isActif
                                          ? AppColors.green100
                                          : AppColors.red100)
                                      : AppColors.white,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? (isActif
                                            ? AppColors.green600
                                            : AppColors.red600)
                                        : AppColors.border,
                                    width: sel ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(children: [
                                  Text(
                                    c.nom.length > 10
                                        ? '${c.nom.substring(0, 10)}…'
                                        : c.nom,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: sel
                                          ? (isActif
                                              ? AppColors.green700
                                              : AppColors.red800)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (nonTraitees > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 16, height: 16,
                                      decoration: const BoxDecoration(
                                          color: AppColors.amber600,
                                          shape: BoxShape.circle),
                                      child: Center(
                                        child: Text('$nonTraitees',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight:
                                                    FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Carte capteur sélectionné
                      if (_capteurSelId != null)
                        _buildCapteurCard(
                          _capteurs.firstWhere(
                              (c) => c.id == _capteurSelId,
                              orElse: () => _capteurs.first),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // ── Filtres ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionLabel('Captures reçues'),
                        Text(
                          '${_imgsFiltrees.length} image${_imgsFiltrees.length > 1 ? "s" : ""}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filtres.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 7),
                        itemBuilder: (_, i) {
                          final f   = _filtres[i];
                          final sel = _filtre == f;
                          return GestureDetector(
                            onTap: () => setState(() => _filtre = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.green100
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.green600
                                      : AppColors.border,
                                  width: sel ? 1.5 : 0.5,
                                ),
                              ),
                              child: Text(f,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: sel
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: sel
                                        ? AppColors.green700
                                        : AppColors.textMuted,
                                  )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Grille images ────────────────────────────────────
                    if (_imgsFiltrees.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(children: [
                            const Icon(Icons.photo_library_outlined,
                                color: AppColors.textMuted, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _depuisBackend
                                  ? 'Aucune image reçue pour ce filtre'
                                  : 'Aucune image disponible',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted),
                            ),
                          ]),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: _imgsFiltrees.length,
                        itemBuilder: (ctx, i) {
                          final img = _imgsFiltrees[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _DetailImageScreen(image: img),
                              ),
                            ),
                            child: _ImageCard(image: img),
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // ── Bandeau IA ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: const Row(children: [
                        Icon(Icons.psychology_outlined,
                            color: AppColors.green600, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analyse IA automatique',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.text)),
                              SizedBox(height: 2),
                              Text(
                                'Chaque image reçue est analysée automatiquement. '
                                'Le résultat (normale / alerte) apparaît dès traitement. '
                                'Backend IA en cours de développement.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Carte capteur sélectionné ──────────────────────────────────────────────
  Widget _buildCapteurCard(CapteurModel capteur) {
    final isActif  = capteur.etat == 'actif';
    final batterie = capteur.batterie ?? 0;
    final batColor = batterie > 40
        ? AppColors.green600
        : batterie > 20
            ? AppColors.amber600
            : AppColors.red600;

    // Images non traitées pour ce capteur
    final nonTraitees = _images
        .where((i) => i.capteurId == capteur.id && i.statut == 'normale')
        .length;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(capteur.nom,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActif ? AppColors.green100 : AppColors.red100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActif ? 'Actif' : 'Inactif',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActif
                      ? AppColors.green700
                      : AppColors.red800),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _InfoStat(
            icon: Icons.battery_full,
            iconColor: batColor,
            label: 'Batterie',
            value: '$batterie%',
          ),
          _InfoStat(
            icon: Icons.sensors,
            iconColor: AppColors.green600,
            label: 'Type',
            value: capteur.typeCapteur ?? 'Multimédia',
          ),
          if (capteur.surfaceCouverte != null)
            _InfoStat(
              icon: Icons.straighten,
              iconColor: AppColors.green600,
              label: 'Surface',
              value: '${capteur.surfaceCouverte!.toStringAsFixed(1)} ha',
            ),
          _InfoStat(
            icon: Icons.photo_library_outlined,
            iconColor: AppColors.green600,
            label: 'Images',
            value:
                '${_images.where((i) => i.capteurId == capteur.id).length}',
          ),
        ]),

        // Images en attente d'analyse
        if (nonTraitees > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber100.withOpacity(0.6),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: AppColors.amber600.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.hourglass_top_outlined,
                  size: 13, color: AppColors.amber800),
              const SizedBox(width: 6),
              Text(
                '$nonTraitees image${nonTraitees > 1 ? "s" : ""} en attente d\'analyse IA',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.amber800),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                isActif ? () => _demanderImage(capteur) : null,
            icon: const Icon(Icons.camera_alt_outlined, size: 15),
            label: const Text('Prendre une image maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.green200,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailImageScreen
// ─────────────────────────────────────────────────────────────────────────────
class _DetailImageScreen extends StatelessWidget {
  final CaptureImage image;
  const _DetailImageScreen({required this.image});

  @override
  Widget build(BuildContext context) {
    final isAlerte   = image.statut == 'alerte';
    final isAnalysee = image.statut == 'analysee';
    final isAttente  = image.statut == 'en_attente';

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Grande image ─────────────────────────────────────────
            SizedBox(
              height: 300, width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                image.imageUrl.startsWith('http')
                    ? Image.network(
                        image.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : Container(
                                color: AppColors.green100,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.green600,
                                        strokeWidth: 2))),
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
                // Gradient
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 120,
                    decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [Colors.transparent,
                          Colors.black.withOpacity(0.75)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )),
                  ),
                ),
                // Badge alerte
                if (isAlerte)
                  Positioned(bottom: 62, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.red600.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(children: [
                        Icon(Icons.warning_amber,
                            color: Colors.white, size: 13),
                        SizedBox(width: 5),
                        Text('Anomalie détectée',
                            style: TextStyle(color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                // Info bas
                Positioned(bottom: 16, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(image.capteurNom,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            Text('${image.date} · ${image.heure}',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      _StatutBadge(statut: image.statut),
                    ],
                  ),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Analyse en attente ───────────────────────────────
                  if (isAttente)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.amber100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.amber600.withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.amber600)),
                        SizedBox(width: 10),
                        Expanded(child: Text('Analyse IA en cours...',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.amber800))),
                      ]),
                    ),

                  // ── Résultat IA — Alerte ─────────────────────────────
                  if (isAlerte && image.anomalie != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.red100,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: AppColors.red600.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.red600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(image.anomalie!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.red800)),
                            ),
                          ]),
                          if (image.confiance > 0) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.psychology_outlined,
                                  size: 13, color: AppColors.red600),
                              const SizedBox(width: 4),
                              Text(
                                  'Confiance IA : ${image.confiance}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.red800)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Recommandation IA ────────────────────────────────
                  if (image.recommandation != null) ...[
                    const SectionLabel('Recommandation IA'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isAlerte
                            ? AppColors.amber100.withOpacity(0.6)
                            : AppColors.green100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isAlerte
                              ? AppColors.amber600.withOpacity(0.3)
                              : AppColors.green600.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isAlerte
                                ? Icons.medical_services_outlined
                                : Icons.check_circle_outline,
                            color: isAlerte
                                ? AppColors.amber800
                                : AppColors.green700,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(image.recommandation!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isAlerte
                                        ? AppColors.amber800
                                        : AppColors.green800,
                                    height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Résultat IA — OK ─────────────────────────────────
                  if (isAnalysee && image.anomalie == null) ...[
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.green100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.green600.withOpacity(0.2)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.green700, size: 18),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Aucune anomalie détectée — végétation saine.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.green800),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Informations capture ─────────────────────────────
                  const SectionLabel('Informations'),
                  AppCard(
                    child: Column(children: [
                      _InfoRow(label: 'Capteur', value: image.capteurNom),
                      _InfoRow(label: 'Date',    value: image.date),
                      _InfoRow(label: 'Heure',   value: image.heure),
                      _InfoRow(
                        label: 'Statut',
                        value: _labelStatut(image.statut),
                      ),
                      if (image.confiance > 0)
                        _InfoRow(
                          label: 'Confiance IA',
                          value: '${image.confiance}%',
                        ),
                      if (image.apiId != null)
                        _InfoRow(
                          label: 'ID backend',
                          value: image.apiId!.substring(0, 8) + '…',
                          isLast: true,
                        )
                      else
                        _InfoRow(
                            label: 'ID', value: image.id, isLast: true),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // ── Retour ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour aux images'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green700,
                        side: const BorderSide(
                            color: AppColors.green600, width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF3B6D11), Color(0xFF8AB855)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(child: Icon(Icons.grass,
        color: Colors.white54, size: 64)),
  );

  String _labelStatut(String s) {
    switch (s) {
      case 'alerte':     return 'Alerte IA';
      case 'analysee':   return 'Analysée — OK';
      case 'en_attente': return 'Analyse en cours';
      default:           return 'Reçue';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets atomiques
// ─────────────────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final CaptureImage image;
  const _ImageCard({required this.image});

  Color get _badgeBg {
    switch (image.statut) {
      case 'alerte':     return AppColors.red100;
      case 'analysee':   return AppColors.green100;
      case 'en_attente': return AppColors.amber100;
      default:           return const Color(0xFFF5F7F2);
    }
  }

  Color get _badgeColor {
    switch (image.statut) {
      case 'alerte':     return AppColors.red800;
      case 'analysee':   return AppColors.green700;
      case 'en_attente': return AppColors.amber800;
      default:           return AppColors.textMuted;
    }
  }

  String get _badgeLabel {
    switch (image.statut) {
      case 'alerte':     return 'Alerte';
      case 'analysee':   return 'Analysée';
      case 'en_attente': return 'En attente';
      default:           return 'Reçue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(fit: StackFit.expand, children: [
        image.imageUrl.startsWith('http')
            ? Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : Container(color: AppColors.green100,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.green600,
                                strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(
                    color: AppColors.green100,
                    child: const Center(child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.green600, size: 32))),
              )
            : Container(color: AppColors.green100,
                child: const Center(child: Icon(Icons.grass,
                    color: AppColors.green600, size: 40))),

        // Gradient bas
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(height: 70,
            decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent,
                  Colors.black.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )),
          ),
        ),

        // Badge statut
        Positioned(top: 7, right: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _badgeBg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_badgeLabel,
                style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w600, color: _badgeColor)),
          ),
        ),

        // Icône alerte
        if (image.statut == 'alerte')
          const Positioned(top: 7, left: 7,
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.red600, size: 18)),

        // Spinner en attente
        if (image.statut == 'en_attente')
          const Positioned(top: 10, left: 10,
              child: SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.amber600))),

        // Info bas
        Positioned(bottom: 7, left: 8, right: 8,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(image.capteurNom,
                style: const TextStyle(color: Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${image.date} · ${image.heure}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 9)),
          ]),
        ),
      ]),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color, bg; String label;
    switch (statut) {
      case 'alerte':
        color = AppColors.red600; bg = AppColors.red100; label = 'Alerte IA'; break;
      case 'analysee':
        color = AppColors.green600; bg = AppColors.green100; label = 'Analysée'; break;
      case 'en_attente':
        color = AppColors.amber600; bg = AppColors.amber100; label = 'En attente'; break;
      default:
        color = AppColors.textMuted; bg = AppColors.gray50; label = 'Reçue'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  const _InfoStat({required this.icon, required this.iconColor,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(8),
    margin: const EdgeInsets.only(right: 6),
    decoration: BoxDecoration(
        color: AppColors.bg, borderRadius: BorderRadius.circular(9)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconColor, size: 14),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(
          fontSize: 9, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text)),
    ]),
  ));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow({required this.label, required this.value,
      this.isLast = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(
              color: Color(0xFFF0F5EB), width: 0.5)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted)),
      Flexible(child: Text(value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w500, color: AppColors.text))),
    ]),
  );
}
*/




/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/image.dart';
import '../../models/capteur.dart';
import '../../services/image_service.dart';
import '../../services/capteur_service.dart';
import '../../services/ia_service.dart';
import 'details_image_page.dart';
import 'historique_image_page.dart';
import 'analyse_ia_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImagesScreen
// Connecté à :
//   GET /api/capteurs                   → liste des capteurs
//   GET /api/images/:capteur_id         → images du capteur sélectionné
//   POST /api/capturer                  → déclenchement capture (polling)
//   GET /api/ia/statut                  → badge disponibilité IA
// ─────────────────────────────────────────────────────────────────────────────
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  List<CapteurModel>  _capteurs      = [];
  CapteurModel?       _capteurSel;
  List<CaptureImage>  _images        = [];
  String              _filtre        = 'Toutes';
  bool                _isLoading     = true;
  bool                _isCapturing   = false;
  bool                _iaDisponible  = false;

  final List<String> _filtres = ['Toutes', 'Alertes', 'Analysées', 'En attente'];

  // ── Filtrage local ─────────────────────────────────────────────────────────
  List<CaptureImage> get _imgsFiltrees {
    switch (_filtre) {
      case 'Alertes':    return _images.where((i) => i.statut == 'alerte').toList();
      case 'Analysées':  return _images.where((i) => i.statut == 'analysee').toList();
      case 'En attente': return _images.where((i) => i.statut == 'en_attente').toList();
      default:           return _images;
    }
  }

  int get _alertesCount => _images.where((i) => i.statut == 'alerte').length;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // ── Chargement initial : capteurs + statut IA ─────────────────────────────
  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final capteurService = context.read<CapteurService>();
      final iaService      = context.read<IaService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        iaService.isDisponible(),
      ]);

      final capteurs     = results[0] as List<CapteurModel>;
      final iaDisponible = results[1] as bool;

      setState(() {
        _capteurs     = capteurs;
        _iaDisponible = iaDisponible;
        if (capteurs.isNotEmpty) _capteurSel = capteurs.first;
      });

      if (_capteurSel != null) await _loadImages(_capteurSel!);
    } catch (e) {
      _showError('Erreur de chargement : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── GET /api/images/:capteur_id ────────────────────────────────────────────
  Future<void> _loadImages(CapteurModel capteur) async {
    setState(() => _isLoading = true);
    try {
      final imageService = context.read<ImageService>();
      final images = await imageService.getImagesCapteur(capteur);
      // Trier par date décroissante
      images.sort((a, b) {
        if (a.dateCapture == null && b.dateCapture == null) return 0;
        if (a.dateCapture == null) return 1;
        if (b.dateCapture == null) return -1;
        return b.dateCapture!.compareTo(a.dateCapture!);
      });
      if (mounted) setState(() => _images = images);
    } catch (e) {
      _showError('Impossible de charger les images : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── POST /api/capturer + polling ───────────────────────────────────────────
  Future<void> _prendreImage() async {
    if (_capteurSel == null || _isCapturing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Déclencher une capture',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        content: Text(
          'Demander une photo à ${_capteurSel!.nom} maintenant ?',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Capturer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isCapturing = true);
    try {
      // TODO: Appeler POST /api/capturer/:capteur_id puis poll GET /api/capturer/:job_id
      // jusqu'à statut != 'en_attente', puis recharger les images.
      // Voir API_DOCUMENTATION.md §11 pour le flow complet.
      await Future.delayed(const Duration(seconds: 3)); // placeholder
      await _loadImages(_capteurSel!);
      _showSuccess('Capture déclenchée sur ${_capteurSel!.nom}');
    } catch (e) {
      _showError('Erreur capture : $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.red600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Images & capteurs'),
            Text('Analyse visuelle du champ',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // Badge IA disponible
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: _iaDisponible ? 'IA en ligne' : 'IA hors ligne',
              child: Icon(
                Icons.psychology_outlined,
                color: _iaDisponible ? AppColors.green600 : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
          // Bouton IA avec badge d'alertes
          if (_alertesCount > 0)
            Stack(children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AnalyseIaScreen()),
                ),
                icon: const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.green700),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.red600, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$_alertesCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          IconButton(
            onPressed: _capteurSel == null ? null : () => _loadImages(_capteurSel!),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.refresh,
                  color: AppColors.green700, size: 17),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistoriqueImagesScreen(
                        capteurs: _capteurs,
                      )),
            ),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.history,
                  color: AppColors.green700, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _capteurs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _capteurSel != null
                  ? _loadImages(_capteurSel!)
                  : _loadInitial(),
              color: AppColors.green600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sélecteur capteurs ─────────────────────────────────
                    if (_capteurs.isNotEmpty)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capteurs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 7),
                          itemBuilder: (_, i) {
                            final c   = _capteurs[i];
                            final sel = _capteurSel?.id == c.id;
                            final isActif = c.etat == 'actif';
                            return GestureDetector(
                              onTap: () {
                                setState(() => _capteurSel = c);
                                _loadImages(c);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? (isActif
                                          ? AppColors.green100
                                          : AppColors.amber100)
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? (isActif
                                            ? AppColors.green600
                                            : AppColors.amber600)
                                        : AppColors.border,
                                    width: sel ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(children: [
                                  Text(
                                    c.nom,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: sel
                                          ? (isActif
                                              ? AppColors.green700
                                              : AppColors.amber800)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (!isActif) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                            color: AppColors.amber600,
                                            shape: BoxShape.circle)),
                                  ],
                                ]),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),

                    // ── Carte capteur sélectionné ──────────────────────────
                    if (_capteurSel != null)
                      _CapteurInfoCard(
                        capteur: _capteurSel!,
                        imageCount: _images.length,
                        alerteCount: _alertesCount,
                        isCapturing: _isCapturing,
                        onCapture: _prendreImage,
                      ),

                    if (_capteurs.isEmpty)
                      _buildEmpty(),

                    const SizedBox(height: 16),

                    // ── Filtres + grille images ────────────────────────────
                    if (_images.isNotEmpty || _isLoading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionLabel('Dernières captures'),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HistoriqueImagesScreen(
                                        capteurs: _capteurs,
                                        capteurInitial: _capteurSel,
                                      )),
                            ),
                            child: const Text('Voir tout',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.green700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Filtres
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filtres.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 7),
                          itemBuilder: (_, i) {
                            final f   = _filtres[i]; 
                            final sel = _filtre == f;
                            return GestureDetector(
                              onTap: () => setState(() => _filtre = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.green100
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.green600
                                          : AppColors.border,
                                      width: sel ? 1.5 : 0.5),
                                ),
                                child: Text(f,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: sel
                                            ? AppColors.green700
                                            : AppColors.textMuted)),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Grille ou loader
                      if (_isLoading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_imgsFiltrees.isEmpty)
                        _buildEmptyFilter()
                      else
                        _buildGrille(),
                    ],

                    const SizedBox(height: 16),

                    // ── Lien vers analyse IA ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionLabel('Analyse IA'),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AnalyseIaScreen())),
                          child: const Text('Voir tout',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.green700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _IaBannerCard(
                      iaDisponible: _iaDisponible,
                      alertesCount: _alertesCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyseIaScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGrille() {
    final imageService = context.read<ImageService>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 0.95),
      itemCount: _imgsFiltrees.length,
      itemBuilder: (ctx, i) {
        final img = _imgsFiltrees[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => DetailImageScreen(
                image: img,
                capteur: _capteurSel!,
              ),
            ),
          ),
          child: _ImageCard(
              image: img,
              imageUrl: imageService.buildImageUrl(img.cheminStockage)),
        );
      },
    );
  }

  Widget _buildEmpty() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.amber100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.amber800, size: 16),
          SizedBox(width: 8),
          Expanded(
              child: Text(
            'Aucun capteur disponible. Ajoutez des capteurs depuis la page Carte.',
            style: TextStyle(fontSize: 12, color: AppColors.amber800),
          )),
        ]),
      );

  Widget _buildEmptyFilter() => Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Center(
          child: Text(
            'Aucune image pour le filtre "$_filtre".',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CapteurInfoCard
// ─────────────────────────────────────────────────────────────────────────────
class _CapteurInfoCard extends StatelessWidget {
  final CapteurModel capteur;
  final int imageCount;
  final int alerteCount;
  final bool isCapturing;
  final VoidCallback onCapture;

  const _CapteurInfoCard({
    required this.capteur,
    required this.imageCount,
    required this.alerteCount,
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final isActif  = capteur.etat == 'actif';
    final batterie = capteur.batterie ?? 100;
    final batColor = batterie > 40
        ? AppColors.green600
        : batterie > 20
            ? AppColors.amber600
            : AppColors.red600;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(capteur.nom,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: isActif ? AppColors.green100 : AppColors.gray50,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              isActif ? 'Actif' : 'Inactif',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActif
                      ? AppColors.green700
                      : AppColors.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatPill(
              icon: Icons.battery_full,
              color: batColor,
              value: '$batterie%'),
          const SizedBox(width: 8),
          _StatPill(
              icon: Icons.photo_library_outlined,
              color: AppColors.green600,
              value: '$imageCount image${imageCount > 1 ? "s" : ""}'),
          if (alerteCount > 0) ...[
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.warning_amber_outlined,
                color: AppColors.red600,
                value: '$alerteCount alerte${alerteCount > 1 ? "s" : ""}'),
          ],
        ]),
        if (capteur.derniere_connexion != null) ...[
          const SizedBox(height: 6),
          Text(
            'Dernière connexion : ${_formatDate(capteur.derniere_connexion!)}',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isActif && !isCapturing ? onCapture : null,
            icon: isCapturing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_outlined, size: 15),
            label: Text(isCapturing
                ? 'Capture en cours…'
                : 'Prendre une image maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.green200,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} à '
          '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _StatPill(
      {required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// _IaBannerCard — bannière vers AnalyseIaScreen
// ─────────────────────────────────────────────────────────────────────────────
class _IaBannerCard extends StatelessWidget {
  final bool iaDisponible;
  final int alertesCount;
  final VoidCallback onTap;

  const _IaBannerCard({
    required this.iaDisponible,
    required this.alertesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iaDisponible
                    ? AppColors.green100
                    : AppColors.gray50,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.psychology_outlined,
                color: iaDisponible
                    ? AppColors.green600
                    : AppColors.textMuted,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(
                    iaDisponible ? 'IA disponible' : 'IA hors ligne',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text),
                  ),
                  if (alertesCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.red100,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('$alertesCount alerte${alertesCount > 1 ? "s" : ""}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red800)),
                    ),
                  ],
                ]),
                Text(
                  iaDisponible
                      ? 'Analyser, diagnostiquer, prédire les cultures'
                      : 'Vérifiez la connexion au serveur Flask',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ])),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ImageCard — vignette grille
// ─────────────────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final CaptureImage image;
  final String imageUrl;
  const _ImageCard({required this.image, required this.imageUrl});

  Color get _badgeBg {
    switch (image.statut) {
      case 'alerte':     return AppColors.red100;
      case 'analysee':   return AppColors.green100;
      case 'en_attente': return AppColors.amber100;
      default:           return const Color(0xFFF5F7F2);
    }
  }

  Color get _badgeColor {
    switch (image.statut) {
      case 'alerte':     return AppColors.red800;
      case 'analysee':   return AppColors.green700;
      case 'en_attente': return AppColors.amber800;
      default:           return AppColors.textMuted;
    }
  }

  String get _badgeLabel {
    switch (image.statut) {
      case 'alerte':     return 'Alerte';
      case 'analysee':   return 'Analysée';
      case 'en_attente': return 'En attente';
      default:           return 'Reçue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(
                  color: AppColors.green100,
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green600, strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Container(
              color: AppColors.green100,
              child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.green600, size: 32))),
        ),
        // Gradient bas
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Badge statut
        Positioned(
          top: 7, right: 7,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _badgeBg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_badgeLabel,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _badgeColor)),
          ),
        ),
        if (image.statut == 'alerte')
          const Positioned(
              top: 7,
              left: 7,
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.red600, size: 18)),
        if (image.statut == 'en_attente')
          const Positioned(
              top: 10,
              left: 10,
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.amber600))),
        // Info bas
        Positioned(
          bottom: 7, left: 8, right: 8,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(image.capteurNom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${image.dateFormatee} · ${image.heureFormatee}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 9),
                ),
              ]),
        ),
      ]),
    );
  }
}*/
// lib/interfaces/images/images_page.dart
// ─────────────────────────────────────────────────────────────────────────────
// Connecté à :
//   GET  /api/capteurs               → liste des capteurs
//   GET  /api/images/:capteur_id     → images du capteur sélectionné
//   POST /api/capturer               → déclenchement capture (polling)
//   GET  /api/ia/statut              → badge disponibilité IA
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/image.dart';
import '../../models/capteur.dart';
import '../../services/image_service.dart';
import '../../services/capteur_service.dart';
import '../../services/ia_service.dart';
import 'details_image_page.dart';
import 'historique_image_page.dart';
import 'analyse_ia_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImagesScreen
// ─────────────────────────────────────────────────────────────────────────────
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  List<CapteurModel> _capteurs     = [];
  CapteurModel?      _capteurSel;
  List<CaptureImage> _images       = [];
  String             _filtre       = 'Toutes';
  bool               _isLoading    = true;
  bool               _isCapturing  = false;
  bool               _iaDisponible = false;

  final List<String> _filtres = ['Toutes', 'Alertes', 'Analysées', 'En attente'];

  // ── Filtrage ───────────────────────────────────────────────────────────────
  List<CaptureImage> get _imgsFiltrees {
    switch (_filtre) {
      case 'Alertes':    return _images.where((i) => i.statut == 'alerte').toList();
      case 'Analysées':  return _images.where((i) => i.statut == 'analysee').toList();
      case 'En attente': return _images.where((i) => i.statut == 'en_attente').toList();
      default:           return _images;
    }
  }

  int get _alertesCount => _images.where((i) => i.statut == 'alerte').length;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // ── Chargement initial ─────────────────────────────────────────────────────
  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final capteurService = context.read<CapteurService>();
      final iaService      = context.read<IaService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        iaService.isDisponible(),
      ]);

      final capteurs     = results[0] as List<CapteurModel>;
      final iaDisponible = results[1] as bool;

      setState(() {
        _capteurs     = capteurs;
        _iaDisponible = iaDisponible;
        if (capteurs.isNotEmpty) _capteurSel = capteurs.first;
      });

      if (_capteurSel != null) await _loadImages(_capteurSel!);
    } catch (e) {
      _showError('Erreur de chargement : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── GET /api/images/:capteur_id ────────────────────────────────────────────
  Future<void> _loadImages(CapteurModel capteur) async {
    setState(() => _isLoading = true);
    try {
      final imageService = context.read<ImageService>();
      // Le tri est déjà fait dans ImageService.getImagesCapteur()
      final images = await imageService.getImagesCapteur(capteur);
      if (mounted) setState(() => _images = images);
    } catch (e) {
      _showError('Impossible de charger les images : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── POST /api/capturer + polling ───────────────────────────────────────────
  Future<void> _prendreImage() async {
    if (_capteurSel == null || _isCapturing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Déclencher une capture',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        content: Text(
          'Demander une photo à ${_capteurSel!.nom} maintenant ?',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Capturer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isCapturing = true);
    try {
      // TODO: POST /api/capturer + polling GET /api/capturer/:job_id
      // Voir ApiConfig.capturer et ApiConfig.capturerStatut(jobId)
      await Future.delayed(const Duration(seconds: 3));
      await _loadImages(_capteurSel!);
      _showSuccess('Capture déclenchée sur ${_capteurSel!.nom}');
    } catch (e) {
      _showError('Erreur capture : $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.green700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
        ),
      );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.red600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Images & capteurs'),
            Text('Analyse visuelle du champ',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // Badge statut IA
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: _iaDisponible ? 'IA en ligne' : 'IA hors ligne',
              child: Icon(
                Icons.psychology_outlined,
                color: _iaDisponible
                    ? AppColors.green600
                    : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
          // Bouton IA + badge alertes
          if (_alertesCount > 0)
            Stack(children: [
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AnalyseIaScreen())),
                icon: const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.green700),
              ),
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.red600, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$_alertesCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          // Rafraîchir
          IconButton(
            onPressed: _capteurSel == null
                ? null
                : () => _loadImages(_capteurSel!),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.refresh,
                  color: AppColors.green700, size: 17),
            ),
          ),
          // Historique
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistoriqueImagesScreen(images: _images)),
            ),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.history,
                  color: AppColors.green700, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _capteurs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _capteurSel != null
                  ? _loadImages(_capteurSel!)
                  : _loadInitial(),
              color: AppColors.green600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Sélecteur capteurs ─────────────────────────────
                    if (_capteurs.isNotEmpty)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capteurs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 7),
                          itemBuilder: (_, i) {
                            final c     = _capteurs[i];
                            final sel   = _capteurSel?.id == c.id;
                            final actif = c.etat == 'actif';
                            return GestureDetector(
                              onTap: () {
                                setState(() => _capteurSel = c);
                                _loadImages(c);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? (actif
                                          ? AppColors.green100
                                          : AppColors.amber100)
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? (actif
                                            ? AppColors.green600
                                            : AppColors.amber600)
                                        : AppColors.border,
                                    width: sel ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(children: [
                                  Text(
                                    c.nom,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: sel
                                          ? (actif
                                              ? AppColors.green700
                                              : AppColors.amber800)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (!actif) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                          color: AppColors.amber600,
                                          shape: BoxShape.circle),
                                    ),
                                  ],
                                ]),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),

                    // ── Carte capteur sélectionné ──────────────────────
                    if (_capteurSel != null)
                      _CapteurInfoCard(
                        capteur:    _capteurSel!,
                        imageCount: _images.length,
                        alerteCount: _alertesCount,
                        isCapturing: _isCapturing,
                        onCapture:  _prendreImage,
                      ),

                    if (_capteurs.isEmpty) _buildEmpty(),

                    const SizedBox(height: 16),

                    // ── Filtres + grille ───────────────────────────────
                    if (_images.isNotEmpty || _isLoading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionLabel('Dernières captures'),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HistoriqueImagesScreen(
                                        images: _images)),
                            ),
                            child: const Text('Voir tout',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.green700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Filtres
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filtres.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 7),
                          itemBuilder: (_, i) {
                            final f   = _filtres[i];
                            final sel = _filtre == f;
                            return GestureDetector(
                              onTap: () => setState(() => _filtre = f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.green100
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.green600
                                          : AppColors.border,
                                      width: sel ? 1.5 : 0.5),
                                ),
                                child: Text(f,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: sel
                                            ? AppColors.green700
                                            : AppColors.textMuted)),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_imgsFiltrees.isEmpty)
                        _buildEmptyFilter()
                      else
                        _buildGrille(),
                    ],

                    const SizedBox(height: 16),

                    // ── Bannière IA ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SectionLabel('Analyse IA'),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AnalyseIaScreen())),
                          child: const Text('Voir tout',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.green700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _IaBannerCard(
                      iaDisponible: _iaDisponible,
                      alertesCount: _alertesCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyseIaScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Grille images ──────────────────────────────────────────────────────────
  Widget _buildGrille() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:    2,
          crossAxisSpacing:  9,
          mainAxisSpacing:   9,
          childAspectRatio:  0.95),
      itemCount: _imgsFiltrees.length,
      itemBuilder: (ctx, i) {
        final img = _imgsFiltrees[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => DetailImageScreen(image: img),
            ),
          ),
          // ✅ img.imageUrl est déjà calculé dans CaptureImage.fromJson()
          // on n'appelle PLUS buildImageUrl() ici
          child: _ImageCard(image: img),
        );
      },
    );
  }

  Widget _buildEmpty() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.amber100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.amber800, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aucun capteur disponible. Ajoutez des capteurs depuis la page Carte.',
              style: TextStyle(fontSize: 12, color: AppColors.amber800),
            ),
          ),
        ]),
      );

  Widget _buildEmptyFilter() => Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Center(
          child: Text(
            'Aucune image pour le filtre "$_filtre".',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CapteurInfoCard
// ─────────────────────────────────────────────────────────────────────────────
class _CapteurInfoCard extends StatelessWidget {
  final CapteurModel capteur;
  final int          imageCount;
  final int          alerteCount;
  final bool         isCapturing;
  final VoidCallback onCapture;

  const _CapteurInfoCard({
    required this.capteur,
    required this.imageCount,
    required this.alerteCount,
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final isActif  = capteur.etat == 'actif';
    final batterie = capteur.batterie ?? 100;
    final batColor = batterie > 40
        ? AppColors.green600
        : batterie > 20
            ? AppColors.amber600
            : AppColors.red600;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(capteur.nom,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
                color: isActif ? AppColors.green100 : AppColors.gray50,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              isActif ? 'Actif' : 'Inactif',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActif
                      ? AppColors.green700
                      : AppColors.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatPill(
              icon: Icons.battery_full,
              color: batColor,
              value: '$batterie%'),
          const SizedBox(width: 8),
          _StatPill(
              icon: Icons.photo_library_outlined,
              color: AppColors.green600,
              value: '$imageCount image${imageCount > 1 ? "s" : ""}'),
          if (alerteCount > 0) ...[
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.warning_amber_outlined,
                color: AppColors.red600,
                value:
                    '$alerteCount alerte${alerteCount > 1 ? "s" : ""}'),
          ],
        ]),
        // ✅ derniereConnexion en camelCase (convention Dart)
        if (capteur.derniereConnexion != null) ...[
          const SizedBox(height: 6),
          Text(
            'Dernière connexion : ${_formatDate(capteur.derniereConnexion!)}',
            style:
                const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isActif && !isCapturing ? onCapture : null,
            icon: isCapturing
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_outlined, size: 15),
            label: Text(isCapturing
                ? 'Capture en cours…'
                : 'Prendre une image maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.green200,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')} à '
          '${d.hour.toString().padLeft(2, '0')}h'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatPill
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   value;
  const _StatPill(
      {required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// _IaBannerCard
// ─────────────────────────────────────────────────────────────────────────────
class _IaBannerCard extends StatelessWidget {
  final bool         iaDisponible;
  final int          alertesCount;
  final VoidCallback onTap;

  const _IaBannerCard({
    required this.iaDisponible,
    required this.alertesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iaDisponible
                    ? AppColors.green100
                    : AppColors.gray50,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.psychology_outlined,
                color: iaDisponible
                    ? AppColors.green600
                    : AppColors.textMuted,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(
                  iaDisponible ? 'IA disponible' : 'IA hors ligne',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text),
                ),
                if (alertesCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.red100,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        '$alertesCount alerte${alertesCount > 1 ? "s" : ""}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.red800)),
                  ),
                ],
              ]),
              Text(
                iaDisponible
                    ? 'Analyser, diagnostiquer, prédire les cultures'
                    : 'Vérifiez la connexion au serveur Flask',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ImageCard — vignette grille
// ─────────────────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final CaptureImage image;
  // ✅ Plus de paramètre imageUrl séparé — on utilise directement image.imageUrl
  const _ImageCard({required this.image});

  Color get _badgeBg {
    switch (image.statut) {
      case 'alerte':     return AppColors.red100;
      case 'analysee':   return AppColors.green100;
      case 'en_attente': return AppColors.amber100;
      default:           return const Color(0xFFF5F7F2);
    }
  }

  Color get _badgeColor {
    switch (image.statut) {
      case 'alerte':     return AppColors.red800;
      case 'analysee':   return AppColors.green700;
      case 'en_attente': return AppColors.amber800;
      default:           return AppColors.textMuted;
    }
  }

  String get _badgeLabel {
    switch (image.statut) {
      case 'alerte':     return 'Alerte';
      case 'analysee':   return 'Analysée';
      case 'en_attente': return 'En attente';
      default:           return 'Reçue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(fit: StackFit.expand, children: [
        // ✅ image.imageUrl est déjà la bonne URL construite par fromJson()
        Image.network(
          image.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(
                  color: AppColors.green100,
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green600, strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Container(
              color: AppColors.green100,
              child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.green600, size: 32))),
        ),

        // Gradient bas
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Badge statut
        Positioned(
          top: 7, right: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _badgeBg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_badgeLabel,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _badgeColor)),
          ),
        ),

        // Icône alerte
        if (image.statut == 'alerte')
          const Positioned(
              top: 7, left: 7,
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.red600, size: 18)),

        // Spinner en attente
        if (image.statut == 'en_attente')
          const Positioned(
              top: 10, left: 10,
              child: SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.amber600))),

        // Info bas
        Positioned(
          bottom: 7, left: 8, right: 8,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(image.capteurNom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${image.dateFormatee} · ${image.heureFormatee}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 9),
                ),
              ]),
        ),
      ]),
    );
  }
}