// À placer dans : lib/interfaces/profil/parametre_serveur_page.dart
import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../config/api_config.dart';

/// Écran permettant de changer l'adresse du backend sans recompiler l'app.
/// Utile quand le serveur tourne sur une IP locale qui change selon le réseau.
class ParametreServeurScreen extends StatefulWidget {
  const ParametreServeurScreen({super.key});

  @override
  State<ParametreServeurScreen> createState() =>
      _ParametreServeurScreenState();
}

class _ParametreServeurScreenState extends State<ParametreServeurScreen> {
  final _urlCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  String? _validateUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'Adresse requise';
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !uri.isAbsolute) {
      return 'Format invalide. Ex: http://192.168.1.42:8080/api';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ApiConfig.setBaseUrl(_urlCtrl.text.trim());
    setState(() => _saved = true);
    if (!mounted) return;
    _showRestartDialog();
  }

  Future<void> _reset() async {
    await ApiConfig.setBaseUrl(''); // vide → retombe sur la valeur de build
    setState(() {
      _urlCtrl.text = ApiConfig.buildDefault;
      _saved = true;
    });
    if (!mounted) return;
    _showRestartDialog();
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redémarrage requis'),
        content: const Text(
          'La nouvelle adresse est enregistrée. Ferme complètement '
          'l\'application et relance-la pour qu\'elle soit prise en compte '
          'partout (connexion, capteurs, images...).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Adresse du serveur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ApiConfig.hasOverride
                    ? 'Adresse personnalisée active.'
                    : 'Adresse par défaut (build) active : ${ApiConfig.buildDefault}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de base de l\'API',
                  hintText: 'http://192.168.1.42:8080/api',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                validator: _validateUrl,
                onChanged: (_) => setState(() => _saved = false),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                ],
              ),
              if (_saved)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Enregistré. Redémarre l\'app pour appliquer.',
                    style: TextStyle(color: AppColors.green700, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}