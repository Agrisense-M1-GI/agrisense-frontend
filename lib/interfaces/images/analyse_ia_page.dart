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
      // FIX: resizeToAvoidBottomInset = true pour que le clavier
      // repousse correctement la barre de saisie vers le haut
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Analyse IA'),
            Text('Détections & assistant agricole',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.green700,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.green600,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Alertes'),
            Tab(text: 'Résumé'),
            Tab(text: 'Assistant'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AlertesTab(),
          _ResumeTab(),
          // FIX: on enveloppe dans SafeArea pour gérer
          // la barre de navigation système en bas
          const SafeArea(
            top: false,
            child: _AssistantTab(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET ASSISTANT — Chat contextuel agricole
// ══════════════════════════════════════════════════════════════════════════════
class _AssistantTab extends StatefulWidget {
  const _AssistantTab();

  @override
  State<_AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<_AssistantTab> {
  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();
  final List<_ChatMessage>    _messages   = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    'Que faire contre le jaunissement ?',
    'Comment traiter la sécheresse foliaire ?',
    'Quand irriguer en phase de croissance ?',
    'Expliquer les résultats Zone B',
    'Quels engrais pour carence en azote ?',
  ];

  final Map<String, String> _reponses = {
    'jauni':
        'Le **jaunissement des feuilles** peut indiquer :\n\n'
        '• **Carence en azote** : les feuilles jaunissent des plus vieilles '
        'vers les nouvelles. Apport foliaire d\'urée (2%) recommandé sous 48h.\n\n'
        '• **Stress hydrique** : vérifiez l\'humidité. Si < 60%, irriguer immédiatement.\n\n'
        '• **Maladie fongique** : si des taches brunes accompagnent le jaunissement, '
        'consultez un agronome.\n\n'
        'D\'après la Zone B, une carence azotée est la cause probable (confiance 84%).',

    'sécheresse':
        'La **sécheresse foliaire** détectée sur C4 (Zone B) nécessite :\n\n'
        '1. Une irrigation immédiate de 60–80L sur la Zone B\n'
        '2. Un paillage autour des plants pour retenir l\'humidité\n'
        '3. Vérification de la bonne orientation des buses\n\n'
        'L\'IA recommande d\'augmenter la fréquence à 2× par jour '
        'jusqu\'à ce que le taux dépasse 65%.',

    'irriguer':
        'Pour le **maïs en phase de croissance** :\n\n'
        '• **Besoin journalier** : 5–7 mm/jour (50–70L/m²)\n'
        '• **Fréquence** : toutes les 48–72h selon la météo\n'
        '• **Heure idéale** : tôt le matin (5h–8h)\n'
        '• **Seuil critique** : irriguer dès que l\'humidité descend sous 60%\n\n'
        'Votre système est configuré à 60% — c\'est optimal.',

    'zone b':
        'Analyse complète de la **Zone B** :\n\n'
        '• 🔴 **Humidité** : 48% — critique, sous le seuil de 60%\n'
        '• ⚠️ **Anomalie** : jaunissement partiel (confiance 84%)\n'
        '• 🔋 **Capteur C3** : batterie à 18% — à recharger\n\n'
        '**Actions recommandées :**\n'
        '1. Lancer une irrigation manuelle maintenant\n'
        '2. Apport foliaire en azote sous 48h\n'
        '3. Recharger la batterie du capteur C3\n\n'
        'Score de santé : **38/100** — situation critique.',

    'azote':
        'Pour corriger une **carence en azote** sur maïs :\n\n'
        '• **Rapide** : pulvérisation foliaire d\'urée à 2% (20g/L)\n'
        '• **Racinaire** : apport NPK 20-10-10 à 150 kg/ha\n'
        '• **Délai** : 5–7 jours pour les premiers effets\n\n'
        '⚠️ Max 2 applications foliaires par semaine.\n\n'
        'Consultez votre agronome pour adapter les doses.',

    'default':
        'Je suis l\'assistant IA d\'AgriSense, spécialisé dans vos cultures.\n\n'
        'Je peux vous aider sur :\n'
        '• L\'interprétation des images et alertes\n'
        '• Les traitements et apports nutritifs\n'
        '• La gestion de l\'irrigation\n'
        '• Le suivi par zone et capteur\n\n'
        'Posez-moi une question sur votre champ !',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      texte: 'Bonjour 👋 Je suis votre assistant IA AgriSense.\n\n'
          'J\'ai analysé vos dernières captures. '
          '**2 alertes** sont actives, notamment un jaunissement en Zone B. '
          'Comment puis-je vous aider ?',
      isIA:  true,
      heure: _heure(),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _heure() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}h'
        '${n.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(
          _ChatMessage(texte: texte.trim(), isIA: false, heure: _heure()));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
          texte: _repondre(texte.toLowerCase()),
          isIA:  true,
          heure: _heure()));
    });
    _scrollToBottom();
  }

  String _repondre(String q) {
    if (q.contains('jauni') || q.contains('jaune'))
      return _reponses['jauni']!;
    if (q.contains('sécheresse') || q.contains('secheresse') ||
        q.contains('foli'))
      return _reponses['sécheresse']!;
    if (q.contains('irrig') || q.contains('eau') || q.contains('arros'))
      return _reponses['irriguer']!;
    if (q.contains('zone b') || q.contains('résultat'))
      return _reponses['zone b']!;
    if (q.contains('azote') || q.contains('engrais') ||
        q.contains('carence'))
      return _reponses['azote']!;
    return _reponses['default']!;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: on récupère le padding bas du système (barre de navigation)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(children: [

      // ── Liste messages ─────────────────────────────────────────────
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          // FIX: padding bottom genereux pour que le dernier message
          // ne soit pas caché derrière la barre de saisie
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (_isTyping && i == _messages.length) {
              return const _TypingIndicator();
            }
            return _BubbleMessage(message: _messages[i]);
          },
        ),
      ),

      // ── Suggestions rapides (visibles au départ) ───────────────────
      if (_messages.length <= 2)
        Container(
          color: AppColors.bg,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Questions fréquentes',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _envoyer(_suggestions[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: Text(_suggestions[i],
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.text)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      // ── Barre de saisie ────────────────────────────────────────────
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border:
              Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        // FIX: on ajoute le bottomPadding système pour remonter
        // la barre au-dessus de la barre de navigation Android
        padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomPadding),
        child: Row(children: [

          // Bouton pièce jointe (futur)
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.attach_file_rounded,
                color: AppColors.green600, size: 18),
          ),

          const SizedBox(width: 8),

          // Champ de saisie
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(children: [
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    // FIX: maxLines null pour expansion verticale
                    // mais on limite avec minLines/maxLines
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _envoyer,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'Posez une question...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ]),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton envoyer
          GestureDetector(
            onTap: () => _envoyer(_inputCtrl.text),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.green600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green600.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Modèle message ────────────────────────────────────────────────────────────
class _ChatMessage {
  final String texte;
  final bool   isIA;
  final String heure;
  const _ChatMessage(
      {required this.texte, required this.isIA, required this.heure});
}

// ── Bulle de message ──────────────────────────────────────────────────────────
class _BubbleMessage extends StatelessWidget {
  final _ChatMessage message;
  const _BubbleMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final isIA = message.isIA;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isIA ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // Avatar IA
          if (isIA) ...[
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                  color: AppColors.green600, shape: BoxShape.circle),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          // Bulle
          Flexible(
            child: Column(
              crossAxisAlignment: isIA
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color:
                        isIA ? AppColors.white : AppColors.green600,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isIA ? 4 : 16),
                      bottomRight: Radius.circular(isIA ? 16 : 4),
                    ),
                    border: isIA
                        ? Border.all(
                            color: AppColors.border, width: 0.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      _TexteFormate(texte: message.texte, isIA: isIA),
                ),
                const SizedBox(height: 4),
                Text(message.heure,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),

          if (!isIA) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Texte formaté avec support **gras** ───────────────────────────────────────
class _TexteFormate extends StatelessWidget {
  final String texte;
  final bool   isIA;
  const _TexteFormate({required this.texte, required this.isIA});

  @override
  Widget build(BuildContext context) {
    final color = isIA ? AppColors.text : Colors.white;
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final m in regex.allMatches(texte)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: texte.substring(last, m.start),
            style:
                TextStyle(fontSize: 13, color: color, height: 1.5)));
      }
      spans.add(TextSpan(
          text: m.group(1),
          style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.5)));
      last = m.end;
    }
    if (last < texte.length) {
      spans.add(TextSpan(
          text: texte.substring(last),
          style:
              TextStyle(fontSize: 13, color: color, height: 1.5)));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ── Indicateur "IA écrit..." animé ───────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500));
      final a = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut));
      _ctrls.add(c);
      _anims.add(a);
      Future.delayed(Duration(milliseconds: i * 160),
          () { if (mounted) c.repeat(reverse: true); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          decoration: const BoxDecoration(
              color: AppColors.green600, shape: BoxShape.circle),
          child: const Icon(Icons.psychology_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(16),
              topRight:    Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft:  Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => AnimatedBuilder(
                animation: _anims[i],
                builder: (_, __) => Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.green200,
                        AppColors.green600, _anims[i].value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET ALERTES
// ══════════════════════════════════════════════════════════════════════════════
class _AlertesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alertes =
        mockImages.where((i) => i.statut == 'alerte').toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Bandeau résumé
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.red600.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: AppColors.red600.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.red600, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${alertes.length} alertes actives',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red800)),
                const Text('Action recommandée dans les 24h',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.red800)),
              ],
            ),
          ]),
        ),

        const SizedBox(height: 16),
        const _SectionH('ANOMALIES DÉTECTÉES'),
        const SizedBox(height: 10),

        ...alertes.map((img) => GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailImageScreen(image: img))),
              child: _AlerteCard(image: img),
            )),

        const SizedBox(height: 16),
        const _SectionH('RECOMMANDATIONS PRIORITAIRES'),
        const SizedBox(height: 10),

        _PrioCard(
          numero: '1', numBg: AppColors.red600,
          titre: 'Apport en azote — Zone B',
          detail: 'Jaunissement confirmé par 2 captures. '
              'Apport foliaire recommandé sous 48h.',
          icone: Icons.eco_outlined,
          prioriteLabel: 'Urgent',
          prioriteBg: AppColors.red100,
          prioriteColor: AppColors.red800,
        ),
        const SizedBox(height: 8),
        _PrioCard(
          numero: '2', numBg: AppColors.amber600,
          titre: 'Irrigation ciblée — Zone B (C4)',
          detail: 'Sécheresse foliaire visible. '
              'Déclencher irrigation manuelle dans les 24h.',
          icone: Icons.water_drop_outlined,
          prioriteLabel: 'Moyen',
          prioriteBg: AppColors.amber100,
          prioriteColor: AppColors.amber800,
        ),
        const SizedBox(height: 8),
        _PrioCard(
          numero: '3', numBg: AppColors.green600,
          titre: 'Inspection terrain — Zone B',
          detail: 'Vérification manuelle des racines recommandée.',
          icone: Icons.search_outlined,
          prioriteLabel: 'Faible',
          prioriteBg: AppColors.green100,
          prioriteColor: AppColors.green700,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET RÉSUMÉ
// ══════════════════════════════════════════════════════════════════════════════
class _ResumeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total     = mockImages.length;
    final alertes   = mockImages.where((i) => i.statut == 'alerte').length;
    final analysees = mockImages.where((i) => i.statut == 'analysee').length;
    final normales  = mockImages.where((i) => i.statut == 'normale').length;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _SectionH('STATISTIQUES — 7 DERNIERS JOURS'),
        const SizedBox(height: 10),
        Row(children: [
          _StatBox(valeur: '$total',     label: 'Captures',
              bg: AppColors.green100, color: AppColors.green700),
          const SizedBox(width: 9),
          _StatBox(valeur: '$alertes',   label: 'Alertes',
              bg: AppColors.red100,   color: AppColors.red800),
          const SizedBox(width: 9),
          _StatBox(valeur: '$analysees', label: 'Analysées',
              bg: AppColors.green100, color: AppColors.green700),
          const SizedBox(width: 9),
          _StatBox(valeur: '$normales',  label: 'Normales',
              bg: AppColors.gray50,   color: AppColors.textMuted),
        ]),

        const SizedBox(height: 16),
        const _SectionH('SANTÉ PAR ZONE'),
        const SizedBox(height: 10),
        _ZoneSanteCard(zone:'Zone A', score:92, statut:'Excellente',
            couleur:AppColors.green600,
            detail:'Végétation dense et homogène. Aucune anomalie.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone:'Zone B', score:38, statut:'Critique',
            couleur:AppColors.red600,
            detail:'Jaunissement + sécheresse foliaire. Action requise.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone:'Zone C', score:85, statut:'Bonne',
            couleur:AppColors.green600,
            detail:'Irrégularités mineures. Surveillance continue.'),
        const SizedBox(height: 8),
        _ZoneSanteCard(zone:'Zone D', score:60, statut:'Modérée',
            couleur:AppColors.amber600,
            detail:'Capteur C7 batterie faible. Données partielles.'),

        const SizedBox(height: 16),
        const _SectionH('MODÈLE IA — PERFORMANCE'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: Column(children: [
            _IaMetric(label:'Précision détection anomalies',
                value:'87%', bar:0.87, color:AppColors.green600),
            const SizedBox(height: 12),
            _IaMetric(label:'Confiance moyenne des analyses',
                value:'84%', bar:0.84, color:AppColors.green600),
            const SizedBox(height: 12),
            _IaMetric(label:'Images analysées (7j)',
                value:'6/8', bar:0.75, color:AppColors.amber600),
            const SizedBox(height: 12),
            _IaMetric(label:'Taux de faux positifs',
                value:'< 5%', bar:0.05, color:AppColors.green600),
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
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: CustomPaint(
              painter: _TendancePainter(),
              child: const SizedBox.expand()),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Lun','Mar','Mer','Jeu','Ven','Sam','Auj']
              .map((d) => Text(d,
                  style: TextStyle(
                      fontSize: 9,
                      color: d == 'Auj'
                          ? AppColors.green700
                          : AppColors.textMuted,
                      fontWeight: d == 'Auj'
                          ? FontWeight.w500
                          : FontWeight.normal)))
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.8));
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
        border: Border.all(
            color: AppColors.red600.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        // FIX: ClipRRect avec height fixe pour éviter l'overflow
        ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              bottomLeft: Radius.circular(13)),
          child: SizedBox(
            width: 80, height: 88,
            child: Image.network(
              image.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.red100,
                child: const Center(child: Icon(Icons.grass,
                    color: AppColors.red600, size: 28)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${image.capteurId} — ${image.zone}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.red100,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Alerte',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppColors.red800)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  image.anomalie ?? 'Anomalie détectée',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.red800,
                      fontWeight: FontWeight.w500),
                  // FIX: limiter à 2 lignes pour éviter overflow
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('${image.date} · ${image.heure}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                if (image.confiance > 0) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.psychology_outlined,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('Confiance ${image.confiance}%',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted)),
                  ]),
                ],
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 16),
        ),
      ]),
    );
  }
}

