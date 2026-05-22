// ============================================================
// lib/auth/login_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../app_colors.dart'; // AppColors
import 'register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passwordCtrl= TextEditingController();
  bool  _showPwd     = false;
  late  AnimationController _anim;
  late  Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = context.read<AuthService>();
    final success = await auth.login(
      email:    _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!success && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
    // Si succès, l'AuthWrapper redirige automatiquement
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: AppColors.red600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 48),

                // ── Logo + titre ──────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.green700, AppColors.green600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green600.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.grass_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('AgriSense',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 5),
                    const Text('Supervisez vos champs intelligemment',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted)),
                  ]),
                ),

                const SizedBox(height: 44),

                // ── Titre formulaire ──────────────────────────────
                const Text('Connexion',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                const SizedBox(height: 4),
                const Text('Accédez à votre tableau de bord',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),

                const SizedBox(height: 28),

                // ── Formulaire ────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(children: [
                    // Email
                    _AppField(
                      controller:  _emailCtrl,
                      label:       'Adresse email',
                      hint:        'votre@email.com',
                      icon:        Icons.email_outlined,
                      inputType:   TextInputType.emailAddress,
                      validator:   (v) {
                        if (v == null || v.isEmpty)
                          return 'Email requis';
                        if (!v.contains('@'))
                          return 'Email invalide';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Mot de passe
                    _AppField(
                      controller:  _passwordCtrl,
                      label:       'Mot de passe',
                      hint:        '••••••••',
                      icon:        Icons.lock_outline,
                      obscure:     !_showPwd,
                      suffixIcon:  IconButton(
                        icon: Icon(
                          _showPwd
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showPwd = !_showPwd),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Mot de passe requis';
                        if (v.length < 6)
                          return 'Au moins 6 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Bouton connexion
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.green200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('Se connecter'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),

                // ── Séparateur ────────────────────────────────────
                Row(children: [
                  Expanded(child: Container(
                      height: 0.5, color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('ou',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted.withOpacity(0.7))),
                  ),
                  Expanded(child: Container(
                      height: 0.5, color: AppColors.border)),
                ]),

                const SizedBox(height: 32),

                // ── Lien inscription ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Pas encore de compte ? ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                        children: [
                          TextSpan(
                            text: 'S\'inscrire',
                            style: TextStyle(
                                color: AppColors.green700,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Illustration bas ──────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FeatureChip(
                          icon: Icons.water_drop_outlined,
                          label: 'Irrigation'),
                      const SizedBox(width: 10),
                      _FeatureChip(
                          icon: Icons.sensors,
                          label: 'Capteurs'),
                      const SizedBox(width: 10),
                      _FeatureChip(
                          icon: Icons.analytics_outlined,
                          label: 'Analyses'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Champ de saisie réutilisable ─────────────────────────────────────────────
class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? inputType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AppField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: inputType,
      obscureText:  obscure,
      validator:    validator,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText:     label,
        hintText:      hint,
        prefixIcon:    Icon(icon, color: AppColors.green600, size: 20),
        suffixIcon:    suffixIcon,
        labelStyle: const TextStyle(
            fontSize: 13, color: AppColors.textMuted),
        hintStyle: const TextStyle(
            fontSize: 13, color: AppColors.textMuted),
        filled:        true,
        fillColor:     Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
              color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
              color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
              color: AppColors.green600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
              color: AppColors.red600, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
              color: AppColors.red600, width: 1.5),
        ),
        errorStyle: const TextStyle(
            fontSize: 11, color: AppColors.red600),
      ),
    );
  }
}

// ─── Feature chip ─────────────────────────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.green100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green600.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.green700, size: 14),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.green700)),
      ]),
    );
  }
}