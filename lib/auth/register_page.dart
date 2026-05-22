import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../app_colors.dart'; // AppColors
import 'login_page.dart' show _AppField;

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
  String _profession  = 'Agriculteur';
  int   _step         = 1; // 1 = infos perso, 2 = compte

  late AnimationController _anim;
  late Animation<double>   _fade;

  final List<String> _professions = [
    'Agriculteur',
    'Agronome',
    'Responsable de ferme',
    'Chercheur',
    'Technicien agricole',
    'Autre',
  ];

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

  void _nextStep() {
    if (_step == 1) {
      // Valider l'étape 1
      if (_prenomCtrl.text.trim().isEmpty ||
          _nomCtrl.text.trim().isEmpty) {
        _showError('Veuillez renseigner votre prénom et nom.');
        return;
      }
      setState(() => _step = 2);
      _anim.reset();
      _anim.forward();
    }
  }

  void _prevStep() {
    if (_step == 2) {
      setState(() => _step = 1);
      _anim.reset();
      _anim.forward();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = context.read<AuthService>();
    final success = await auth.register(
      email:      _emailCtrl.text,
      password:   _passwordCtrl.text,
      nom:        _nomCtrl.text,
      prenom:     _prenomCtrl.text,
      profession: _profession,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg,
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
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text, size: 18),
          onPressed: _step == 2
              ? _prevStep
              : () => Navigator.pop(context),
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

                  // ── Header ──────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.green700, AppColors.green600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.grass_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                      Text('AgriSense',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green800)),
                      Text('Création de compte',
                          style: TextStyle(fontSize: 12,
                              color: AppColors.textMuted)),
                    ]),
                  ]),

                  const SizedBox(height: 28),

                  // ── Indicateur étapes ────────────────────────────
                  Row(children: [
                    _StepDot(num: 1, active: _step >= 1,
                        label: 'Identité'),
                    _StepLine(active: _step >= 2),
                    _StepDot(num: 2, active: _step >= 2,
                        label: 'Compte'),
                  ]),

                  const SizedBox(height: 28),

                  // ════════════════════════════════════════════════
                  // ÉTAPE 1 : Informations personnelles
                  // ════════════════════════════════════════════════
                  if (_step == 1) ...[
                    const Text('Vos informations',
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    const Text('Dites-nous qui vous êtes',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 24),

                    // Prénom
                    _AppField(
                      controller: _prenomCtrl,
                      label:      'Prénom',
                      hint:       'Jean',
                      icon:       Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Prénom requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Nom
                    _AppField(
                      controller: _nomCtrl,
                      label:      'Nom',
                      hint:       'Dupont',
                      icon:       Icons.badge_outlined,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Profession
                    const Text('PROFESSION',
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8,
                      children: _professions.map((p) {
                        final sel = _profession == p;
                        return GestureDetector(
                          onTap: () => setState(() => _profession = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.green100 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.green600 : AppColors.border,
                                width: sel ? 1.5 : 0.5,
                              ),
                            ),
                            child: Text(p,
                                style: TextStyle(fontSize: 12,
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

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continuer'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ════════════════════════════════════════════════
                  // ÉTAPE 2 : Informations de compte
                  // ════════════════════════════════════════════════
                  if (_step == 2) ...[
                    Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.green100,
                            shape: BoxShape.circle),
                        child: Center(child: Text(
                          '${_prenomCtrl.text[0].toUpperCase()}'
                          '${_nomCtrl.text.isNotEmpty ? _nomCtrl.text[0].toUpperCase() : ""}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: AppColors.green700),
                        )),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${_prenomCtrl.text} ${_nomCtrl.text}',
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text)),
                        Text(_profession,
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.textMuted)),
                      ]),
                    ]),

                    const SizedBox(height: 20),
                    const Text('Votre compte',
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    const SizedBox(height: 4),
                    const Text('Créez vos identifiants de connexion',
                        style: TextStyle(fontSize: 13,
                            color: AppColors.textMuted)),
                    const SizedBox(height: 24),

                    // Email
                    _AppField(
                      controller: _emailCtrl,
                      label:      'Adresse email',
                      hint:       'votre@email.com',
                      icon:       Icons.email_outlined,
                      inputType:  TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Mot de passe
                    _AppField(
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
                        onPressed: () =>
                            setState(() => _showPwd = !_showPwd),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Mot de passe requis';
                        if (v.length < 8)
                          return 'Au moins 8 caractères';
                        if (!RegExp(r'[A-Z]').hasMatch(v))
                          return 'Au moins une majuscule';
                        if (!RegExp(r'[0-9]').hasMatch(v))
                          return 'Au moins un chiffre';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirmation mot de passe
                    _AppField(
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
                        if (v == null || v.isEmpty)
                          return 'Confirmation requise';
                        if (v != _passwordCtrl.text)
                          return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Indicateur force mot de passe
                    _PasswordStrength(password: _passwordCtrl.text),

                    const SizedBox(height: 28),

                    // Bouton inscription
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
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 18),
                                  SizedBox(width: 8),
                                  Text('Créer mon compte'),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Lien connexion ──────────────────────────────
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

// ─── Indicateur étape ─────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final int num;
  final bool active;
  final String label;
  const _StepDot(
      {required this.num, required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.green600 : const Color(0xFFE8EDE4),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: active
              ? Text('$num',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w600))
              : Text('$num',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.w500 : FontWeight.normal,
          color: active ? AppColors.green700 : AppColors.textMuted)),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.green600 : const Color(0xFFE8EDE4),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ));
  }
}

// ─── Indicateur force mot de passe ───────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _score {
    int s = 0;
    if (password.length >= 8)                         s++;
    if (RegExp(r'[A-Z]').hasMatch(password))          s++;
    if (RegExp(r'[0-9]').hasMatch(password))          s++;
    if (RegExp(r'[!@#\$%\^&\*]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = _score;
    final color = s <= 1
        ? AppColors.red600
        : s == 2
            ? AppColors.amber600
            : s == 3
                ? AppColors.amber600
                : AppColors.green600;
    final label = s <= 1 ? 'Faible' : s <= 2 ? 'Modéré' : s == 3 ? 'Bon' : 'Excellent';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(child: Container(
        height: 3,
        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
        decoration: BoxDecoration(
          color: i < s ? color : const Color(0xFFE8EDE4),
          borderRadius: BorderRadius.circular(2),
        ),
      )))),
      const SizedBox(height: 5),
      Text('Sécurité : $label',
          style: TextStyle(fontSize: 11,
              color: color, fontWeight: FontWeight.w500)),
    ]);
  }
}

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
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.green600, size: 20),
        suffixIcon: suffixIcon,
        // ... décorations de bordure et style ...
      ),
    );
  }
}