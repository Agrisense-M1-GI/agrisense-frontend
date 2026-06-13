import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../models/champ.dart';
import '../../models/capteur.dart';
import '../../models/culture.dart';
import '../../services/champ_service.dart';
import '../../services/capteur_service.dart';
import '../../services/auth_service.dart';

class ParametreChampScreen extends StatefulWidget {
  final ChampModel? champ;
  const ParametreChampScreen({super.key, this.champ});

  @override
  State<ParametreChampScreen> createState() => _ParametreChampScreenState();
}

class _ParametreChampScreenState extends State<ParametreChampScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données chargées
  ChampModel?          _champ;
  List<CultureModel>   _cultures  = [];
  List<CapteurModel>   _capteurs  = [];
  bool                 _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _champ = widget.champ;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Chargement ─────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final champService   = context.read<ChampService>();
      final capteurService = context.read<CapteurService>();
      final auth           = context.read<AuthService>();

      // Si pas de champ passé, charge le premier
      if (_champ == null) {
        final champs = await champService.getChamps();
        if (champs.isNotEmpty) _champ = champs.first;
      }

      if (_champ == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Cultures du champ
      final cultures = await champService.getCultures(_champ!.id);

      // Capteurs (globaux, filtrés si besoin)
      if (auth.token != null) capteurService.setToken(auth.token!);
      final capteurs = await capteurService.getCapteurs();

      setState(() {
        _cultures  = cultures;
        _capteurs  = capteurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur de chargement : $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.green700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Supprimer le champ ─────────────────────────────────────────────────────
  Future<void> _supprimerChamp() async {
    final confirm = await _confirmer(
      titre:   'Supprimer le champ',
      message: 'Cette action supprimera le champ et toutes ses cultures. Continuer ?',
      danger:  true,
    );
    if (!confirm) return;

    try {
      await context.read<ChampService>().deleteChamp(_champ!.id);
      if (!mounted) return;
      _showSuccess('Champ supprimé');
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur : $e');
    }
  }

  // ── Supprimer culture ──────────────────────────────────────────────────────
  Future<void> _supprimerCulture(CultureModel culture) async {
    final confirm = await _confirmer(
      titre:   'Supprimer la culture',
      message: 'Supprimer "${culture.nom}" ?',
      danger:  true,
    );
    if (!confirm) return;

    try {
      await context.read<ChampService>().deleteCulture(
        champId:   _champ!.id,
        cultureId: culture.id,
      );
      _showSuccess('Culture supprimée');
      _loadData();
    } catch (e) {
      _showError('Erreur : $e');
    }
  }

  // ── Supprimer capteur ──────────────────────────────────────────────────────
  Future<void> _supprimerCapteur(CapteurModel capteur) async {
    final confirm = await _confirmer(
      titre:   'Supprimer le capteur',
      message: 'Supprimer "${capteur.nom}" ?',
      danger:  true,
    );
    if (!confirm) return;

    try {
      await context.read<CapteurService>().deleteCapteur(capteur.id);
      _showSuccess('Capteur supprimé');
      _loadData();
    } catch (e) {
      _showError('Erreur : $e');
    }
  }

  Future<bool> _confirmer({
    required String titre,
    required String message,
    bool danger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(titre,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            content: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      danger ? AppColors.red600 : AppColors.green600,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(danger ? 'Supprimer' : 'Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_champ?.nom ?? 'Paramètres du champ'),
        actions: [
          if (_champ != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.red600),
              onPressed: _supprimerChamp,
              tooltip: 'Supprimer le champ',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.green700,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.green600,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              icon: const Icon(Icons.agriculture, size: 18),
              text: 'Champ (${_champ == null ? 0 : 1})',
            ),
            Tab(
              icon: const Icon(Icons.eco, size: 18),
              text: 'Cultures (${_cultures.length})',
            ),
            Tab(
              icon: const Icon(Icons.sensors, size: 18),
              text: 'Capteurs (${_capteurs.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _champ == null
              ? _buildPasDeChamp()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOngletChamp(),
                    _buildOngletCultures(),
                    _buildOngletCapteurs(),
                  ],
                ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONGLET CHAMP
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOngletChamp() {
    final c = _champ!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte info
          _InfoCard(
            titre: 'Informations générales',
            rows: [
              _InfoRow(label: 'Nom',          value: c.nom),
              _InfoRow(label: 'Description',  value: c.description ?? '--'),
              _InfoRow(label: 'Localisation', value: c.localisation ?? '--'),
              _InfoRow(
                label: 'Superficie',
                value: '${c.superficie} ha',
              ),
              _InfoRow(
                label: 'Zones (capteurs)',
                value: '${_capteurs.length} zone(s)',
              ),
              _InfoRow(
                label: 'Latitude',
                value: c.latitude?.toString() ?? '--',
              ),
              _InfoRow(
                label: 'Longitude',
                value: c.longitude?.toString() ?? '--',
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bouton modifier
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ModifierChampScreen(champ: c),
                  ),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifier le champ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green600,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Bouton supprimer
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _supprimerChamp,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Supprimer le champ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red600,
                side: const BorderSide(
                    color: AppColors.red600, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONGLET CULTURES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOngletCultures() {
    return Column(
      children: [
        Expanded(
          child: _cultures.isEmpty
              ? _buildVide(
                  icon:    Icons.eco_outlined,
                  message: 'Aucune culture enregistrée',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cultures.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _CultureCard(
                    culture:    _cultures[i],
                    onModifier: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _ModifierCultureScreen(
                            champId: _champ!.id,
                            culture: _cultures[i],
                          ),
                        ),
                      );
                      if (result == true) _loadData();
                    },
                    onSupprimer: () =>
                        _supprimerCulture(_cultures[i]),
                  ),
                ),
        ),
        _buildBoutonAjouter(
          label:    'Ajouter une culture',
          icon:     Icons.eco,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _AjouterCultureScreen(champId: _champ!.id),
              ),
            );
            if (result == true) _loadData();
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONGLET CAPTEURS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOngletCapteurs() {
    return Column(
      children: [
        // Résumé zones
        if (_capteurs.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.green600.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.green700, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_capteurs.length} capteur(s) = ${_capteurs.length} zone(s) · '
                  'Surface champ : ${_champ!.superficie} ha',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.green700),
                ),
              ],
            ),
          ),

        Expanded(
          child: _capteurs.isEmpty
              ? _buildVide(
                  icon:    Icons.sensors_off,
                  message: 'Aucun capteur enregistré',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _capteurs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CapteurCard(
                    capteur:      _capteurs[i],
                    index:        i + 1,
                    superficieChamp: _champ!.superficie,
                    onModifier: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _ModifierCapteurScreen(
                            capteur: _capteurs[i],
                            superficieChamp: _champ!.superficie,
                          ),
                        ),
                      );
                      if (result == true) _loadData();
                    },
                    onSupprimer: () =>
                        _supprimerCapteur(_capteurs[i]),
                  ),
                ),
        ),
        _buildBoutonAjouter(
          label: 'Ajouter un capteur',
          icon:  Icons.sensors,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => _AjouterCapteurScreen(
                  superficieChamp: _champ!.superficie,
                ),
              ),
            );
            if (result == true) _loadData();
          },
        ),
      ],
    );
  }

  // ── Widgets utilitaires ───────────────────────────────────────────────────
  Widget _buildPasDeChamp() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Aucun champ configuré',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Configurer mon champ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green600,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );

  Widget _buildVide({
    required IconData icon,
    required String message,
  }) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _buildBoutonAjouter({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
}

// =============================================================================
// MODIFIER CHAMP
// =============================================================================
class _ModifierChampScreen extends StatefulWidget {
  final ChampModel champ;
  const _ModifierChampScreen({required this.champ});

  @override
  State<_ModifierChampScreen> createState() =>
      _ModifierChampScreenState();
}

class _ModifierChampScreenState extends State<_ModifierChampScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _supCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl  = TextEditingController(text: widget.champ.nom);
    _descCtrl = TextEditingController(
        text: widget.champ.description ?? '');
    _locCtrl  = TextEditingController(
        text: widget.champ.localisation ?? '');
    _supCtrl  = TextEditingController(
        text: widget.champ.superficie.toString());
    _latCtrl  = TextEditingController(
        text: widget.champ.latitude?.toString() ?? '');
    _lngCtrl  = TextEditingController(
        text: widget.champ.longitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _descCtrl.dispose(); _locCtrl.dispose();
    _supCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await context.read<ChampService>().updateChamp(
        id: widget.champ.id,
        data: {
          'nom':          _nomCtrl.text.trim(),
          'description':  _descCtrl.text.trim(),
          'localisation': _locCtrl.text.trim(),
          'superficie':
              double.tryParse(_supCtrl.text) ??
                  widget.champ.superficie,
          'latitude':
              double.tryParse(_latCtrl.text) ??
                  widget.champ.latitude,
          'longitude':
              double.tryParse(_lngCtrl.text) ??
                  widget.champ.longitude,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.red600),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Modifier le champ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _sauvegarder,
              child: Text('Sauvegarder',
                  style: TextStyle(
                    color: _isSaving
                        ? AppColors.textMuted
                        : AppColors.green700,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _FormCard(children: [
                _Field(label: 'Nom *',          ctrl: _nomCtrl,  icon: Icons.label_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
                const _FDivider(),
                _Field(label: 'Description',   ctrl: _descCtrl, icon: Icons.notes),
                const _FDivider(),
                _Field(label: 'Localisation',  ctrl: _locCtrl,  icon: Icons.location_on_outlined),
                const _FDivider(),
                _Field(
                  label: 'Superficie (ha) *',
                  ctrl: _supCtrl,
                  icon: Icons.straighten,
                  type: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (double.tryParse(v) == null) return 'Invalide';
                    return null;
                  },
                ),
                const _FDivider(),
                _Field(label: 'Latitude',  ctrl: _latCtrl, icon: Icons.my_location, type: TextInputType.number),
                const _FDivider(),
                _Field(label: 'Longitude', ctrl: _lngCtrl, icon: Icons.my_location, type: TextInputType.number),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green200,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODIFIER CULTURE
// =============================================================================
class _ModifierCultureScreen extends StatefulWidget {
  final String champId;
  final CultureModel culture;
  const _ModifierCultureScreen(
      {required this.champId, required this.culture});

  @override
  State<_ModifierCultureScreen> createState() =>
      _ModifierCultureScreenState();
}

class _ModifierCultureScreenState
    extends State<_ModifierCultureScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _autreTypeCtrl;
  late final TextEditingController _notesCtrl;

  late String _typeCulture;
  late String _stade;
  bool   _autreType = false;
  bool   _isSaving  = false;

  final List<String> _types = [
    'Maïs', 'Manioc', 'Haricot', 'Tomate', 'Plantain',
    'Blé', 'Riz', 'Sorgho', 'Autre',
  ];
  final List<String> _stades = [
    'Semis', 'Germination', 'Croissance',
    'Floraison', 'Fructification', 'Récolte',
  ];

  @override
  void initState() {
    super.initState();
    _nomCtrl      = TextEditingController(text: widget.culture.nom);
    _notesCtrl    = TextEditingController(
        text: widget.culture.notes ?? '');
    _autreTypeCtrl = TextEditingController();
    _stade        = _stades.contains(widget.culture.stadeCroissance)
        ? widget.culture.stadeCroissance
        : _stades.first;

    if (_types.contains(widget.culture.typeCulture)) {
      _typeCulture = widget.culture.typeCulture;
      _autreType   = false;
    } else {
      _typeCulture     = 'Autre';
      _autreType       = true;
      _autreTypeCtrl.text = widget.culture.typeCulture;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _autreTypeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final typeFinal =
        _autreType ? _autreTypeCtrl.text.trim() : _typeCulture;

    try {
      await context.read<ChampService>().updateCulture(
        champId:   widget.champId,
        cultureId: widget.culture.id,
        data: {
          'nom':             _nomCtrl.text.trim(),
          'type_culture':    typeFinal,
          'stade_croissance': _stade,
          'notes':           _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.red600),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Modifier la culture'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _sauvegarder,
              child: Text('Sauvegarder',
                  style: TextStyle(
                    color: _isSaving
                        ? AppColors.textMuted
                        : AppColors.green700,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormCard(children: [
                _Field(
                  label: 'Nom *',
                  ctrl: _nomCtrl,
                  icon: Icons.spa_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const _FDivider(),
                _Field(
                  label: 'Notes',
                  ctrl: _notesCtrl,
                  icon: Icons.notes,
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('Type de culture'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _types.map((t) {
                          final isAutre = t == 'Autre';
                          final sel = _autreType
                              ? isAutre
                              : _typeCulture == t;
                          return _Chip(
                            label: t,
                            selected: sel,
                            onTap: () => setState(() {
                              if (isAutre) {
                                _autreType = true;
                              } else {
                                _autreType   = false;
                                _typeCulture = t;
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      if (_autreType) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _autreTypeCtrl,
                          decoration: _inputDeco(
                              'Précisez le type *'),
                          validator: (v) =>
                              _autreType &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('Stade de croissance'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _stades.map((s) => _Chip(
                          label: s,
                          selected: _stade == s,
                          onTap: () =>
                              setState(() => _stade = s),
                        )).toList(),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AJOUTER CULTURE
// =============================================================================
class _AjouterCultureScreen extends StatefulWidget {
  final String champId;
  const _AjouterCultureScreen({required this.champId});

  @override
  State<_AjouterCultureScreen> createState() =>
      _AjouterCultureScreenState();
}

class _AjouterCultureScreenState
    extends State<_AjouterCultureScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nomCtrl       = TextEditingController();
  final _autreTypeCtrl = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _dateSemCtrl   = TextEditingController();
  final _dateRecCtrl   = TextEditingController();

  String _typeCulture = 'Maïs';
  String _stade       = 'Semis';
  bool   _autreType   = false;
  bool   _isSaving    = false;

  final List<String> _types = [
    'Maïs', 'Manioc', 'Haricot', 'Tomate', 'Plantain',
    'Blé', 'Riz', 'Sorgho', 'Autre',
  ];
  final List<String> _stades = [
    'Semis', 'Germination', 'Croissance',
    'Floraison', 'Fructification', 'Récolte',
  ];

  @override
  void dispose() {
    _nomCtrl.dispose(); _autreTypeCtrl.dispose();
    _notesCtrl.dispose(); _dateSemCtrl.dispose();
    _dateRecCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.green600),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final typeFinal =
        _autreType ? _autreTypeCtrl.text.trim() : _typeCulture;

    try {
      await context.read<ChampService>().createCulture(
        champId:          widget.champId,
        nom:              _nomCtrl.text.trim(),
        typeCulture:      typeFinal,
        stadeCroissance:  _stade,
        dateSemence: _dateSemCtrl.text.trim().isNotEmpty
            ? _dateSemCtrl.text.trim() : null,
        dateRecoltePrevue: _dateRecCtrl.text.trim().isNotEmpty
            ? _dateRecCtrl.text.trim() : null,
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.red600),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Ajouter une culture')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormCard(children: [
                _Field(
                  label: 'Nom de la culture *',
                  ctrl: _nomCtrl,
                  icon: Icons.spa_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const _FDivider(),
                _Field(
                  label: 'Date de semence',
                  ctrl: _dateSemCtrl,
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _pickDate(_dateSemCtrl),
                ),
                const _FDivider(),
                _Field(
                  label: 'Date de récolte prévue',
                  ctrl: _dateRecCtrl,
                  icon: Icons.event_available_outlined,
                  readOnly: true,
                  onTap: () => _pickDate(_dateRecCtrl),
                ),
                const _FDivider(),
                _Field(
                  label: 'Notes',
                  ctrl: _notesCtrl,
                  icon: Icons.notes,
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('Type de culture *'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _types.map((t) {
                          final isAutre = t == 'Autre';
                          final sel = _autreType
                              ? isAutre
                              : _typeCulture == t;
                          return _Chip(
                            label: t,
                            selected: sel,
                            onTap: () => setState(() {
                              if (isAutre) {
                                _autreType = true;
                              } else {
                                _autreType   = false;
                                _typeCulture = t;
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      if (_autreType) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _autreTypeCtrl,
                          decoration:
                              _inputDeco('Précisez le type *'),
                          validator: (v) =>
                              _autreType &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('Stade de croissance'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _stades
                        .map((s) => _Chip(
                              label: s,
                              selected: _stade == s,
                              onTap: () =>
                                  setState(() => _stade = s),
                            ))
                        .toList(),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white))
                      : const Text('Ajouter la culture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODIFIER CAPTEUR
// =============================================================================
class _ModifierCapteurScreen extends StatefulWidget {
  final CapteurModel capteur;
  final double superficieChamp;
  const _ModifierCapteurScreen(
      {required this.capteur, required this.superficieChamp});

  @override
  State<_ModifierCapteurScreen> createState() =>
      _ModifierCapteurScreenState();
}

class _ModifierCapteurScreenState
    extends State<_ModifierCapteurScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _surfaceCtrl;
  late final TextEditingController _batterieCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late String _typeCapteur;
  late String _etat;
  bool _isSaving = false;

  final List<Map<String, String>> _typesCapteur = [
  {'value': 'humidite', 'label': 'Humidité'},
  {'value': 'imageur',  'label': 'Imageur'},
  {'value': 'mixte',    'label': 'Mixte'},
];
  final List<String> _etats = ['actif', 'inactif'];

  @override
  void initState() {
    super.initState();
    _nomCtrl     = TextEditingController(text: widget.capteur.nom);
    _surfaceCtrl = TextEditingController(
        text: widget.capteur.surfaceCouverte?.toString() ?? '');
    _batterieCtrl = TextEditingController(
        text: widget.capteur.batterie?.toString() ?? '100');
    _latCtrl = TextEditingController(
        text: widget.capteur.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(
        text: widget.capteur.longitude?.toString() ?? '');
    _typeCapteur = widget.capteur.typeCapteur ?? 'humidite';
    _etat        = widget.capteur.etat;
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _surfaceCtrl.dispose();
    _batterieCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await context.read<CapteurService>().updateEtat(
        id:       widget.capteur.id,
        etat:     _etat,
        batterie: int.tryParse(_batterieCtrl.text),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.red600),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Modifier le capteur'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _sauvegarder,
              child: Text('Sauvegarder',
                  style: TextStyle(
                    color: _isSaving
                        ? AppColors.textMuted
                        : AppColors.green700,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormCard(children: [
                _Field(
                  label: 'Nom *',
                  ctrl: _nomCtrl,
                  icon: Icons.label_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const _FDivider(),
                _Field(
                  label: 'Surface couverte (ha)',
                  ctrl: _surfaceCtrl,
                  icon: Icons.straighten,
                  type: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null) return 'Invalide';
                    if (val > widget.superficieChamp) {
                      return 'Max ${widget.superficieChamp} ha (superficie du champ)';
                    }
                    return null;
                  },
                ),
                const _FDivider(),
                _Field(
                  label: 'Batterie (%)',
                  ctrl: _batterieCtrl,
                  icon: Icons.battery_full,
                  type: TextInputType.number,
                ),
                const _FDivider(),
                _Field(
                  label: 'Latitude',
                  ctrl: _latCtrl,
                  icon: Icons.my_location,
                  type: TextInputType.number,
                ),
                const _FDivider(),
                _Field(
                  label: 'Longitude',
                  ctrl: _lngCtrl,
                  icon: Icons.my_location,
                  type: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('État du capteur'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: _etats.map((e) {
                      final sel = _etat == e;
                      final color = e == 'actif'
                          ? AppColors.green600
                          : AppColors.red600;
                      final bg = e == 'actif'
                          ? AppColors.green100
                          : AppColors.red100;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _etat = e),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(
                                right: e == 'actif' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? bg : AppColors.bg,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    sel ? color : AppColors.border,
                                width: sel ? 1.5 : 0.5,
                              ),
                            ),
                            child: Text(
                              e == 'actif' ? 'Actif' : 'Inactif',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: sel ? color : AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AJOUTER CAPTEUR
// =============================================================================
class _AjouterCapteurScreen extends StatefulWidget {
  final double superficieChamp;
  const _AjouterCapteurScreen({required this.superficieChamp});

  @override
  State<_AjouterCapteurScreen> createState() =>
      _AjouterCapteurScreenState();
}

class _AjouterCapteurScreenState
    extends State<_AjouterCapteurScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nomCtrl      = TextEditingController();
  final _surfaceCtrl  = TextEditingController();
  final _batterieCtrl = TextEditingController(text: '100');
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();

  String _typeCapteur = 'humidite_temperature';
  bool   _isSaving    = false;

  final List<Map<String, String>> _typesCapteur = [
  {'value': 'humidite', 'label': 'Humidité'},
  {'value': 'imageur',  'label': 'Imageur'},
  {'value': 'mixte',    'label': 'Mixte'},
];

  @override
  void dispose() {
    _nomCtrl.dispose(); _surfaceCtrl.dispose();
    _batterieCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await context.read<CapteurService>().createCapteur(
        nom:             _nomCtrl.text.trim(),
        typeCapteur:     _typeCapteur,
        batterie:        int.tryParse(_batterieCtrl.text) ?? 100,
        surfaceCouverte: double.tryParse(_surfaceCtrl.text),
        latitude:        double.tryParse(_latCtrl.text),
        longitude:       double.tryParse(_lngCtrl.text),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.red600),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Ajouter un capteur')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormCard(children: [
                _Field(
                  label: 'Nom du capteur *',
                  ctrl: _nomCtrl,
                  icon: Icons.label_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const _FDivider(),
                _Field(
                  label:
                      'Surface couverte (ha, max ${widget.superficieChamp})',
                  ctrl: _surfaceCtrl,
                  icon: Icons.straighten,
                  type: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null) return 'Invalide';
                    if (val > widget.superficieChamp) {
                      return 'Max ${widget.superficieChamp} ha';
                    }
                    return null;
                  },
                ),
                const _FDivider(),
                _Field(
                  label: 'Batterie (%)',
                  ctrl: _batterieCtrl,
                  icon: Icons.battery_full,
                  type: TextInputType.number,
                ),
                const _FDivider(),
                _Field(
                  label: 'Latitude',
                  ctrl: _latCtrl,
                  icon: Icons.my_location,
                  type: TextInputType.number,
                ),
                const _FDivider(),
                _Field(
                  label: 'Longitude',
                  ctrl: _lngCtrl,
                  icon: Icons.my_location,
                  type: TextInputType.number,
                ),
              ]),
              const SizedBox(height: 16),
              const _SectionLabel('Type de capteur *'),
              _FormCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _typesCapteur.map((t) {
                      final sel = _typeCapteur == t['value'];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _typeCapteur = t['value']!),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green100
                                : AppColors.bg,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? AppColors.green600
                                  : AppColors.border,
                              width: sel ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sensors,
                                  color: sel
                                      ? AppColors.green600
                                      : AppColors.textMuted,
                                  size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(t['label']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: sel
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      color: sel
                                          ? AppColors.green700
                                          : AppColors.text,
                                    )),
                              ),
                              if (sel)
                                const Icon(Icons.check_circle,
                                    color: AppColors.green600,
                                    size: 18),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white))
                      : const Text('Ajouter le capteur'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS PARTAGÉS
// =============================================================================

class _InfoCard extends StatelessWidget {
  final String titre;
  final List<Widget> rows;
  const _InfoCard({required this.titre, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(titre),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow(
      {required this.label,
      required this.value,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                    color: Color(0xFFF0F5EB), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

class _CultureCard extends StatelessWidget {
  final CultureModel culture;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  const _CultureCard(
      {required this.culture,
      required this.onModifier,
      required this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco,
                      color: AppColors.green600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(culture.nom,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text)),
                      Text(
                          '${culture.typeCulture} · ${culture.stadeCroissance}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (culture.notes != null &&
              culture.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(culture.notes!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic)),
            ),
          const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFF0F5EB)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onModifier,
                  icon: const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.green700),
                  label: const Text('Modifier',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.green700)),
                ),
              ),
              Container(
                  width: 0.5,
                  height: 32,
                  color: const Color(0xFFF0F5EB)),
              Expanded(
                child: TextButton.icon(
                  onPressed: onSupprimer,
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.red600),
                  label: const Text('Supprimer',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.red600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapteurCard extends StatelessWidget {
  final CapteurModel capteur;
  final int index;
  final double superficieChamp;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;
  const _CapteurCard({
    required this.capteur,
    required this.index,
    required this.superficieChamp,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final isActif = capteur.etat == 'actif';
    final couleur =
        isActif ? AppColors.green600 : AppColors.textMuted;
    final bg = isActif ? AppColors.green100 : AppColors.gray50;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('C$index',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: couleur)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(capteur.nom,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text)),
                      Text(
                        '${capteur.typeCapteur ?? '--'} · '
                        'Zone $index · '
                        '${capteur.surfaceCouverte != null ? '${capteur.surfaceCouverte} ha' : '--'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: couleur),
                  ),
                ),
              ],
            ),
          ),
          // Batterie
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.battery_full,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (capteur.batterie ?? 0) / 100,
                      minHeight: 4,
                      backgroundColor:
                          const Color(0xFFE8EDE4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (capteur.batterie ?? 0) > 40
                            ? AppColors.green600
                            : (capteur.batterie ?? 0) > 20
                                ? AppColors.amber600
                                : AppColors.red600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${capteur.batterie ?? 0}%',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFF0F5EB)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onModifier,
                  icon: const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.green700),
                  label: const Text('Modifier',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.green700)),
                ),
              ),
              Container(
                  width: 0.5,
                  height: 32,
                  color: const Color(0xFFF0F5EB)),
              Expanded(
                child: TextButton.icon(
                  onPressed: onSupprimer,
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.red600),
                  label: const Text('Supprimer',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.red600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widgets atomiques ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String titre;
  const _SectionLabel(this.titre);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titre.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.8)),
      );
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(children: children),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType? type;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.type,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.green600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller:   ctrl,
                keyboardType: type,
                validator:    validator,
                readOnly:     readOnly,
                onTap:        onTap,
                maxLines:     maxLines,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  labelText:  label,
                  labelStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  border:         InputBorder.none,
                  errorStyle:     const TextStyle(fontSize: 11),
                  isDense:        true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );
}

class _FDivider extends StatelessWidget {
  const _FDivider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 44,
      color: Color(0xFFF0F5EB));
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.green100 : AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.green600
                  : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w500
                    : FontWeight.normal,
                color: selected
                    ? AppColors.green700
                    : AppColors.textMuted,
              )),
        ),
      );
}

InputDecoration _inputDeco(String label) => InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 12, color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.green600),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );