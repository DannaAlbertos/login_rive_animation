import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:async';
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';

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

  //4.2 Errores para mostrar en la UI
  String? emailError;
  String? pwdError;

  //5.2 Variable para mostrar el CircularProgressIndicator mientras carga
  bool _isLoading = false;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    //Recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pwd = pwdCtrl.text;

    //Recalcular errores
    final emailTypedError = isValidEmail(email) ? null : 'Invalid Email';
    final pwdTypedError = isValidPassword(pwd) ? null : 'Invalid Password';

    //4.5 Para mostrar el cambio
    setState(() {
      emailError = emailTypedError;
      pwdError = pwdTypedError;
    });

    //4.6 Cerrar el teclado y oso neutro
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 (modificado) Si algún campo tiene formato inválido, activar fallo y detener aquí
    if (emailTypedError != null || pwdTypedError != null) {
      _trigFail?.fire();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Credenciales no válidas")),
      );
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
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar a la pantalla de productos (catálogo de vestidos)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } catch (e) {
      // TEMPORAL: muestra en la consola la causa real del fallo (bórralo cuando funcione)
      debugPrint('Login error: $e');
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      setState(() {
        _isLoading = false;
      });
      _trigFail?.fire();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales no válidas")),
        );
      }
    }
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

  // Círculo decorativo del fondo
  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // Estilo compartido de los campos de texto
  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    String? error,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      //4.9 Mostrar el error
      errorText: error,
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
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado rosa
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Color(0xFFFFC1DC),
                    Color(0xFFFFE3F0),
                    Color(0xFFFFF7FB),
                  ],
                ),
              ),
            ),
          ),
          // Círculos decorativos
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
                      // ---- Osito Rive (lógica original sin cambios) ----
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

                      // ---- Tarjeta flotante (el osito se asoma por arriba) ----
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
                                if (_isHandsUp != null) {
                                  //No tapes los ojos al ver el email
                                  //_isHandsUp!.change(false);
                                }
                                //si isChecking no es null
                                if (_isChecking == null) return;
                                //Activa el modo chismoso
                                _isChecking!.change(true);
                                //3.4. Implementar recorrido de mirada
                                //Ajuste de límites del 0 al 100
                                //80 medida de calibración. Clamp es un rango y se traduce como abrazadera
                                final look =
                                    (value.length / 80.0 * 100).clamp(0.0, 100.0);
                                _numLook?.value = look;

                                //3.5. Debounce: si vuelve a teclear, reinicia el controlador
                                _typingDebounce?.cancel();
                                //Crear nuevo timer
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
                                error: emailError,
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
                                if (_isChecking != null) {
                                  //No actives el modo chismoso
                                  //_isChecking!.change(false);
                                }
                                //si isHandsUp no es null
                                if (_isHandsUp == null) return;
                                //Tapa los ojos
                                _isHandsUp!.change(true);
                              },
                              obscureText: _isObscure,
                              decoration: _decoration(
                                hint: 'Password',
                                icon: Icons.lock_rounded,
                                error: pwdError,
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
                            const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: _pinkDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

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
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Register',
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