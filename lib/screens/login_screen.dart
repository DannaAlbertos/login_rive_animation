import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  const new({super.key});

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

  //4.4 Acción del botón
  void _onLogin(){
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

    //4.7 Activar triggers
    if (emailTypedError == null && pwdTypedError == null){
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
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
 

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 20),
           child: Column(
             children: [
              SizedBox(
                width: screenSize.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear-animation.riv',
                  stateMachines: ['Login Machine'],
                  //1.2 Vincular la animación
                  onInit: (artboard){
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
                )
            ), 
                //Para separar elementos
                SizedBox(height: 10),
                //Email
                TextField(
                  //4.8 Vincular el controller
                  controller: emailCtrl,
                  //2.3 Asignar el Focus al TextField
                  focusNode: _emailFocus,
                  //1.5 vincular a campo de texto
                  onChanged: (value){
                    if(_isHandsUp != null){
                      //No tapes los ojos al ver el email
                      //_isHandsUp!.change(false);
                    }
                    //si isChecking no es null
                    if(_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                    //3.4. Implementar recorrido de mirada
                    //Ajuste de límites del 0 al 100
                    //80 medida de calibración. Clamp es un rango y se traduce como abrazadera
                    final look = (value.length / 80.0 * 100).clamp(0.0, 100.0);
                    _numLook?.value = look;

                    //3.5. Debounce: si vuelve a teclear, reinicia el controlador
                    _typingDebounce?.cancel();
                    //Crear nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      //Mirada neutra
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    //4.9 Mostrar el error
                    errorText: emailError,
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
                const SizedBox(height: 10),
                //Contraseña
                TextField(
                  //4.8 Vincular el controller
                  controller: pwdCtrl,
                  //2.3 Asignar el Focus al TextField
                  focusNode: _passwordFocus,
                  //1.5 vincular a campo de texto
                  onChanged: (value){
                    if(_isChecking != null){
                      //No actives el modo chismoso
                      //_isChecking!.change(false);
                    }
                    //si isHandsUp no es null
                    if(_isHandsUp == null) return;
                    //Tapa los ojos 
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    //4.9 Mostrar el error
                    errorText: pwdError,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: (){
                        //Refrescar el icono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      }, 
                      icon: Icon(
                        //If ternario
                        _isObscure ? Icons.visibility : Icons.visibility_off
                      ),
                      ),
                    border: OutlineInputBorder(
                      //Para redondear bordes
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
               
                const SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password?",
                    textAlign: TextAlign.right, 
                    style: TextStyle(decoration: TextDecoration.underline),
                  )
                ),
                const SizedBox(height: 10),
                //Toma todo el ancho posible
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: (){}, 
                        child: Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            ),
                        ),
                      ),

                    ]
                  ),
                )
              ],
            ),
          ),
        ),
      ), //RC : Release Candidate
    );
  }

  @override
  void dispose() {
    //2.4 Liberar memoeria/recursos en los focusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    //3.5. Liberar timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}