import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';
import '../app_field.dart';
import 'register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _showPwd      = false;
  bool  _isSaving     = false; // ← état local pour le bouton
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

    setState(() => _isSaving = true);

    final auth    = context.read<AuthService>();
    final success = await auth.login(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Bienvenue ${auth.user?.prenom ?? ""} !',
              style: const TextStyle(fontSize: 13),
            ),
          ]),
          backgroundColor: AppColors.green600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 2),
        ),
      );
      // AuthWrapper redirige automatiquement vers MainShell
    } else {
      _showError(auth.errorMessage ?? 'Email ou mot de passe incorrect');
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ]),
                ),

                const SizedBox(height: 44),

                const Text('Connexion',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                const SizedBox(height: 4),
                const Text('Accédez à votre tableau de bord',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),

                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(children: [

                    AppField(
                      controller: _emailCtrl,
                      label:      'Adresse email',
                      hint:       'votre@email.com',
                      icon:       Icons.email_outlined,
                      inputType:  TextInputType.emailAddress,
                      validator:  (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
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
                        if (v.length < 6) return 'Au moins 6 caractères';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // ✅ État local _isSaving, pas auth.isLoading
                        onPressed: _isSaving ? null : _submit,
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
                        child: _isSaving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Se connecter'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),

                Row(children: [
                  Expanded(child: Container(height: 0.5, color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('ou',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted.withOpacity(0.7))),
                  ),
                  Expanded(child: Container(height: 0.5, color: AppColors.border)),
                ]),

                const SizedBox(height: 32),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Pas encore de compte ? ',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FeatureChip(icon: Icons.water_drop_outlined, label: 'Irrigation'),
                      const SizedBox(width: 10),
                      _FeatureChip(icon: Icons.sensors, label: 'Capteurs'),
                      const SizedBox(width: 10),
                      _FeatureChip(icon: Icons.analytics_outlined, label: 'Analyses'),
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