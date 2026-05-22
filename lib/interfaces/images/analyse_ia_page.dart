import 'package:flutter/material.dart';
import '../../app_colors.dart';

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

    // ORDRE DEMANDÉ :
    // 1. Assistant IA
    // 2. Historique
    // 3. Alertes
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg,

      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Analyse IA'),
            Text(
              'Assistant agricole intelligent',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),

        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.green700,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.green600,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Assistant'),
            Tab(text: 'Historique'),
            Tab(text: 'Alertes'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabs,
        children: const [
          SafeArea(
            top: false,
            child: _AssistantTab(),
          ),
          _HistoriqueTab(),
          _AlertesTab(),
        ],
      ),
    );
  }
}

//
// ════════════════════════════════════════════════════════════════
// ASSISTANT IA — FRONTEND UNIQUEMENT
// ════════════════════════════════════════════════════════════════
//

class _AssistantTab extends StatefulWidget {
  const _AssistantTab();

  @override
  State<_AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<_AssistantTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      texte:
          'Bonjour 👋\n\nJe suis votre assistant IA agricole.\nPosez votre question concernant vos cultures.',
      isIA: true,
      heure: '09h42',
    ),
  ];

  bool _isTyping = false;

  final List<String> _suggestions = [
    'Analyser cette culture',
    'Pourquoi les feuilles jaunissent ?',
    'Conseils irrigation',
    'Maladies fréquentes du maïs',
    'Que signifie cette alerte ?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _heure() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}h'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _envoyer(String texte) async {
    if (texte.trim().isEmpty) return;

    final message = texte.trim();

    _inputCtrl.clear();

    setState(() {
      _messages.add(
        _ChatMessage(
          texte: message,
          isIA: false,
          heure: _heure(),
        ),
      );

      // Animation frontend uniquement
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulation visuelle uniquement
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isTyping = false;

      // MESSAGE TEMPORAIRE FRONTEND
      // LE BACKEND PYTHON REMPLACERA CECI
      _messages.add(
        _ChatMessage(
          texte:
              'Réponse IA en attente du backend Python.\n\nCette zone sera connectée au modèle IA plus tard.',
          isIA: true,
          heure: _heure(),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [

        // ─────────────────────────────────────────
        // LISTE MESSAGES
        // ─────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isTyping && i == _messages.length) {
                return const _TypingIndicator();
              }

              return _BubbleMessage(
                message: _messages[i],
              );
            },
          ),
        ),

        // ─────────────────────────────────────────
        // SUGGESTIONS
        // ─────────────────────────────────────────
        if (_messages.length <= 2)
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  'Questions fréquentes',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 7),
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () => _envoyer(_suggestions[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _suggestions[i],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // ─────────────────────────────────────────
        // BARRE DE SAISIE
        // ─────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            14,
            10,
            14,
            12 + bottomPadding,
          ),
          child: Row(
            children: [

              // Bouton image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.green600,
                  size: 18,
                ),
              ),

              const SizedBox(width: 8),

              // Champ texte
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),

                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction:
                              TextInputAction.send,
                          onSubmitted: _envoyer,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Posez une question...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Envoyer
              GestureDetector(
                onTap: () => _envoyer(_inputCtrl.text),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.green600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green600
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//
// ════════════════════════════════════════════════════════════════
// HISTORIQUE
// ════════════════════════════════════════════════════════════════
//

class _HistoriqueTab extends StatelessWidget {
  const _HistoriqueTab();

  @override
  Widget build(BuildContext context) {
    final historiques = [
      {
        'titre': 'Analyse maïs Zone A',
        'date': '21 Mai 2026',
        'statut': 'Terminée',
      },
      {
        'titre': 'Détection maladie foliaire',
        'date': '20 Mai 2026',
        'statut': 'Terminée',
      },
      {
        'titre': 'Analyse humidité sol',
        'date': '18 Mai 2026',
        'statut': 'Terminée',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [

        const _SectionH('HISTORIQUE DES ANALYSES'),

        const SizedBox(height: 10),

        ...historiques.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.green600,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        item['titre']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        item['date']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['statut']!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.green700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

//
// ════════════════════════════════════════════════════════════════
// ALERTES
// ════════════════════════════════════════════════════════════════
//

class _AlertesTab extends StatelessWidget {
  const _AlertesTab();

  @override
  Widget build(BuildContext context) {
    final alertes = [
      {
        'titre': 'Jaunissement détecté',
        'zone': 'Zone B',
        'niveau': 'Critique',
      },
      {
        'titre': 'Humidité faible',
        'zone': 'Zone C',
        'niveau': 'Moyen',
      },
      {
        'titre': 'Possible maladie foliaire',
        'zone': 'Zone A',
        'niveau': 'Faible',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.red100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [

              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      AppColors.red600.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.red600,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 alertes actives',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Certaines anomalies nécessitent une vérification.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.red800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const _SectionH('ALERTES RÉCENTES'),

        const SizedBox(height: 10),

        ...alertes.map((a) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red600,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        a['titre']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        a['zone']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    a['niveau']!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.red800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

//
// ════════════════════════════════════════════════════════════════
// MODELE MESSAGE
// ════════════════════════════════════════════════════════════════
//

class _ChatMessage {
  final String texte;
  final bool isIA;
  final String heure;

  const _ChatMessage({
    required this.texte,
    required this.isIA,
    required this.heure,
  });
}

//
// ════════════════════════════════════════════════════════════════
// BULLE MESSAGE
// ════════════════════════════════════════════════════════════════
//

class _BubbleMessage extends StatelessWidget {
  final _ChatMessage message;

  const _BubbleMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isIA = message.isIA;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        mainAxisAlignment: isIA
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [

          if (isIA) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.green600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),

            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isIA
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isIA
                        ? AppColors.white
                        : AppColors.green600,
                    borderRadius:
                        BorderRadius.only(
                      topLeft:
                          const Radius.circular(16),
                      topRight:
                          const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(
                              isIA ? 4 : 16),
                      bottomRight:
                          Radius.circular(
                              isIA ? 16 : 4),
                    ),
                    border: isIA
                        ? Border.all(
                            color:
                                AppColors.border,
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Text(
                    message.texte,
                    style: TextStyle(
                      fontSize: 13,
                      color: isIA
                          ? AppColors.text
                          : Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message.heure,
                  style: const TextStyle(
                    fontSize: 9,
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

//
// ════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ════════════════════════════════════════════════════════════════
//

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [

          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.green600,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ════════════════════════════════════════════════════════════════
// TITRE SECTION
// ════════════════════════════════════════════════════════════════
//

class _SectionH extends StatelessWidget {
  final String text;

  const _SectionH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}