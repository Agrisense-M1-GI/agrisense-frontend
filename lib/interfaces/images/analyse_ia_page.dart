import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/image.dart';
import '../../models/champ.dart';
import '../../models/culture.dart';
import '../../services/champ_service.dart';

class AnalyseIaScreen extends StatefulWidget {
  final CaptureImage? imageContexte;
  const AnalyseIaScreen({super.key, this.imageContexte});

  @override
  State<AnalyseIaScreen> createState() => _AnalyseIaScreenState();
}

class _AnalyseIaScreenState extends State<AnalyseIaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ChampModel>   _champs   = [];
  // Map champId → cultures : contourne l'absence de champId dans CultureModel
  Map<String, List<CultureModel>> _culturesParChamp = {};
  bool _contextLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContexte());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadContexte() async {
    try {
      final champService = context.read<ChampService>();
      final champs = await champService.getChamps();

      // Pour chaque champ, charger ses cultures et les stocker par champId
      final Map<String, List<CultureModel>> culturesParChamp = {};
      await Future.wait(
        champs.map((champ) async {
          try {
            final cc = await champService.getCultures(champ.id);
            culturesParChamp[champ.id] = cc;
          } catch (_) {
            culturesParChamp[champ.id] = [];
          }
        }),
      );

      if (mounted) {
        setState(() {
          _champs          = champs;
          _culturesParChamp = culturesParChamp;
          _contextLoaded   = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _contextLoaded = true);
    }
  }

  /// Liste à plat de toutes les cultures (utile pour le payload IA)
  List<CultureModel> get _toutesLesCultures =>
      _culturesParChamp.values.expand((c) => c).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Analyse IA'),
            Text('Assistant agricole intelligent',
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
            Tab(text: 'Assistant'),
            Tab(text: 'Historique'),
            Tab(text: 'Alertes'),
          ],
        ),
      ),
      body: _contextLoaded
          ? TabBarView(
              controller: _tabs,
              children: [
                SafeArea(
                  top: false,
                  child: _AssistantTab(
                    imageContexte:    widget.imageContexte,
                    champs:           _champs,
                    culturesParChamp: _culturesParChamp,
                    toutesLesCultures: _toutesLesCultures,
                  ),
                ),
                _HistoriqueTab(
                  champs:           _champs,
                  culturesParChamp: _culturesParChamp,
                ),
                _AlertesTab(champs: _champs),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ASSISTANT TAB
// ══════════════════════════════════════════════════════════════════════════════
class _AssistantTab extends StatefulWidget {
  final CaptureImage?                     imageContexte;
  final List<ChampModel>                  champs;
  final Map<String, List<CultureModel>>   culturesParChamp;
  final List<CultureModel>                toutesLesCultures;

  const _AssistantTab({
    this.imageContexte,
    required this.champs,
    required this.culturesParChamp,
    required this.toutesLesCultures,
  });

  @override
  State<_AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<_AssistantTab> {
  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();
  final List<_ChatMessage>    _messages   = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    'État général de mes cultures ?',
    'Pourquoi les feuilles jaunissent ?',
    'Conseils irrigation',
    'Maladies fréquentes du maïs',
    'Que faire pour cette alerte ?',
  ];

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Initialisation du chat ─────────────────────────────────────────────────
  void _initMessages() {
    // Message de bienvenue avec contexte champ/cultures
    _messages.add(_ChatMessage(
      texte: 'Bonjour 👋\n\nJe suis votre assistant IA agricole.'
          '${_construireContexteIA()}'
          '\n\nPosez votre question sur vos cultures ou sur une capture.',
      isIA:  true,
      heure: _heure(),
    ));

    // Si une image est passée en contexte
    if (widget.imageContexte != null) {
      final img = widget.imageContexte!;
      _messages.add(_ChatMessage(
        texte: '📷 Image envoyée : ${img.capteurNom}'
            '${img.zone.isNotEmpty ? " — ${img.zone}" : ""}\n'
            '${img.date} · ${img.heure}\n'
            'Statut : ${_labelStatut(img.statut)}'
            '${img.anomalie != null ? "\nAnomalie : ${img.anomalie}" : ""}',
        isIA:            false,
        heure:           _heure(),
        isImageContexte: true,
        imageUrl:        img.imageUrl,
      ));

      _messages.add(_ChatMessage(
        texte: _reponseAutoImage(img),
        isIA:  true,
        heure: _heure(),
      ));
    }
  }

  // ── Contexte textuel envoyé à l'IA ────────────────────────────────────────
  String _construireContexteIA() {
    if (widget.champs.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('\n\nVoici le contexte de votre exploitation :');

    for (final champ in widget.champs) {
      buffer.writeln('\n🌾 Champ : ${champ.nom}');
      buffer.writeln('   • Superficie : ${champ.superficie} ha');
      if (champ.localisation != null)
        buffer.writeln('   • Localisation : ${champ.localisation}');
      if (champ.description != null)
        buffer.writeln('   • Description : ${champ.description}');

      final cultures = widget.culturesParChamp[champ.id] ?? [];
      if (cultures.isNotEmpty) {
        buffer.writeln('   • Cultures :');
        for (final c in cultures) {
          buffer.write('     – ${c.nom} (${c.typeCulture})'
              ' · Stade : ${c.stadeCroissance}');
          if (c.notes != null && c.notes!.isNotEmpty)
            buffer.write(' · Notes : ${c.notes}');
          buffer.writeln();
        }
      } else {
        buffer.writeln('   • Aucune culture enregistrée');
      }
    }

    return buffer.toString();
  }

  // ── Réponse automatique selon le statut de l'image ────────────────────────
  String _reponseAutoImage(CaptureImage img) {
    switch (img.statut) {
      case 'alerte':
        return 'J\'ai analysé cette capture du capteur ${img.capteurNom}.\n\n'
            '⚠️ Anomalie détectée : ${img.anomalie ?? "anomalie non précisée"}.\n\n'
            '${img.confiance > 0 ? "Confiance IA : ${img.confiance}%.\n\n" : ""}'
            '${img.recommandation ?? "Une vérification terrain est recommandée sous 24h."}\n\n'
            'Souhaitez-vous plus de détails sur les causes ou les actions à mener ?';
      case 'analysee':
        return 'J\'ai examiné cette capture du capteur ${img.capteurNom}.\n\n'
            '✅ Aucune anomalie détectée — végétation conforme au stade de croissance.\n\n'
            'Avez-vous des questions sur cette zone ?';
      default:
        return 'Cette image (${img.capteurNom}) n\'a pas encore été analysée.\n\n'
            'Je peux répondre à vos questions sur vos cultures en attendant le résultat.';
    }
  }

  String _labelStatut(String s) {
    switch (s) {
      case 'alerte':   return 'Alerte IA';
      case 'analysee': return 'Analysée — OK';
      default:         return 'En attente d\'analyse';
    }
  }

  String _heure() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}h'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  // ── Envoi message ──────────────────────────────────────────────────────────
  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty) return;
    final message = texte.trim();
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(texte: message, isIA: false, heure: _heure()));
      _isTyping = true;
    });
    _scrollToBottom();

    // ── Payload prêt pour le backend IA Python ────────────────────────────
    // Décommenter quand le backend /ia/chat sera disponible :
    //
    // final payload = {
    //   'message': message,
    //   'system_context': {
    //     'champs': widget.champs.map((c) => {
    //       'id': c.id,
    //       'nom': c.nom,
    //       'superficie': c.superficie,
    //       'localisation': c.localisation,
    //       'description': c.description,
    //       'cultures': (widget.culturesParChamp[c.id] ?? []).map((cu) => {
    //         'nom': cu.nom,
    //         'type_culture': cu.typeCulture,
    //         'stade_croissance': cu.stadeCroissance,
    //         'notes': cu.notes,
    //       }).toList(),
    //     }).toList(),
    //     'image': widget.imageContexte == null ? null : {
    //       'id': widget.imageContexte!.apiId,
    //       'capteur': widget.imageContexte!.capteurNom,
    //       'zone': widget.imageContexte!.zone,
    //       'statut': widget.imageContexte!.statut,
    //       'anomalie': widget.imageContexte!.anomalie,
    //       'recommandation': widget.imageContexte!.recommandation,
    //       'confiance': widget.imageContexte!.confiance,
    //       'url': widget.imageContexte!.imageUrl,
    //     },
    //   },
    //   'historique': _messages
    //       .where((m) => !m.isImageContexte)
    //       .map((m) => {
    //             'role': m.isIA ? 'assistant' : 'user',
    //             'content': m.texte,
    //           })
    //       .toList(),
    // };
    //
    // final response = await http.post(
    //   Uri.parse('$baseUrl/ia/chat'),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode(payload),
    // );
    // final reponseIA = jsonDecode(response.body)['reponse'] as String;

    // Simulation en attendant le backend
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final champsInfo = widget.champs
        .map((c) {
          final cultures = widget.culturesParChamp[c.id] ?? [];
          final culturesStr = cultures.isNotEmpty
              ? cultures.map((cu) => '${cu.nom} (${cu.stadeCroissance})').join(', ')
              : 'aucune culture';
          return '• ${c.nom} — ${c.superficie} ha — $culturesStr';
        })
        .join('\n');

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        texte: 'Backend IA non encore connecté.\n\n'
            'Contexte qui sera envoyé :\n$champsInfo'
            '${widget.imageContexte != null ? '\n• Image : ${widget.imageContexte!.capteurNom} (${widget.imageContexte!.statut})' : ''}',
        isIA:  true,
        heure: _heure(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPadding  = MediaQuery.of(context).padding.bottom;
    final showSuggestions = _messages.length <= 3;

    return Column(children: [

      // Bandeau image en contexte
      if (widget.imageContexte != null) _buildImageContexteBanner(),

      // Liste messages
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            if (_isTyping && i == _messages.length)
              return const _TypingIndicator();
            return _BubbleMessage(message: _messages[i]);
          },
        ),
      ),

      // Suggestions rapides
      if (showSuggestions)
        Container(
          color: AppColors.bg,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Questions fréquentes',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6)),
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
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(_suggestions[i],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.text)),
                  ),
                ),
              ),
            ),
          ]),
        ),

      // Barre de saisie
      Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border:
              Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomPadding),
        child: Row(children: [
          const SizedBox(width: 8),
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
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _envoyer,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'Posez une question sur vos cultures...',
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

  Widget _buildImageContexteBanner() {
    final img      = widget.imageContexte!;
    final isAlerte = img.statut == 'alerte';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlerte ? AppColors.red100 : AppColors.green100,
        border: Border(
          bottom: BorderSide(
            color: isAlerte
                ? AppColors.red600.withOpacity(0.3)
                : AppColors.green600.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44, height: 44,
            child: Image.network(
              img.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.green200,
                child: const Icon(Icons.grass,
                    color: AppColors.green700, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image en contexte : ${img.capteurNom}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isAlerte ? AppColors.red800 : AppColors.green800,
                ),
              ),
              Text(
                '${img.date} · ${img.heure}'
                '${img.anomalie != null ? " · ${img.anomalie}" : ""}',
                style: TextStyle(
                  fontSize: 11,
                  color: isAlerte ? AppColors.red800 : AppColors.green700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(
          isAlerte
              ? Icons.warning_amber_rounded
              : Icons.check_circle_outline,
          color: isAlerte ? AppColors.red600 : AppColors.green600,
          size: 18,
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HISTORIQUE TAB
// ══════════════════════════════════════════════════════════════════════════════
class _HistoriqueTab extends StatelessWidget {
  final List<ChampModel>                champs;
  final Map<String, List<CultureModel>> culturesParChamp;

  const _HistoriqueTab({
    required this.champs,
    required this.culturesParChamp,
  });

  @override
  Widget build(BuildContext context) {
    if (champs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.grass,
                color: AppColors.green600, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Aucun champ configuré',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          const Text('Ajoutez votre champ depuis les paramètres.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _SectionH('VOS CHAMPS & CULTURES'),
        const SizedBox(height: 10),
        ...champs.map((champ) {
          final cultures = culturesParChamp[champ.id] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête champ
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                          color: AppColors.green50,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.grass,
                          color: AppColors.green600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(champ.nom,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text)),
                          Text(
                            '${champ.superficie.toStringAsFixed(1)} ha'
                            '${champ.localisation != null ? ' · ${champ.localisation}' : ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                          if (champ.description != null &&
                              champ.description!.isNotEmpty)
                            Text(champ.description!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${cultures.length} culture${cultures.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.green700),
                      ),
                    ),
                  ]),
                ),

                // Cultures du champ
                if (cultures.isNotEmpty) ...[
                  const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: Color(0xFFF0F5EB)),
                  ...cultures.map(
                    (culture) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: AppColors.green100,
                              borderRadius:
                                  BorderRadius.circular(8)),
                          child: const Icon(Icons.eco,
                              color: AppColors.green600,
                              size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${culture.nom} — ${culture.typeCulture}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text),
                              ),
                              Text(
                                'Stade : ${culture.stadeCroissance}'
                                '${culture.notes != null && culture.notes!.isNotEmpty ? ' · ${culture.notes}' : ''}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.green50,
                              borderRadius:
                                  BorderRadius.circular(20)),
                          child: Text(
                            culture.stadeCroissance,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.green700),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALERTES TAB
// ══════════════════════════════════════════════════════════════════════════════
class _AlertesTab extends StatelessWidget {
  final List<ChampModel> champs;
  const _AlertesTab({required this.champs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.amber600, size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Alertes IA',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            const Text(
              'Les alertes détectées sur vos images apparaîtront ici '
              'une fois le modèle IA connecté.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODÈLE MESSAGE
// ══════════════════════════════════════════════════════════════════════════════
class _ChatMessage {
  final String  texte;
  final bool    isIA;
  final String  heure;
  final bool    isImageContexte;
  final String? imageUrl;

  const _ChatMessage({
    required this.texte,
    required this.isIA,
    required this.heure,
    this.isImageContexte = false,
    this.imageUrl,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// BULLE MESSAGE
// ══════════════════════════════════════════════════════════════════════════════
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
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isIA ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Miniature image si contexte
                if (message.imageUrl != null && message.isImageContexte) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft:  Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 180, height: 100,
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.green100,
                          child: const Center(
                            child: Icon(Icons.grass,
                                color: AppColors.green600, size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isIA ? AppColors.white : AppColors.green600,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isIA ? 4 : 16),
                      bottomRight: Radius.circular(isIA ? 16 : 4),
                    ),
                    border: isIA
                        ? Border.all(color: AppColors.border, width: 0.5)
                        : null,
                  ),
                  child: Text(
                    message.texte,
                    style: TextStyle(
                        fontSize: 13,
                        color: isIA ? AppColors.text : Colors.white,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(message.heure,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ══════════════════════════════════════════════════════════════════════════════
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const SizedBox(
          width: 40,
          child: LinearProgressIndicator(minHeight: 4),
        ),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TITRE SECTION
// ══════════════════════════════════════════════════════════════════════════════
class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.8),
  );
}