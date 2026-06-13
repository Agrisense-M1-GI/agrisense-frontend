import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/champ_service.dart';
import '../../services/capteur_service.dart';
import '../../services/seuil_service.dart';

class ConfigurerChampScreen extends StatefulWidget {
  const ConfigurerChampScreen({super.key});

  @override
  State<ConfigurerChampScreen> createState() => _ConfigurerChampScreenState();
}

class _ConfigurerChampScreenState extends State<ConfigurerChampScreen> {
  final _formKey  = GlobalKey<FormState>();
  int   _etape    = 0; // 0=champ, 1=culture, 2=capteur
  bool  _isSaving = false;

  // ── Champ ─────────────────────────────────────────────────────────────────
  final _nomChampCtrl    = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _localisationCtrl= TextEditingController();
  final _superficieCtrl  = TextEditingController();
  final _latCtrl         = TextEditingController();
  final _lngCtrl         = TextEditingController();

  // ── Culture ───────────────────────────────────────────────────────────────
  final _nomCultureCtrl     = TextEditingController();
  final _autreTypeCtrl      = TextEditingController();
  final _stadeCtrl          = TextEditingController();
  final _dateSemenceCtrl    = TextEditingController();
  final _dateRecoltCtrl     = TextEditingController();
  final _notesCtrl          = TextEditingController();

  String  _typeCulture   = 'Maïs';
  bool    _autreType     = false;
  final List<String> _typesCulture = [
    'Maïs', 'Manioc', 'Haricot', 'Tomate', 'Plantain',
    'Blé', 'Riz', 'Sorgho', 'Autre',
  ];
  final List<String> _stadesCroissance = [
    'Semis', 'Germination', 'Croissance', 'Floraison',
    'Fructification', 'Récolte',
  ];
  String _stadeCroissance = 'Semis';

  // ── Capteur ───────────────────────────────────────────────────────────────
  final _nomCapteurCtrl      = TextEditingController();
  final _surfaceCtrl         = TextEditingController();
  final _batterieCtrl        = TextEditingController(text: '100');
  final _latCapteurCtrl      = TextEditingController();
  final _lngCapteurCtrl      = TextEditingController();

 String _typeCapteur = 'mixte';
final List<Map<String, String>> _typesCapteur = [
  {'value': 'humidite', 'label': 'Humidité'},
  {'value': 'imageur',  'label': 'Imageur'},
  {'value': 'mixte',    'label': 'Mixte'},
];

  // IDs créés
  String? _champId;

  @override
  void dispose() {
    _nomChampCtrl.dispose();
    _descCtrl.dispose();
    _localisationCtrl.dispose();
    _superficieCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _nomCultureCtrl.dispose();
    _autreTypeCtrl.dispose();
    _stadeCtrl.dispose();
    _dateSemenceCtrl.dispose();
    _dateRecoltCtrl.dispose();
    _notesCtrl.dispose();
    _nomCapteurCtrl.dispose();
    _surfaceCtrl.dispose();
    _batterieCtrl.dispose();
    _latCapteurCtrl.dispose();
    _lngCapteurCtrl.dispose();
    super.dispose();
  }

  // ── Navigation entre étapes ───────────────────────────────────────────────
  void _suivant() {
    if (!_formKey.currentState!.validate()) return;
    if (_etape < 2) setState(() => _etape++);
  }

  void _precedent() {
    if (_etape > 0) setState(() => _etape--);
  }

  // ── Sauvegarde finale ─────────────────────────────────────────────────────
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final champService   = context.read<ChampService>();
      final capteurService = context.read<CapteurService>();
      final auth           = context.read<AuthService>();

      // 1. Créer le champ
      final champ = await champService.createChamp(
        nom:          _nomChampCtrl.text.trim(),
        description:  _descCtrl.text.trim(),
        localisation: _localisationCtrl.text.trim(),
        superficie:   double.tryParse(_superficieCtrl.text) ?? 0,
        latitude:     double.tryParse(_latCtrl.text),
        longitude:    double.tryParse(_lngCtrl.text),
      );
      _champId = champ.id;

      // 2. Créer la culture dans ce champ
      final typeFinal = _autreType
          ? _autreTypeCtrl.text.trim()
          : _typeCulture;

