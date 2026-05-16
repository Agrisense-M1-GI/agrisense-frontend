import 'package:flutter/material.dart';
import '../../app_colors.dart';

class ParametreChampScreen extends StatefulWidget {
  const ParametreChampScreen({super.key});

  @override
  State<ParametreChampScreen> createState() => _ParametreChampScreenState();
}

class _ParametreChampScreenState extends State<ParametreChampScreen> {
  // Infos champ
  final _nomController = TextEditingController(text: 'Champ Nord');
  final _surfaceController = TextEditingController(text: '4.2');
  final _zonesController = TextEditingController(text: '4');

  // Culture
  String _culture = 'Maïs';
  String _stade = 'Croissance';
  final List<String> _cultures = ['Maïs', 'Manioc', 'Haricot', 'Tomate', 'Plantain', 'Autre'];
  final List<String> _stades = ['Semis', 'Croissance', 'Floraison', 'Récolte'];

  // Seuil humidité
  double _seuilHumidite = 60;
  bool _notifPush = true;
  bool _notifSms = false;
  bool _alerteAuto = true;
  bool _irrigationAuto = true;

  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Paramètres enregistrés avec succès !'),
          backgroundColor: AppColors.green700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _surfaceController.dispose();
    _zonesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Paramètres du champ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                'Sauver',
                style: TextStyle(
                  color: _isSaving ? AppColors.textMuted : AppColors.green700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image du champ ────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://media.istockphoto.com/id/539817708/photo/green-corn-field-blue-sky-and-sun-on-summer-day.jpg?s=170667a&w=0&k=20&c=ImxfkOC4QHQzETn54ojZMQ20HYFBiKGIPzD-SxaqK2w=',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B6D11), Color(0xFF8AB855)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                            child: Icon(Icons.landscape,
                                color: Colors.white54, size: 48)),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 12, left: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Champ Nord',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text('Dschang, Cameroun',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Identité du champ ─────────────────────────────────────────
            _SectionHeader(title: 'Identité du champ'),
            _FormCard(
              children: [
                _FormField(
                  label: 'Nom du champ',
                  controller: _nomController,
                  icon: Icons.agriculture,
                ),
                const _FieldDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'Surface (ha)',
                        controller: _surfaceController,
                        icon: Icons.straighten,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Container(
                        width: 0.5, height: 48, color: const Color(0xFFF0F5EB)),
                    Expanded(
                      child: _FormField(
                        label: 'Nb. zones',
                        controller: _zonesController,
                        icon: Icons.grid_view,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Type de culture ───────────────────────────────────────────
            _SectionHeader(title: 'Type de culture'),
            _FormCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Culture principale',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cultures.map((c) {
                          final sel = _culture == c;
                          return GestureDetector(
                            onTap: () => setState(() => _culture = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
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
                              child: Text(c,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                      color: sel
                                          ? AppColors.green700
                                          : AppColors.textMuted)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const _FieldDivider(),
                      const SizedBox(height: 8),
                      const Text('Stade de croissance',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: _stades.map((s) {
                          final sel = _stade == s;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _stade = s),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                    right: s != _stades.last ? 6 : 0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.green100
                                      : AppColors.bg,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.green600
                                        : AppColors.border,
                                    width: sel ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Text(s,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: sel
                                            ? AppColors.green700
                                            : AppColors.textMuted)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Seuil d'humidité ──────────────────────────────────────────
            _SectionHeader(title: 'Seuil & alertes'),
            _FormCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seuil d\'humidité critique',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.text)),
                              Text('En dessous → alerte déclenchée',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.green100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_seuilHumidite.round()}%',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.green700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Slider coloré
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 20),
                          activeTrackColor: _seuilColor(),
                          inactiveTrackColor: const Color(0xFFE8EDE4),
                          thumbColor: _seuilColor(),
                          overlayColor: _seuilColor().withOpacity(0.15),
                        ),
                        child: Slider(
                          value: _seuilHumidite,
                          min: 20,
                          max: 90,
                          divisions: 70,
                          onChanged: (v) =>
                              setState(() => _seuilHumidite = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('20%',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                          Text(
                            _seuilHumidite < 40
                                ? 'Zone critique'
                                : _seuilHumidite < 65
                                    ? 'Zone modérée'
                                    : 'Zone sécurisée',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _seuilColor()),
                          ),
                          const Text('90%',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),

                const _FieldDivider(),

                // Toggles alertes
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications push',
                  sub: 'Alertes en temps réel',
                  value: _notifPush,
                  onChanged: (v) => setState(() => _notifPush = v),
                ),
                const _FieldDivider(),
                _ToggleRow(
                  icon: Icons.sms_outlined,
                  label: 'Alertes SMS',
                  sub: 'Notification par message',
                  value: _notifSms,
                  onChanged: (v) => setState(() => _notifSms = v),
                ),
                const _FieldDivider(),
                _ToggleRow(
                  icon: Icons.warning_amber_outlined,
                  label: 'Alertes automatiques',
                  sub: 'Détection anomalies IA',
                  value: _alerteAuto,
                  onChanged: (v) => setState(() => _alerteAuto = v),
                ),
                const _FieldDivider(),
                _ToggleRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Irrigation automatique',
                  sub: 'Déclenche selon le seuil',
                  value: _irrigationAuto,
                  onChanged: (v) => setState(() => _irrigationAuto = v),
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Bouton sauvegarder ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.green200,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                    : const Text('Enregistrer les paramètres'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _seuilColor() {
    if (_seuilHumidite < 40) return AppColors.red600;
    if (_seuilHumidite < 65) return AppColors.amber600;
    return AppColors.green600;
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(),
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

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) => const Divider(
      height: 0.5, thickness: 0.5,
      indent: 44, color: Color(0xFFF0F5EB));
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool value, isLast;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom:
                      BorderSide(color: Color(0xFFF0F5EB), width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.text)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.green600,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}