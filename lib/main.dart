import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPAKARENA',
      theme: ThemeData(
        primaryColor: const Color(0xFF7E4C27),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Langsung set home, jangan pakai initialRoute
      debugShowCheckedModeBanner: false,
    );
  }
}