      await champService.createCulture(
        champId:          _champId!,
        nom:              _nomCultureCtrl.text.trim(),
        typeCulture:      typeFinal,
        stadeCroissance:  _stadeCroissance,
        dateSemence:      _dateSemenceCtrl.text.trim().isNotEmpty
            ? _dateSemenceCtrl.text.trim() : null,
        dateRecoltePrevue: _dateRecoltCtrl.text.trim().isNotEmpty
            ? _dateRecoltCtrl.text.trim() : null,
        notes:            _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim() : null,
      );

      // 3. Créer le capteur
      if (auth.token != null) {
        capteurService.setToken(auth.token!);
      }
      await capteurService.createCapteur(
        nom:            _nomCapteurCtrl.text.trim(),
        typeCapteur:    _typeCapteur,
        batterie:       int.tryParse(_batterieCtrl.text) ?? 100,
        surfaceCouverte: double.tryParse(_surfaceCtrl.text),
        latitude:       double.tryParse(_latCapteurCtrl.text),
        longitude:      double.tryParse(_lngCapteurCtrl.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuration enregistrée avec succès !'),
          backgroundColor: AppColors.green700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true); // true = données créées
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.red600,
        ),
      );
    }

    setState(() => _isSaving = false);
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  DateTime.now(),
      firstDate:    DateTime(2020),
      lastDate:     DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.green600),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Configurer mon exploitation'),
        leading: _etape > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _precedent,
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Indicateur d'étape ─────────────────────────────────────────
          _StepIndicator(etape: _etape),

          // ── Formulaire ─────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: [
                  _buildEtapeChamp(),
                  _buildEtapeCulture(),
                  _buildEtapeCapteur(),
                ][_etape],
              ),
            ),
          ),

          // ── Boutons de navigation ──────────────────────────────────────
          _buildBoutonsNavigation(),
        ],
      ),
    );
  }

  // ── ÉTAPE 1 : Champ ───────────────────────────────────────────────────────
  Widget _buildEtapeChamp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreEtape(
          icon: Icons.agriculture,
          titre: 'Mon champ',
          sous: 'Informations générales sur votre exploitation',
        ),
        const SizedBox(height: 20),
        _ChampFormCard(children: [
          _AppField(
            label: 'Nom du champ *',
            ctrl: _nomChampCtrl,
            icon: Icons.label_outline,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const _Divider(),
          _AppField(
            label: 'Description',
            ctrl: _descCtrl,
            icon: Icons.notes,
          ),
          const _Divider(),
          _AppField(
            label: 'Localisation *',
            ctrl: _localisationCtrl,
            icon: Icons.location_on_outlined,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const _Divider(),
          _AppField(
            label: 'Superficie (ha) *',
            ctrl: _superficieCtrl,
            icon: Icons.straighten,
            type: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (double.tryParse(v) == null) return 'Nombre invalide';
              return null;
            },
          ),
        ]),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Coordonnées GPS (optionnel)'),
        _ChampFormCard(children: [
          _AppField(
            label: 'Latitude',
            ctrl: _latCtrl,
            icon: Icons.my_location,
            type: TextInputType.number,
          ),
          const _Divider(),
          _AppField(
            label: 'Longitude',
            ctrl: _lngCtrl,
            icon: Icons.my_location,
            type: TextInputType.number,
          ),
        ]),
      ],
    );
  }

  // ── ÉTAPE 2 : Culture ─────────────────────────────────────────────────────
  Widget _buildEtapeCulture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreEtape(
          icon: Icons.eco,
          titre: 'Ma culture',
          sous: 'Type de culture et stade de croissance',
        ),
        const SizedBox(height: 20),
        _ChampFormCard(children: [
          _AppField(
            label: 'Nom de la culture *',
            ctrl: _nomCultureCtrl,
            icon: Icons.spa_outlined,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
        ]),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Type de culture *'),
        _ChampFormCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _typesCulture.map((t) {
                      final isAutre = t == 'Autre';
                      final sel     = _autreType ? isAutre : _typeCulture == t;
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isAutre) {
                            _autreType  = true;
                          } else {
                            _autreType   = false;
                            _typeCulture = t;
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green100
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.green600
                                  : AppColors.border,
                              width: sel ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: sel
                                    ? AppColors.green700
                                    : AppColors.textMuted,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  // Champ libre si "Autre"
                  if (_autreType) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _autreTypeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Précisez le type de culture *',
                        labelStyle: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.green600),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      validator: (v) => _autreType &&
                              (v == null || v.trim().isEmpty)
                          ? 'Précisez le type'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Stade de croissance'),
        _ChampFormCard(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _stadesCroissance.map((s) {
                final sel = _stadeCroissance == s;
                return GestureDetector(
                  onTap: () => setState(() => _stadeCroissance = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.green100 : AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            sel ? AppColors.green600 : AppColors.border,
                        width: sel ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w500 : FontWeight.normal,
                          color: sel
                              ? AppColors.green700
                              : AppColors.textMuted,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Dates (optionnel)'),
        _ChampFormCard(children: [
          _AppField(
            label: 'Date de semence',
            ctrl: _dateSemenceCtrl,
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () => _pickDate(_dateSemenceCtrl),
          ),
          const _Divider(),
          _AppField(
            label: 'Date de récolte prévue',
            ctrl: _dateRecoltCtrl,
            icon: Icons.event_available_outlined,
            readOnly: true,
            onTap: () => _pickDate(_dateRecoltCtrl),
          ),
        ]),
        const SizedBox(height: 16),
        _ChampFormCard(children: [
          _AppField(
            label: 'Notes',
            ctrl: _notesCtrl,
            icon: Icons.notes,
            maxLines: 3,
          ),
        ]),
      ],
    );
  }

  // ── ÉTAPE 3 : Capteur ─────────────────────────────────────────────────────
  Widget _buildEtapeCapteur() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreEtape(
          icon: Icons.sensors,
          titre: 'Mon capteur',
          sous: 'Informations sur le capteur installé dans votre champ',
        ),
        const SizedBox(height: 20),
        _ChampFormCard(children: [
          _AppField(
            label: 'Nom du capteur *',
            ctrl: _nomCapteurCtrl,
            icon: Icons.label_outline,
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const _Divider(),
          _AppField(
            label: 'Surface couverte (ha)',
            ctrl: _surfaceCtrl,
            icon: Icons.straighten,
            type: TextInputType.number,
          ),
          const _Divider(),
          _AppField(
            label: 'Batterie (%)',
            ctrl: _batterieCtrl,
            icon: Icons.battery_full,
            type: TextInputType.number,
          ),
        ]),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Type de capteur *'),
        _ChampFormCard(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: _typesCapteur.map((t) {
                final sel = _typeCapteur == t['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _typeCapteur = t['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.green100 : AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            sel ? AppColors.green600 : AppColors.border,
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
                        Text(t['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: sel
                                  ? AppColors.green700
                                  : AppColors.text,
                            )),
                        if (sel) ...[
                          const Spacer(),
                          const Icon(Icons.check_circle,
                              color: AppColors.green600, size: 18),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _SectionHeader(titre: 'Coordonnées GPS (optionnel)'),
        _ChampFormCard(children: [
          _AppField(
            label: 'Latitude',
            ctrl: _latCapteurCtrl,
            icon: Icons.my_location,
            type: TextInputType.number,
          ),
          const _Divider(),
          _AppField(
            label: 'Longitude',
            ctrl: _lngCapteurCtrl,
            icon: Icons.my_location,
            type: TextInputType.number,
          ),
        ]),
      ],
    );
  }

  // ── Boutons navigation ────────────────────────────────────────────────────
  Widget _buildBoutonsNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_etape > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _precedent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green700,
                  side: const BorderSide(
                      color: AppColors.green600, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_etape > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (_etape < 2 ? _suivant : _sauvegarder),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green600,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.green200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(_etape < 2 ? 'Suivant' : 'Terminer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titreEtape({
    required IconData icon,
    required String titre,
    required String sous,
  }) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.green100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.green600, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              Text(sous,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── StepIndicator ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int etape;
  const _StepIndicator({required this.etape});

  @override
  Widget build(BuildContext context) {
    final labels = ['Champ', 'Culture', 'Capteur'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(3, (i) {
          final done    = i < etape;
          final current = i == etape;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done || current
                                    ? AppColors.green600
                                    : AppColors.border,
                              ),
                            ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.green600
                                  : current
                                      ? AppColors.green100
                                      : AppColors.bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: done || current
                                    ? AppColors.green600
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: current
                                            ? AppColors.green700
                                            : AppColors.textMuted,
                                      )),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done
                                    ? AppColors.green600
                                    : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: current
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: current
                              ? AppColors.green700
                              : done
                                  ? AppColors.green600
                                  : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String titre;
  const _SectionHeader({required this.titre});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          titre.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _ChampFormCard extends StatelessWidget {
  final List<Widget> children;
  const _ChampFormCard({required this.children});
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

class _AppField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType? type;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const _AppField({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 44,
      color: Color(0xFFF0F5EB));
}