class _PrioCard extends StatelessWidget {
  final String  numero, titre, detail, prioriteLabel;
  final Color   numBg, prioriteBg, prioriteColor;
  final IconData icone;
  const _PrioCard({
    required this.numero,   required this.numBg,
    required this.titre,    required this.detail,
    required this.icone,    required this.prioriteLabel,
    required this.prioriteBg, required this.prioriteColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration:
            BoxDecoration(color: numBg, shape: BoxShape.circle),
        child: Center(
          child: Text(numero,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(titre,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: prioriteBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(prioriteLabel,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: prioriteColor)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(detail,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4)),
          ],
        ),
      ),
    ]),
  );
}

class _StatBox extends StatelessWidget {
  final String valeur, label;
  final Color  bg, color;
  const _StatBox({required this.valeur, required this.label,
      required this.bg, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(valeur,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
      ]),
    ),
  );
}

class _ZoneSanteCard extends StatelessWidget {
  final String zone, statut, detail;
  final int    score;
  final Color  couleur;
  const _ZoneSanteCard({
    required this.zone,   required this.score,
    required this.statut, required this.couleur,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(zone,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text)),
        Row(children: [
          Text('$score/100',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: couleur)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(statut,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: couleur)),
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
      Text(detail,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4)),
    ]),
  );
}

