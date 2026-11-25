import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:async';
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';
import 'signup_screen.dart';

// Colores del login
const _pink = Color(0xFFEE2680);
const _pinkLight = Color(0xFFFF5C9E);
const _pinkDark = Color(0xFFB81862);
const _pinkField = Color(0xFFFFF1F7);
const _ink = Color(0xFF2A1B26);
const _muted = Color(0xFF8A7A85);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Control para mostar ocultar contraseña
  bool _isObscure = true;

  //1.1 Máquina de estados / Cerebro de la animación
  StateMachineController? _controller;
  //StateMachineInput
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener el recorrido de la mirada
  Timer? _typingDebounce;

  //2.1 Crear variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //4.1 Controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final pwdCtrl = TextEditingController();

  //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;

  // A2. Mensaje global ÚNICO (OWASP): no dice si falló el correo o la contraseña
  void _showInvalidCredentials() {
    _trigFail?.fire();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciales inválidas')),
    );
  }

  //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    //Recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pwd = pwdCtrl.text;

    //4.6 Cerrar el teclado y oso neutro
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // A1. Solo se valida que los campos no estén vacíos (sin regex ni errorText)
    if (email.isEmpty || pwd.isEmpty) {
      _showInvalidCredentials();
      return;
    }

    //5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      //5.5 Autenticar usuario en Firebase (esperamos un par de segundos para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pwd,
      );

      //5.6 Apagar loading, disparar éxito del osito y esperar a que termine su animación
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar a la pantalla de productos (catálogo)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } catch (e) {
      // Solo en modo debug: el detalle del error nunca se muestra al usuario
      if (kDebugMode) debugPrint('Login error: $e');
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showInvalidCredentials();
    }
  }

  // C1. "Forgot password?" funcional: Dialog que pide el correo y manda el enlace
  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: emailCtrl.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escribe tu correo y te enviaremos un enlace para restablecer tu contraseña.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _pink),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (email == null) return; // canceló
    if (!mounted) return;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu correo')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) debugPrint('Reset error: $e');
    }
    if (!mounted) return;
    // Mensaje genérico: no revela si el correo existe o no
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Si el correo está registrado, te enviamos un enlace para restablecer tu contraseña.',
        ),
      ),
    );
  }

  //2.2. Crear los oyentes o listeners
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {});
    _passwordFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          //3.3. Mirar neutral
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocus.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  // ---------- ESTILO (solo visual) ----------

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // Estilo de los campos (sin errorText: A1)
  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      prefixIcon: Icon(icon, color: _pink),
      suffixIcon: suffix,
      filled: true,
      fillColor: _pinkField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_pink, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFC1DC),
                    Color(0xFFFFE3F0),
                    Color(0xFFFFF7FB),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: -70, right: -60, child: _circle(220, 0.35)),
          Positioned(top: 140, left: -80, child: _circle(160, 0.25)),
          Positioned(bottom: -90, right: -40, child: _circle(240, 0.30)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: RiveAnimation.asset(
                          'assets/login-bear-animation.riv',
                          stateMachines: ['Login Machine'],
                          //1.2 Vincular la animación
                          onInit: (artboard) {
                            _controller = StateMachineController.fromArtboard(
                              artboard,
                              'Login Machine',
                            );
                            //1.3 Verificar que inició bien
                            if (_controller == null) return;
                            //Agregar el controlador al escenario
                            artboard.addController(_controller!);
                            //1.4 Vincular las variables
                            _isChecking = _controller!.findSMI('isChecking');
                            _isHandsUp = _controller!.findSMI('isHandsUp');
                            _trigSuccess = _controller!.findSMI('trigSuccess');
                            _trigFail = _controller!.findSMI('trigFail');
                            _numLook = _controller!.findSMI('numLook');
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: _pink.withOpacity(0.18),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CATÁLOGO CHERRY',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                                color: _pink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '¡Hola de nuevo!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Inicia sesión para ver los vestidos',
                              style: TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 22),

                            //Email
                            TextField(
                              //4.8 Vincular el controller
                              controller: emailCtrl,
                              //2.3 Asignar el Focus al TextField
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              //1.5 vincular a campo de texto
                              onChanged: (value) {
                                //si isChecking no es null
                                if (_isChecking == null) return;
                                //Activa el modo chismoso
                                _isChecking!.change(true);
                                //3.4. Implementar recorrido de mirada
                                //80 medida de calibración. Clamp es un rango y se traduce como abrazadera
                                final look =
                                    (value.length / 80.0 * 100).clamp(0.0, 100.0);
                                _numLook?.value = look;

                                //3.5. Debounce: si vuelve a teclear, reinicia el controlador
                                _typingDebounce?.cancel();
                                _typingDebounce =
                                    Timer(const Duration(seconds: 3), () {
                                  if (!mounted) return;
                                  //Mirada neutra
                                  _isChecking?.change(false);
                                });
                              },
                              decoration: _decoration(
                                hint: 'Email',
                                icon: Icons.email_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),

                            //Contraseña
                            TextField(
                              //4.8 Vincular el controller
                              controller: pwdCtrl,
                              //2.3 Asignar el Focus al TextField
                              focusNode: _passwordFocus,
                              //1.5 vincular a campo de texto
                              onChanged: (value) {
                                //si isHandsUp no es null
                                if (_isHandsUp == null) return;
                                //Tapa los ojos
                                _isHandsUp!.change(true);
                              },
                              obscureText: _isObscure,
                              decoration: _decoration(
                                hint: 'Password',
                                icon: Icons.lock_rounded,
                                suffix: IconButton(
                                  onPressed: () {
                                    //Refrescar el icono
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    //If ternario
                                    _isObscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // C1. Forgot password funcional
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: _pinkDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            //4.13 Botón de login con degradado
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_pinkLight, _pink],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _onLogin,
                                //5.9 Mostrar CircularProgressIndicator si está cargando, o el texto Login
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?",
                              style: TextStyle(color: _muted)),
                          // B1. "Sign up" navega con Navigator.push (para poder regresar)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: _pinkDark,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //2.4 Liberar memoeria/recursos en los focusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    pwdCtrl.dispose();
    //3.5. Liberar timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}