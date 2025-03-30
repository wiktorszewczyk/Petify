import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onSwitch;
  final VoidCallback onBack;

  const LoginView({super.key, required this.onSwitch, required this.onBack});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  String? _emailValidator(String? val) {
    if (val == null || val.isEmpty || !val.contains('@')) {
      return 'Podaj poprawny email';
    }
    return null;
  }

  String? _passwordValidator(String? val) {
    if (val == null || val.length < 6) {
      return 'Hasło min. 6 znaków';
    }
    return null;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Symulacja requestu
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => _isLoading = false);
      // TODO: obsługa odpowiedzi z serwera
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // Używamy SingleChildScrollView, aby w razie potrzeby móc przewinąć treść
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tu wstawiamy nasz TopHeader, jeśli chcesz go widzieć w tym samym ekranie
            // Wtedy wystarczy: TopHeader()
            // ALE jeżeli topHeader jest w "WelcomeView", to pomijamy go tutaj.

            // minimalny odstęp
            const SizedBox(height: 10),

            // 1) Pasek z przyciskiem cofania + tytułem
            _buildHeaderBar(),

            // 2) Formularz: Pola, przycisk Zaloguj się, spinner
            _buildFormArea(),
          ],
        ),
      ),
    );
  }

  // Pasek z przyciskiem cofania (po lewej) + tytuł (na środku)
  Widget _buildHeaderBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        Expanded(
          child: Text(
            'Logowanie',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48), // miejsce na ikonę, by tytuł pozostał wycentrowany
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // Główna część: Walidacja, Pola tekstowe, Spinner
  Widget _buildFormArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // E-mail
            CustomTextField(
              labelText: 'email',
              controller: _emailController,
              validator: _emailValidator,
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 15),

            // Hasło
            CustomTextField(
              labelText: 'hasło',
              obscureText: true,
              controller: _passwordController,
              validator: _passwordValidator,
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 30),

            // Zaloguj się / Spinner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              )
                  : PrimaryButton(
                text: 'Zaloguj się',
                onPressed: _submit,
              ),
            ).animate().scale(
              delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 15),

            // Link do Rejestracji
            TextButton(
              onPressed: widget.onSwitch,
              child: Text(
                'Nie masz konta? Zarejestruj się',
                style: GoogleFonts.poppins(color: AppColors.primaryColor, fontSize: 16),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
