import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../styles/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_textfield.dart';
import '../../services/user_service.dart';
import '../home_view.dart';

enum LoginType { email, phone }

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
  LoginType _loginType = LoginType.email;

  String? _emailValidator(String? val) {
    if (val == null || val.isEmpty) {
      return _loginType == LoginType.email
          ? 'Podaj poprawny email'
          : 'Podaj numer telefonu';
    }

    if (_loginType == LoginType.email && !val.contains('@')) {
      return 'Podaj poprawny email';
    }

    if (_loginType == LoginType.phone) {
      // Usuń wszystkie znaki oprócz cyfr i znaku +
      final cleanPhone = val.replaceAll(RegExp(r'[^\+\d]'), '');
      if (cleanPhone.length < 9) {
        return 'Podaj poprawny numer telefonu';
      }
    }

    return null;
  }

  String? _passwordValidator(String? val) {
    if (val == null || val.length < 6) {
      return 'Hasło min. 6 znaków';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userService = UserService();

    try {
      final resp = await userService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (resp.status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zalogowano!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd logowania: ${resp.data}')),
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

  void _switchLoginType(LoginType newType) {
    if (_loginType != newType) {
      setState(() {
        _loginType = newType;
        _emailController.clear(); // Wyczyść pole przy przełączaniu
      });
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
            _buildHeaderBar(),
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
            'Logowanie',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoginTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchLoginType(LoginType.email),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _loginType == LoginType.email
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: _loginType == LoginType.email
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        color: _loginType == LoginType.email
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchLoginType(LoginType.phone),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _loginType == LoginType.phone
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: _loginType == LoginType.phone
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Telefon',
                      style: GoogleFonts.poppins(
                        color: _loginType == LoginType.phone
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
            Text(
              'Zaloguj się za pomocą:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 12),

            _buildLoginTypeSelector().animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 25),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: CustomTextField(
                key: ValueKey(_loginType),
                labelText: _loginType == LoginType.email ? 'email' : 'numer telefonu',
                controller: _emailController,
                validator: _emailValidator,
                keyboardType: _loginType == LoginType.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                prefixIcon: Icon(
                  _loginType == LoginType.email
                      ? Icons.email_outlined
                      : Icons.phone_outlined,
                  color: AppColors.primaryColor,
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'hasło',
              obscureText: true,
              controller: _passwordController,
              validator: _passwordValidator,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primaryColor,
              ),
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
                text: 'Zaloguj się',
                onPressed: _submit,
              ),
            ).animate().scale(
              delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 15),

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