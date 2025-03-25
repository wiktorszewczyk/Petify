import 'package:flutter/material.dart';
import 'styles/theme.dart';
import 'views/auth/login_view.dart';

void main() {
  runApp(const PetifyApp());
}

class PetifyApp extends StatelessWidget {
  const PetifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const LoginScreen(),
    );
  }
}
