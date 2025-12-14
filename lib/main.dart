import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'models/user.dart';

void main() {
  runApp(const ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  const ConferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конференция "Мой первый шаг в IT"',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          elevation: 4,
        ),
      ),
      home: const AuthScreen(),
    );
  }
}