import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _domain = '@tecdesoftware.edu.mx';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // ---- Reglas (se evalúan en vivo para mostrarlas en pantalla) ----
  String get _email => _emailCtrl.text.trim().toLowerCase();
  bool get _emailOk => RegExp(r'^[^\s@]+@tecdesoftware\.edu\.mx$').hasMatch(_email);
  bool get _lenOk => _pwdCtrl.text.length >= 8;
  bool get _upperOk => RegExp(r'[A-Z]').hasMatch(_pwdCtrl.text);
  bool get _lowerOk => RegExp(r'[a-z]').hasMatch(_pwdCtrl.text);
  bool get _digitOk => RegExp(r'\d').hasMatch(_pwdCtrl.text);
  bool get _symbolOk => RegExp(r'[^A-Za-z0-9]').hasMatch(_pwdCtrl.text);
  bool get _pwdOk => _lenOk && _upperOk && _lowerOk && _digitOk && _symbolOk;
  bool get _matchOk =>
      _confirmCtrl.text.isNotEmpty && _confirmCtrl.text == _pwdCtrl.text;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---- Registro en Firebase ----
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _pwdCtrl.text,
      );
      // Firebase inicia sesión solo al crear la cuenta; la cerramos
      // para que el usuario entre desde el Login.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ya puedes iniciar sesión.')),
      );
      Navigator.pop(context); // regresa al Login
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Ese correo ya está registrado.';
          break;
        case 'invalid-email':
          msg = 'El correo no es válido.';
          break;
        case 'weak-password':
          msg = 'La contraseña es demasiado débil.';
          break;
        case 'network-request-failed':
          msg = 'Sin conexión. Revisa tu internet.';
          break;
        default:
          msg = 'No se pudo crear la cuenta. Intenta de nuevo.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (kDebugMode) debugPrint('Sign up error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la cuenta. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Estilo ----
  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder b(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIcon: Icon(icon, color: AppColors.pink),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFFF1F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(AppColors.pink, 2),
      errorBorder: b(Colors.redAccent),
      focusedErrorBorder: b(Colors.redAccent, 2),
    );
  }

  Widget _rule(bool ok, String text) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: ok ? Colors.green : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: ok ? Colors.green.shade700 : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC1DC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC1DC), Color(0xFFFFE3F0), Color(0xFFFFF7FB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withOpacity(0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CREAR CUENTA',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Regístrate',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Usa tu correo institucional',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 22),

                        // Correo
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                          decoration: _dec('Correo institucional', Icons.email_rounded),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Escribe tu correo institucional';
                            }
                            if (!_emailOk) return 'Debe terminar en $_domain';
                            return null;
                          },
                        ),
                        _rule(_emailOk, 'Termina en $_domain'),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextFormField(
                          controller: _pwdCtrl,
                          obscureText: _obscure,
                          onChanged: (_) => setState(() {}),
                          decoration: _dec(
                            'Contraseña',
                            Icons.lock_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: AppColors.muted,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Escribe una contraseña';
                            if (!_pwdOk) return 'La contraseña no cumple todas las reglas';
                            return null;
                          },
                        ),
                        _rule(_lenOk, 'Mínimo 8 caracteres'),
                        _rule(_upperOk, 'Una letra mayúscula'),
                        _rule(_lowerOk, 'Una letra minúscula'),
                        _rule(_digitOk, 'Un número'),
                        _rule(_symbolOk, 'Un símbolo (por ejemplo: ! @ # \$ %)'),
                        const SizedBox(height: 16),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          onChanged: (_) => setState(() {}),
                          decoration: _dec(
                            'Confirmar contraseña',
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: AppColors.muted,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                            if (v != _pwdCtrl.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ),
                        _rule(_matchOk, 'Las contraseñas coinciden'),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}