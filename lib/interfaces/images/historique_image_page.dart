import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/image.dart';
import 'details_image_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoriqueImagesScreen
//
// Reçoit la liste d'images depuis ImagesScreen (déjà chargées depuis l'API
// ou depuis les mocks en fallback). Aucun appel réseau ici.
// ─────────────────────────────────────────────────────────────────────────────
class HistoriqueImagesScreen extends StatefulWidget {
  final List<CaptureImage> images;

  const HistoriqueImagesScreen({super.key, required this.images});

  @override
  State<HistoriqueImagesScreen> createState() => _HistoriqueImagesScreenState();
}

class _HistoriqueImagesScreenState extends State<HistoriqueImagesScreen> {
  String _filtreZone   = 'Toutes';
  String _filtreStatut = 'Tous';
  bool   _isGrid       = true;

  final List<String> _statuts = ['Tous','Alertes','Analysées','Normales'];

  // Zones dynamiques extraites des images reçues
  List<String> get _zones {
    final zonesSet = widget.images.map((i) => i.zone).where((z) => z.isNotEmpty).toSet();
    return ['Toutes', ...zonesSet.toList()..sort()];
  }

  List<CaptureImage> get _filtered {
    var imgs = List<CaptureImage>.from(widget.images);
    if (_filtreZone != 'Toutes')
      imgs = imgs.where((i) => i.zone == _filtreZone).toList();
    if (_filtreStatut == 'Alertes')
      imgs = imgs.where((i) => i.statut == 'alerte').toList();
    else if (_filtreStatut == 'Analysées')
      imgs = imgs.where((i) => i.statut == 'analysee').toList();
    else if (_filtreStatut == 'Normales')
      imgs = imgs.where((i) => i.statut == 'normale').toList();
    return imgs;
  }

