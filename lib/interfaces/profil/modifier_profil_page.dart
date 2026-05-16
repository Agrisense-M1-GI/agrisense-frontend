import 'package:flutter/material.dart';
import '../../main.dart';
import '../../app_colors.dart';

class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({super.key});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController(text: 'Kouam');
  final _prenomController = TextEditingController(text: 'Njankou');
  final _emailController = TextEditingController(text: 'kouam.njankou@agrisense.cm');
  final _telController = TextEditingController(text: '+237 677 123 456');
  final _villeController = TextEditingController(text: 'Dschang');
  final _regionController = TextEditingController(text: 'Ouest, Cameroun');

  String _selectedMetier = 'Agriculteur';
  final List<String> _metiers = [
    'Agriculteur',
    'Agronome',
    'Responsable de ferme',
    'Chercheur',
    'Autre',
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _villeController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour avec succès !'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                'Sauvegarder',
                style: TextStyle(
                  color: _isSaving
                      ? AppColors.textMuted
                      : AppColors.green700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
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
              // ── Avatar éditable ───────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.green200,
                      child: Text(
                        'KN',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: AppColors.green700),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.green600,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: AppColors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Appuyer pour changer la photo',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 24),

              // ── Informations personnelles ─────────────────────────────
              _SectionHeader(title: 'Informations personnelles'),
              _FormCard(
                children: [
                  _AppField(
                    label: 'Prénom',
                    controller: _prenomController,
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  const _Divider(),
                  _AppField(
                    label: 'Nom',
                    controller: _nomController,
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  const _Divider(),
                  _AppField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const _Divider(),
                  _AppField(
                    label: 'Téléphone',
                    controller: _telController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Localisation ──────────────────────────────────────────
              _SectionHeader(title: 'Localisation'),
              _FormCard(
                children: [
                  _AppField(
                    label: 'Ville',
                    controller: _villeController,
                    icon: Icons.location_city_outlined,
                  ),
                  const _Divider(),
                  _AppField(
                    label: 'Région',
                    controller: _regionController,
                    icon: Icons.map_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Métier ────────────────────────────────────────────────
              _SectionHeader(title: 'Profession'),
              _FormCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.work_outline,
                            color: AppColors.green600, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMetier,
                              isExpanded: true,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.text),
                              icon: const Icon(Icons.expand_more,
                                  color: AppColors.textMuted),
                              onChanged: (v) =>
                                  setState(() => _selectedMetier = v!),
                              items: _metiers
                                  .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Bouton sauvegarder ────────────────────────────────────
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
                              strokeWidth: 2,
                              color: AppColors.white),
                        )
                      : const Text('Enregistrer les modifications'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _AppField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AppField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.green600, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
                border: InputBorder.none,
                errorStyle:
                    const TextStyle(fontSize: 11, height: 0.8),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 0.5, thickness: 0.5,
        indent: 44, color: Color(0xFFF0F5EB));
  }
}