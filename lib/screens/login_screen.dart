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
                )
                ],
           ),
        
          
         )),
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