  // Groupement par date
  Map<String, List<CaptureImage>> get _groupedByDate {
    final Map<String, List<CaptureImage>> grouped = {};
    for (final img in _filtered) {
      grouped.putIfAbsent(img.date, () => []).add(img);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDate;
    final total   = _filtered.length;
    final alertes = _filtered.where((i) => i.statut == 'alerte').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Historique des images'),
          Text('Toutes les captures', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(_isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.green700),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [

        // ── Barre stats rapides ──────────────────────────────────────
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            _StatChip(
              icon: Icons.photo_library_outlined,
              label: '$total capture${total > 1 ? "s" : ""}',
              bg: AppColors.green100, color: AppColors.green700,
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.warning_amber_outlined,
              label: '$alertes alerte${alertes > 1 ? "s" : ""}',
              bg: alertes > 0 ? AppColors.red100 : AppColors.green100,
              color: alertes > 0 ? AppColors.red600 : AppColors.green700,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showFiltreSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green600, width: 0.5),
                ),
                child: const Row(children: [
                  Icon(Icons.filter_list, color: AppColors.green700, size: 14),
                  SizedBox(width: 5),
                  Text('Filtrer', style: TextStyle(fontSize: 11, color: AppColors.green700, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Filtre zone ──────────────────────────────────────────────
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final z   = _zones[i];
                final sel = _filtreZone == z;
                return GestureDetector(
                  onTap: () => setState(() => _filtreZone = z),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.green100 : AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.green600 : AppColors.border,
                          width: sel ? 1.5 : 0.5),
                    ),
                    child: Text(z, style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                      color: sel ? AppColors.green700 : AppColors.textMuted,
                    )),
                  ),
                );
              },
            ),
          ),
        ),

        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),

        // ── Contenu ──────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: grouped.length,
                  itemBuilder: (_, sectionIdx) {
                    final date = grouped.keys.elementAt(sectionIdx);
                    final imgs = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête date
                        Padding(
                          padding: EdgeInsets.only(bottom: 10, top: sectionIdx == 0 ? 0 : 14),
                          child: Row(children: [
                            Text(date.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted, letterSpacing: 0.8)),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 0.5, color: AppColors.border)),
                            const SizedBox(width: 8),
                            Text('${imgs.length} image${imgs.length > 1 ? "s" : ""}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ]),
                        ),

                        // Grille ou liste
                        _isGrid
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3, crossAxisSpacing: 7,
                                    mainAxisSpacing: 7, childAspectRatio: 0.85),
                                itemCount: imgs.length,
                                itemBuilder: (ctx, i) {
                                  final img = imgs[i];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(ctx,
                                        MaterialPageRoute(builder: (_) => DetailImageScreen(image: img))),
                                    child: _GridThumb(image: img),
                                  );
                                },
                              )
                            : Column(
                                children: imgs.map((img) => GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => DetailImageScreen(image: img))),
                                  child: _ListTile(image: img),
                                )).toList(),
                              ),
                      ],
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.photo_library_outlined, color: AppColors.green600, size: 32),
      ),
      const SizedBox(height: 14),
      const Text('Aucune image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
      const SizedBox(height: 6),
      const Text('Aucune capture ne correspond aux filtres sélectionnés.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
    ]),
  );

  void _showFiltreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Filtres',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
            const SizedBox(height: 16),
            const Text('STATUT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: AppColors.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _statuts.map((s) {
              final sel = _filtreStatut == s;
              return GestureDetector(
                onTap: () {
                  setSheetState(() => _filtreStatut = s);
                  setState(() => _filtreStatut = s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.green100 : AppColors.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.green600 : AppColors.border,
                        width: sel ? 1.5 : 0.5),
                  ),
                  child: Text(s, style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                    color: sel ? AppColors.green700 : AppColors.textMuted,
                  )),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600, foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Appliquer',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GridThumb — vignette grille (inchangée)
// ─────────────────────────────────────────────────────────────────────────────
class _GridThumb extends StatelessWidget {
  final CaptureImage image;
  const _GridThumb({required this.image});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(image.imageUrl, fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null ? child
              : Container(color: AppColors.green100,
                  child: const Center(child: CircularProgressIndicator(
                      color: AppColors.green600, strokeWidth: 1.5))),
          errorBuilder: (_, __, ___) => Container(color: AppColors.green100,
              child: const Center(child: Icon(Icons.grass, color: AppColors.green600, size: 28))),
        ),
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(height: 40,
            decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            )),
          ),
        ),
        if (image.statut == 'alerte')
          const Positioned(top: 5, right: 5,
              child: Icon(Icons.warning_amber_rounded, color: AppColors.red600, size: 15)),
        if (image.statut == 'analysee')
          Positioned(top: 5, right: 5,
            child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.green600, shape: BoxShape.circle))),
        Positioned(bottom: 5, left: 6,
          child: Text(image.heure,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ListTile — ligne liste (inchangée)
// ─────────────────────────────────────────────────────────────────────────────
class _ListTile extends StatelessWidget {
  final CaptureImage image;
  const _ListTile({required this.image});

  @override
  Widget build(BuildContext context) {
    final isAlerte   = image.statut == 'alerte';
    final isAnalysee = image.statut == 'analysee';
    final badgeBg    = isAlerte ? AppColors.red100   : isAnalysee ? AppColors.green100 : AppColors.gray50;
    final badgeColor = isAlerte ? AppColors.red800   : isAnalysee ? AppColors.green700 : AppColors.textMuted;
    final badgeLabel = isAlerte ? 'Alerte'           : isAnalysee ? 'Analysée'         : 'Normale';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isAlerte ? AppColors.red600.withOpacity(0.3) : AppColors.border,
            width: 0.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(width: 64, height: 64,
            child: Image.network(image.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.green100,
                  child: const Center(child: Icon(Icons.grass, color: AppColors.green600, size: 24))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(
              image.zone.isNotEmpty
                  ? '${image.capteurId} — ${image.zone}'
                  : image.capteurId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text),
              overflow: TextOverflow.ellipsis,
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(badgeLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: badgeColor)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${image.date} · ${image.heure}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (image.anomalie != null) ...[
            const SizedBox(height: 4),
            Text(image.anomalie!,
                style: const TextStyle(fontSize: 11, color: AppColors.red800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (image.confiance > 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.psychology_outlined, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text('IA · ${image.confiance}%',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ],
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatChip
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, color;
  const _StatChip({required this.icon, required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    ]),
  );
}