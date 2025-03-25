import 'package:flutter/material.dart';
import 'register_view.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';
import '../../styles/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //const AppLogo(),
              const SizedBox(height: 40),
              const CustomTextField(labelText: 'Email'),
              const SizedBox(height: 15),
              const CustomTextField(labelText: 'Hasło', obscureText: true),
              const SizedBox(height: 30),
              PrimaryButton(
                text: 'Zaloguj się',
                onPressed: () {
                  // TODO: implementacja logowania z backendem
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text('Nie masz konta? Zarejestruj się', style: TextStyle(color: AppColors.textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