class _IaMetric extends StatelessWidget {
  final String label, value;
  final double bar;
  final Color  color;
  const _IaMetric({required this.label, required this.value,
      required this.bar, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
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
      ]),
    ),
  ]);
}

// ── Graphique tendance humidité ───────────────────────────────────────────────
class _TendancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8EDE4)
      ..strokeWidth = 0.5;
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, y * size.height),
          Offset(size.width, y * size.height), grid);
    }
    _ligne(canvas, size,
        [0.38, 0.32, 0.28, 0.42, 0.25, 0.30, 0.27], AppColors.green600);
    _ligne(canvas, size,
        [0.70, 0.72, 0.68, 0.65, 0.60, 0.55, 0.52], AppColors.red600);
    _legendDot(canvas, AppColors.green600, 'Zone A/C', 0);
    _legendDot(canvas, AppColors.red600,   'Zone B',   70);
  }

  void _ligne(Canvas canvas, Size size, List<double> pts, Color color) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.12), color.withOpacity(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final offs = pts.asMap().entries
        .map((e) => Offset(
            e.key * size.width / (pts.length - 1),
            e.value * size.height))
        .toList();
    final fp = Path()..moveTo(offs.first.dx, offs.first.dy);
    for (final o in offs.skip(1)) fp.lineTo(o.dx, o.dy);
    fp..lineTo(offs.last.dx, size.height)
      ..lineTo(offs.first.dx, size.height)
      ..close();
    canvas.drawPath(fp, fill);
    final lp = Path()..moveTo(offs.first.dx, offs.first.dy);
    for (final o in offs.skip(1)) lp.lineTo(o.dx, o.dy);
    canvas.drawPath(lp, stroke);
    canvas.drawCircle(offs.last, 3.5,
        Paint()..color = color..style = PaintingStyle.fill);
  }

  void _legendDot(
      Canvas canvas, Color color, String label, double x) {
    canvas.drawCircle(Offset(x + 6, 8), 4,
        Paint()..color = color..style = PaintingStyle.fill);
    (TextPainter(
      text: TextSpan(
          text: '  $label',
          style: TextStyle(color: color, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(x + 8, 2));
  }

  @override
  bool shouldRepaint(_) => false;
}