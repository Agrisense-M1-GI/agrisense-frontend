import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/seuil.dart';
import '../../models/capteur.dart';
import '../../services/seuil_service.dart';
import '../../services/capteur_service.dart';
import '../../services/mesure_service.dart';
import '../tableau_de_bord/notifications_page.dart';
import 'historique_humidite_page.dart';
import 'historique_irrigation_page.dart';
import 'programmation_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MonitoringScreen
// ─────────────────────────────────────────────────────────────────────────────
class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  // ── État ──────────────────────────────────────────────────────────────────
  SeuilModel?          _seuil;
  List<CapteurModel>   _capteurs     = [];
  Map<String, double?> _humiditeParCapteur = {};
  bool                 _isLoading    = true;
  bool                 _isSaving     = false;
  bool                 _depuisBackend = false;

  // Contrôleurs des champs de formulaire
  late TextEditingController _ctrlHumMin;
  late TextEditingController _ctrlHumMax;
  late TextEditingController _ctrlTempMax;

  // Clé de formulaire pour la validation
  final _formKey = GlobalKey<FormState>();

  bool _irrigationAuto = false;

  @override
  void initState() {
    super.initState();
    _ctrlHumMin  = TextEditingController();
    _ctrlHumMax  = TextEditingController();
    _ctrlTempMax = TextEditingController(text: '35');
    _loadData();
  }

  @override
  void dispose() {
    _ctrlHumMin.dispose();
    _ctrlHumMax.dispose();
    _ctrlTempMax.dispose();
    super.dispose();
  }

  // ── Chargement ────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final seuilService   = context.read<SeuilService>();
      final capteurService = context.read<CapteurService>();
      final mesureService  = context.read<MesureService>();

      final results = await Future.wait([
        seuilService.getSeuil(),
        capteurService.getCapteurs(),
      ]);

      final seuil   = results[0] as SeuilModel?;
      final capteurs = results[1] as List<CapteurModel>;

      // Humidité air par capteur
      final humiditeResults = await Future.wait(
        capteurs.map((c) => mesureService.getDerniereHumiditeAir(c.id)),
      );
      final humiditeMap = <String, double?>{};
      for (var i = 0; i < capteurs.length; i++) {
        humiditeMap[capteurs[i].id] = humiditeResults[i]?.valeur;
      }

      setState(() {
        _seuil    = seuil;
        _capteurs = capteurs;
        _humiditeParCapteur = humiditeMap;
        if (seuil != null) {
          _ctrlHumMin.text    = seuil.valeurMin.toStringAsFixed(0);
          _ctrlHumMax.text    = seuil.valeurMax.toStringAsFixed(0);
          _irrigationAuto     = seuil.irrigationAuto;
        }
        _depuisBackend = true;
        _isLoading     = false;
      });
    } catch (_) {
      setState(() {
        _depuisBackend = false;
        _isLoading     = false;
      });
    }
  }

  int get _capteursActifs => _capteurs.where((c) => c.etat == 'actif').length;

  // ── Sauvegarder seuil → POST /seuils ─────────────────────────────────────
  Future<void> _saveSeuil() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final min = double.tryParse(_ctrlHumMin.text.trim()) ?? 0;
    final max = double.tryParse(_ctrlHumMax.text.trim()) ?? 0;

    if (min >= max) {
      _showError('L\'humidité minimale doit être inférieure au maximum.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final seuilService = context.read<SeuilService>();
      // POST /seuils (UPSERT côté backend)
      await seuilService.saveSeuil(
        valeurMin:      min,
        valeurMax:      max,
        irrigationAuto: _irrigationAuto,
      );
      if (!mounted) return;
      _showSuccess('Seuils enregistrés.');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(fontSize: 13)),
      ]),
      backgroundColor: AppColors.green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
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

  // ── Lancer irrigation ─────────────────────────────────────────────────────
  Future<void> _lancerIrrigation(CapteurModel? capteur) async {
    final tous = capteur == null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          tous ? 'Irriguer tous les capteurs' : 'Irriguer ${capteur!.nom}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        content: Text(
          tous
              ? 'Lancer l\'irrigation sur ${_capteurs.length} capteur(s) actif(s) ?'
              : 'Lancer l\'irrigation sur "${capteur!.nom}" ?',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _showSuccess(tous
        ? 'Irrigation lancée sur tous les capteurs.'
        : 'Irrigation lancée sur ${capteur!.nom}.');
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
            Text('Monitoring'),
            Text('Contrôle & seuils',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend ? 'Données en ligne' : 'Données locales',
                child: Icon(
                  _depuisBackend
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: _depuisBackend
                      ? AppColors.green600
                      : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh,
                      color: AppColors.green700, size: 17),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProgrammationScreen())),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.schedule,
                  color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.green600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeuils(),
                      const SizedBox(height: 20),
                      _buildIrrigationManuelle(),
                      const SizedBox(height: 20),
                      _buildHistorique(),
                      const SizedBox(height: 20),
                      _buildAutoSection(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Section seuils (formulaires) ──────────────────────────────────────────
  Widget _buildSeuils() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Seuils de surveillance',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          if (_seuil == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Non configuré',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.amber800)),
            ),
        ]),
        const SizedBox(height: 4),
        const Text('Définissez les limites d\'humidité et de température.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),

        const SizedBox(height: 20),
        const _SectionDivider(label: 'Humidité du sol et de l\'air'),
        const SizedBox(height: 14),

        // Humidité : min + max côte à côte
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _FormField(
              label: 'Minimum',
              hint: 'ex. 30',
              unit: '%',
              controller: _ctrlHumMin,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null) return 'Valeur invalide';
                if (n < 0 || n > 100) return 'Entre 0 et 100';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FormField(
              label: 'Maximum',
              hint: 'ex. 70',
              unit: '%',
              controller: _ctrlHumMax,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null) return 'Valeur invalide';
                if (n < 0 || n > 100) return 'Entre 0 et 100';
                final min = double.tryParse(_ctrlHumMin.text) ?? 0;
                if (n <= min) return 'Doit être > min';
                return null;
              },
            ),
          ),
        ]),

        const SizedBox(height: 20),
        const _SectionDivider(label: 'Température'),
        const SizedBox(height: 14),

        // Température critique
        Row(children: [
          SizedBox(
            width: 140,
            child: _FormField(
              label: 'Critique',
              hint: 'ex. 35',
              unit: '°C',
              controller: _ctrlTempMax,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null) return 'Valeur invalide';
                if (n < 0 || n > 80) return 'Entre 0 et 80';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                '',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 20),

        // Bouton enregistrer → POST /seuils
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSeuil,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green700,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.green200,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enregistrer les seuils'),
          ),
        ),
      ]),
    );
  }

  // ── Irrigation manuelle ────────────────────────────────────────────────────
  Widget _buildIrrigationManuelle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Irrigation manuelle'),

      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _capteurs.isEmpty ? null : () => _lancerIrrigation(null),
          icon: const Icon(Icons.water_drop_outlined, size: 16),
          label: Text(_capteurs.isEmpty
              ? 'Aucun capteur disponible'
              : 'Irriguer tous les capteurs (${_capteurs.length})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green700,
            side: const BorderSide(color: AppColors.green700, width: 0.8),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      if (_capteurs.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Par capteur individuel',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        ..._capteurs.map((c) => _CapteurRow(
              capteur: c,
              humidite: _humiditeParCapteur[c.id],
              seuil: _seuil,
              onIrriguer: () => _lancerIrrigation(c),
            )),
      ],

      if (_capteurs.isEmpty)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.amber100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.amber600.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.amber800, size: 15),
            SizedBox(width: 8),
            Expanded(
                child: Text(
              'Aucun capteur configuré. Ajoutez des capteurs depuis la page Carte.',
              style: TextStyle(fontSize: 11, color: AppColors.amber800),
            )),
          ]),
        ),
    ]);
  }

  // ── Historique ─────────────────────────────────────────────────────────────
  Widget _buildHistorique() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Historique',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistoriqueHumiditeScreen())),
              child: const Text('Humidité',
                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HistoriqueIrrigationScreen())),
              child: const Text('Irrigation',
                  style: TextStyle(fontSize: 11, color: AppColors.green700)),
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 80,
          decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(8)),
          child: CustomPaint(
            painter: _MiniChart(
              seuilMin: double.tryParse(_ctrlHumMin.text) ?? 30,
              seuilMax: double.tryParse(_ctrlHumMax.text) ?? 70,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Auj']
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
        Row(children: [
          _LegendDot(color: AppColors.green600, label: 'Humidité'),
          const SizedBox(width: 14),
          _LegendDot(color: AppColors.red800, label: 'Seuil min'),
          const SizedBox(width: 14),
          _LegendDot(color: AppColors.amber600, label: 'Seuil max'),
        ]),
      ]),
    );
  }

  // ── Irrigation auto ────────────────────────────────────────────────────────
  Widget _buildAutoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.auto_mode,
              color: AppColors.green600, size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Irrigation automatique',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text)),
              Text('Activée à l\'enregistrement des seuils.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
        Switch(
          value: _irrigationAuto,
          activeColor: AppColors.green600,
          onChanged: (v) => setState(() => _irrigationAuto = v),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FormField  — champ de saisie numérique sobre
// ─────────────────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final String unit;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.hint,
    required this.unit,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.2)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
          suffixText: unit,
          suffixStyle: const TextStyle(
              fontSize: 13, color: AppColors.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.border, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.border, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.green700, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.red600, width: 0.8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.red600, width: 1.2),
          ),
          filled: true,
          fillColor: AppColors.white,
          errorStyle: const TextStyle(fontSize: 10),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionDivider  — séparateur avec label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.05)),
      const SizedBox(width: 8),
      const Expanded(child: Divider(height: 1, thickness: 0.5)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CapteurRow
// ─────────────────────────────────────────────────────────────────────────────
class _CapteurRow extends StatelessWidget {
  final CapteurModel capteur;
  final double? humidite;
  final SeuilModel? seuil;
  final VoidCallback onIrriguer;

  const _CapteurRow({
    required this.capteur,
    required this.humidite,
    required this.seuil,
    required this.onIrriguer,
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
    final afficherHumidite = humidite != null && seuil != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        // Indicateur d'état
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActif ? AppColors.green600 : AppColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(capteur.nom,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.battery_full, size: 11, color: batColor),
            const SizedBox(width: 3),
            Text('$batterie%',
                style: TextStyle(fontSize: 11, color: batColor)),
            if (afficherHumidite) ...[
              const SizedBox(width: 8),
              Text(
                '· ${humidite!.toStringAsFixed(0)}% hum.',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ]),
        ])),
        OutlinedButton(
          onPressed: isActif ? onIrriguer : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green700,
            disabledForegroundColor: AppColors.textMuted,
            side: BorderSide(
                color: isActif ? AppColors.green700 : AppColors.border,
                width: 0.8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500),
          ),
          child: const Text('Irriguer'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets atomiques
// ─────────────────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniChart
// ─────────────────────────────────────────────────────────────────────────────
class _MiniChart extends CustomPainter {
  final double seuilMin, seuilMax;
  const _MiniChart({required this.seuilMin, required this.seuilMax});

  @override
  void paint(Canvas canvas, Size size) {
    _dashLine(canvas, size, seuilMin / 100, AppColors.red800.withOpacity(0.6));
    _dashLine(canvas, size, seuilMax / 100, AppColors.amber600.withOpacity(0.6));
    final pts = [0.65, 0.72, 0.68, 0.75, 0.70, 0.65, 0.72];
    _drawCurve(canvas, size, pts, AppColors.green600);
  }

  void _dashLine(Canvas canvas, Size size, double frac, Color color) {
    final y = (1 - frac) * size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double x = 0;
    bool draw = true;
    while (x < size.width) {
      final nx = (x + (draw ? 6 : 4)).clamp(0.0, size.width);
      if (draw) canvas.drawLine(Offset(x, y), Offset(nx, y), paint);
      x = nx;
      draw = !draw;
    }
  }

  void _drawCurve(
      Canvas canvas, Size size, List<double> pts, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final offsets = pts
        .asMap()
        .entries
        .map((e) => Offset(
            e.key * (size.width) / (pts.length - 1),
            (1 - e.value) * size.height))
        .toList();

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) path.lineTo(o.dx, o.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
        offsets.last, 3, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MiniChart old) =>
      old.seuilMin != seuilMin || old.seuilMax != seuilMax;
}