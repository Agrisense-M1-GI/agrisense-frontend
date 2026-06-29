import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/image.dart';
import 'analyse_ia_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DetailImageScreen
//
// statut 'alerte'   → bloc anomalie rouge + recommandations
// statut 'analysee' → analyse IA verte
// statut 'normale'  → image reçue, en attente d'analyse IA (est_traitee == false)
//
// Quand le backend IA sera prêt : ajouter les champs anomalie, confiance,
// statut_ia dans CaptureImage et ils s'afficheront automatiquement ici.
// ─────────────────────────────────────────────────────────────────────────────
class DetailImageScreen extends StatelessWidget {
  final CaptureImage image;
  const DetailImageScreen({super.key, required this.image});

  bool get isAlerte   => image.statut == 'alerte';
  bool get isAnalysee => image.statut == 'analysee';
  bool get isNormale  => image.statut == 'normale';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: const _ActionBtn(icon: Icons.share_outlined)),
          IconButton(onPressed: () {}, icon: const _ActionBtn(icon: Icons.download_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Grande image ─────────────────────────────────────────────
          _buildHero(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Alerte critique ──────────────────────────────────────
              if (isAlerte) ...[
                _buildAlerteBloc(),
                const SizedBox(height: 14),
              ],

              // ── En attente d'analyse IA ──────────────────────────────
              if (isNormale) ...[
                _buildEnAttenteBloc(),
                const SizedBox(height: 14),
              ],

              // ── Informations de la capture ───────────────────────────
              const SectionLabel('Informations de la capture'),
              AppCard(child: Column(children: [
                _InfoRow(label: 'Identifiant',  value: image.id),
                _InfoRow(label: 'Capteur',      value: image.capteurId),
                _InfoRow(label: 'Zone',         value: image.zone.isNotEmpty ? image.zone : '—'),
                _InfoRow(label: 'Date & heure', value: '${image.date} à ${image.heure}'),
                _InfoRow(label: 'Statut',       value: _labelStatut(image.statut)),
                if (image.confiance > 0)
                  _InfoRow(label: 'Confiance IA', value: '${image.confiance}%'),
                const _InfoRow(label: 'Résolution', value: '1920 × 1080 px', isLast: true),
              ])),

              const SizedBox(height: 14),

              // ── Analyse IA ────────────────────────────────────────────
              if (isAlerte || isAnalysee) ...[
                const SectionLabel('Analyse IA'),
                _buildAnalyseBloc(),
                const SizedBox(height: 8),
                if (image.confiance > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.psychology_outlined, color: AppColors.green700, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Indice de confiance IA',
                            style: TextStyle(fontSize: 12, color: AppColors.text))),
                        Text('${image.confiance}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                                color: AppColors.green700)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: image.confiance / 100,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFE8EDE4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            image.confiance >= 80 ? AppColors.green600
                                : image.confiance >= 60 ? AppColors.amber600
                                : AppColors.red600,
                          ),
                        ),
                      ),
                    ]),
                  ),
                const SizedBox(height: 14),
              ],

              // ── Comparaison avant/après ───────────────────────────────
              if (isAlerte) ...[
                const SectionLabel('Comparaison avant / après'),
                _buildComparaison(),
                const SizedBox(height: 14),
              ],

              // ── Recommandations ───────────────────────────────────────
              const SectionLabel('Recommandations'),
              _buildRecommandations(),
              const SizedBox(height: 16),

              // ── Actions ───────────────────────────────────────────────
              _buildActions(context),
              const SizedBox(height: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 300, width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          image.imageUrl, fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null ? child
              : Container(color: AppColors.green100,
                  child: const Center(child: CircularProgressIndicator(
                      color: AppColors.green600, strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF3B6D11), Color(0xFF8AB855)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            )),
            child: const Center(child: Icon(Icons.grass, color: Colors.white54, size: 64)),
          ),
        ),
        // Gradient bas
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(height: 110,
            decoration: BoxDecoration(gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            )),
          ),
        ),
        // Badge alerte
        if (isAlerte)
          Positioned(bottom: 68, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.red600.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.warning_amber, color: Colors.white, size: 13),
                SizedBox(width: 5),
                Text('Anomalie détectée',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        // Badge en attente
        if (isNormale)
          Positioned(bottom: 68, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.amber600.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.hourglass_top_outlined, color: Colors.white, size: 13),
                SizedBox(width: 5),
                Text('En attente d\'analyse IA',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        // Infos bas
        Positioned(bottom: 16, left: 16, right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  image.zone.isNotEmpty
                      ? '${image.capteurId} — ${image.zone}'
                      : image.capteurId,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text('${image.date} · ${image.heure}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              _StatusBadge(statut: image.statut),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Bloc alerte ────────────────────────────────────────────────────────────
  Widget _buildAlerteBloc() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.red600.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.red600, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            image.anomalie ?? 'Anomalie détectée',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.red800),
          ),
          const SizedBox(height: 3),
          const Text(
            'Une vérification terrain est recommandée dans les 24h. '
            'Vérifier l\'apport en nutriments et l\'état des racines.',
            style: TextStyle(fontSize: 11, color: AppColors.red800, height: 1.4),
          ),
        ])),
      ]),
    );
  }

  // ── Bloc en attente ────────────────────────────────────────────────────────
  Widget _buildEnAttenteBloc() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.amber100.withOpacity(0.6),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome_outlined, color: AppColors.amber600, size: 20),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Image reçue — analyse IA en attente',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.amber800)),
          SizedBox(height: 3),
          Text(
            'Cette image n\'a pas encore été analysée par le modèle IA. '
            'Le résultat apparaîtra automatiquement dès que le traitement sera terminé.',
            style: TextStyle(fontSize: 11, color: AppColors.amber800, height: 1.4),
          ),
        ])),
      ]),
    );
  }

  // ── Analyse IA ─────────────────────────────────────────────────────────────
  Widget _buildAnalyseBloc() {
    return Container(
      decoration: BoxDecoration(
        color: isAlerte
            ? AppColors.red100.withOpacity(0.45)
            : AppColors.green100.withOpacity(0.45),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isAlerte
              ? AppColors.red600.withOpacity(0.2)
              : AppColors.green600.withOpacity(0.2),
        ),
      ),
      child: Column(children: [
        _AnalyseRow(
          titre:  isAlerte ? (image.anomalie ?? 'Anomalie détectée') : 'Végétation saine',
          detail: isAlerte
              ? 'Coloration anormale détectée sur 20–30% de la surface visible.'
              : 'Densité foliaire et couleur conformes au stade de croissance.',
          icon:  isAlerte ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: isAlerte ? AppColors.red600 : AppColors.green700,
        ),
        Divider(height: 0.5, thickness: 0.5,
            color: isAlerte
                ? AppColors.red600.withOpacity(0.15)
                : AppColors.green600.withOpacity(0.15),
            indent: 14),
        _AnalyseRow(
          titre:  'Humidité foliaire',
          detail: 'Niveau : ${isAlerte ? "critique (< 40%)" : "normal (65–80%)"}.',
          icon:   Icons.water_drop_outlined,
          color:  isAlerte ? AppColors.amber600 : AppColors.green600,
        ),
        Divider(height: 0.5, thickness: 0.5,
            color: isAlerte
                ? AppColors.red600.withOpacity(0.15)
                : AppColors.green600.withOpacity(0.15),
            indent: 14),
        _AnalyseRow(
          titre:  'Densité végétale',
          detail: isAlerte
              ? 'Faible clairsemement observé en bas de la zone.'
              : 'Couverture végétale dense et homogène.',
          icon:   Icons.grass,
          color:  AppColors.green600,
          isLast: true,
        ),
      ]),
    );
  }

  // ── Comparaison avant/après ────────────────────────────────────────────────
  Widget _buildComparaison() {
    return Column(children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Avant', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(height: 100,
              child: Image.network(
                'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=400&q=70',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.green100,
                    child: const Center(child: Icon(Icons.grass, color: AppColors.green600, size: 32))),
              ),
            ),
          ),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Après — Anomalie',
              style: TextStyle(fontSize: 11, color: AppColors.red800)),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(height: 100,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(image.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.red100)),
                Container(color: Colors.red.withOpacity(0.12)),
              ]),
            ),
          ),
        ])),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.amber100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.amber600.withOpacity(0.3)),
        ),
        child: const Text(
          'Changement notable entre les deux captures : '
          'coloration et densité végétale dégradées sur la zone basse.',
          style: TextStyle(fontSize: 11, color: AppColors.amber800, height: 1.4),
        ),
      ),
    ]);
  }

  // ── Recommandations ────────────────────────────────────────────────────────
  Widget _buildRecommandations() {
    if (isAlerte) {
      return Column(children: [
        _RecoItem(
          priorite: 'Élevée', prioriteBg: AppColors.red100, prioriteColor: AppColors.red800,
          titre: image.anomalie != null
              ? 'Traiter : ${image.anomalie}'
              : 'Vérifier l\'apport en azote',
          detail: 'Le jaunissement ou l\'anomalie peut indiquer une carence. '
              'Apport foliaire recommandé sous 48h.',
        ),
        const SizedBox(height: 8),
        _RecoItem(
          priorite: 'Moyenne', prioriteBg: AppColors.amber100, prioriteColor: AppColors.amber800,
          titre: 'Inspecter les racines manuellement',
          detail: 'Sondage recommandé pour écarter une atteinte fongique au niveau du sol.',
        ),
        const SizedBox(height: 8),
        _RecoItem(
          priorite: 'Faible', prioriteBg: AppColors.green100, prioriteColor: AppColors.green700,
          titre: 'Augmenter la fréquence de capture',
          detail: 'Activer des prises toutes les 2h sur ${image.capteurId} pour surveiller l\'évolution.',
        ),
      ]);
    } else if (isAnalysee) {
      return _RecoItem(
        priorite: 'OK', prioriteBg: AppColors.green100, prioriteColor: AppColors.green700,
        titre: 'Maintenir le rythme actuel',
        detail: 'La végétation est en bonne santé. Continuer selon le programme défini.',
      );
    } else {
      return _RecoItem(
        priorite: 'Info', prioriteBg: AppColors.amber100, prioriteColor: AppColors.amber800,
        titre: 'Analyse IA en cours',
        detail: 'Les recommandations seront disponibles après le traitement par le modèle IA.',
      );
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Column(children: [
      if (isAlerte) ...[
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            /*onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalyseIaScreen())),*/
                // Remplacer l'onPressed du bouton "Voir l'analyse complète IA"
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AnalyseIaScreen(imageContexte: image),
  ),
),
            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
            label: const Text('Voir l\'analyse complète IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600, foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            
          ),
          
        ),
        const SizedBox(height: 8),
      ],
      SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Retour'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green700,
            side: const BorderSide(color: AppColors.green600, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    ]);
  }

  String _labelStatut(String s) {
    switch (s) {
      case 'alerte':   return 'Alerte détectée';
      case 'analysee': return 'Analysée';
      default:         return 'En attente d\'analyse';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  const _ActionBtn({super.key, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(9)),
    child: Icon(icon, color: Colors.white, size: 17),
  );
}

class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({super.key, required this.statut});
  @override
  Widget build(BuildContext context) {
    final color = statut == 'alerte'
        ? AppColors.red600
        : statut == 'analysee'
            ? AppColors.green600
            : AppColors.amber600;
    final bg = statut == 'alerte'
        ? AppColors.red100
        : statut == 'analysee'
            ? AppColors.green100
            : AppColors.amber100;
    final label = statut == 'alerte'
        ? 'Alerte'
        : statut == 'analysee'
            ? 'Analysée'
            : 'En attente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg.withOpacity(0.92), borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow({super.key, required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    decoration: BoxDecoration(
      border: isLast ? null : const Border(
          bottom: BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      Flexible(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text),
          textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _AnalyseRow extends StatelessWidget {
  final String titre, detail;
  final IconData icon;
  final Color color;
  final bool isLast;
  const _AnalyseRow({
    super.key,
    required this.titre, required this.detail,
    required this.icon, required this.color, this.isLast = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(13),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
      ])),
    ]),
  );
}

class _RecoItem extends StatelessWidget {
  final String priorite, titre, detail;
  final Color prioriteBg, prioriteColor;
  const _RecoItem({
    super.key,
    required this.priorite, required this.prioriteBg, required this.prioriteColor,
    required this.titre, required this.detail,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(titre,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: prioriteBg, borderRadius: BorderRadius.circular(20)),
          child: Text(priorite,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: prioriteColor)),
        ),
      ]),
      const SizedBox(height: 5),
      Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
    ]),
  );
}