import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';
import '../../services/user_service.dart';
import '../home_view.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback onSwitch;
  final VoidCallback onBack;

  const RegisterView({super.key, required this.onSwitch, required this.onBack});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

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

  String? _repeatPasswordValidator(String? val) {
    if (val != _passwordController.text) {
      return 'Hasła muszą być takie same';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userService = UserService();

    try {
      final regResp = await userService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      setState(() => _isLoading = false);
      if (regResp.status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zarejestrowano i zalogowano!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd rejestracji: ${regResp.data}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wystąpił błąd: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            _buildHeaderBar().animate().fadeIn(duration: 400.ms, delay: 50.ms),

            const SizedBox(height: 25),

            _buildFormArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        Expanded(
          child: Text(
            'Rejestracja',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildFormArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              labelText: 'email',
              controller: _emailController,
              validator: _emailValidator,
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'hasło',
              obscureText: true,
              controller: _passwordController,
              validator: _passwordValidator,
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'powtórz hasło',
              obscureText: true,
              controller: _repeatPasswordController,
              validator: _repeatPasswordValidator,
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 30),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              )
                  : PrimaryButton(
                text: 'Zarejestruj się',
                onPressed: _submit,
              ),
            ).animate().scale(
              delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: widget.onSwitch,
              child: Text(
                'Masz już konto? Zaloguj się',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
