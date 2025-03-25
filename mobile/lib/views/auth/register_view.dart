import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';


class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text('Rejestracja'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //const AppLogo(),
              const SizedBox(height: 30),
              const CustomTextField(labelText: 'Email'),
              const SizedBox(height: 15),
              const CustomTextField(labelText: 'Hasło', obscureText: true),
              const SizedBox(height: 15),
              const CustomTextField(labelText: 'Powtórz hasło', obscureText: true),
              const SizedBox(height: 30),
              PrimaryButton(
                text: 'Zarejestruj się',
                onPressed: () {
                  // TODO: implementacja rejestracji z backendem
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Masz już konto? Zaloguj się', style: TextStyle(color: AppColors.textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
