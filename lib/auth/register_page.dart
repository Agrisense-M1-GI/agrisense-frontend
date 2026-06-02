// lib/auth/register_page.dart
import 'package:agrisense/interfaces/carte/configurer_champ_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';
import '../app_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _prenomCtrl   = TextEditingController();
  final _nomCtrl      = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _showPwd      = false;
  bool  _showConfirm  = false;

  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = context.read<AuthService>();
    final success = await auth.register(
      email:      _emailCtrl.text.trim(),
      password:   _passwordCtrl.text,
      nom:        _nomCtrl.text.trim(),
      prenom:     _prenomCtrl.text.trim(),
      profession: 'Agriculteur',
    );

    if (!mounted) return;

    if (success) {
      // Déconnecter pour forcer une vraie connexion
      await auth.logout();

        

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Inscription réussie ! Connectez-vous.',
                style: TextStyle(fontSize: 13)),
          ]),
          backgroundColor: AppColors.green600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 2),
        ),
      );

      // Retour vers la page de connexion après 2 secondes
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);

    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Column(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.green700, AppColors.green600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green600.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.grass_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text('Créer un compte',
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green800)),
                      const SizedBox(height: 4),
                      const Text('Rejoignez AgriSense',
                          style: TextStyle(fontSize: 13,
                              color: AppColors.textMuted)),
                    ]),
                  ),

                  const SizedBox(height: 32),

                  AppField(
                    controller: _prenomCtrl,
                    label:      'Prénom',
                    hint:       'Jean',
                    icon:       Icons.person_outline,
                    validator:  (v) => (v == null || v.trim().isEmpty)
                        ? 'Prénom requis' : null,
                  ),
                  const SizedBox(height: 14),

                  AppField(
                    controller: _nomCtrl,
                    label:      'Nom',
                    hint:       'Dupont',
                    icon:       Icons.badge_outlined,
                    validator:  (v) => (v == null || v.trim().isEmpty)
                        ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 14),

                  AppField(
                    controller: _emailCtrl,
                    label:      'Adresse email',
                    hint:       'votre@email.com',
                    icon:       Icons.email_outlined,
                    inputType:  TextInputType.emailAddress,
                    validator:  (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  AppField(
                    controller: _passwordCtrl,
                    label:      'Mot de passe',
                    hint:       '••••••••',
                    icon:       Icons.lock_outline,
                    obscure:    !_showPwd,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPwd
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _showPwd = !_showPwd),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (v.length < 8) return 'Au moins 8 caractères';
                      if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins une majuscule';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins un chiffre';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  AppField(
                    controller: _confirmCtrl,
                    label:      'Confirmer le mot de passe',
                    hint:       '••••••••',
                    icon:       Icons.lock_outline,
                    obscure:    !_showConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted, size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirmation requise';
                      if (v != _passwordCtrl.text)
                        return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.green200,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Créer mon compte'),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                  color: AppColors.green700,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}