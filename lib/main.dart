import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:login_rive_animation/screens/login_screen.dart';

Future<void> main() async {
  // Encender el puente nativo antes de usar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase usando las credenciales de firebase_options.dart
  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen());
  }
}
