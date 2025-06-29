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
  final PageController _pageController = PageController();
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Controllers for all fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  // State variables
  int _currentStep = 0;
  bool _isLoading = false;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'MALE';

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  // Validators
  String? _nameValidator(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'To pole jest wymagane';
    }
    if (val.trim().length < 2) {
      return 'Minimum 2 znaki';
    }
    return null;
  }

  String? _emailValidator(String? val) {
    if (val == null || val.isEmpty || !val.contains('@')) {
      return 'Podaj poprawny email';
    }
    return null;
  }

  String? _phoneValidator(String? val) {
    if (val == null || val.isEmpty) {
      return 'Podaj numer telefonu';
    }
    // Basic phone validation - adjust regex as needed
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(val.replaceAll(' ', ''))) {
      return 'Nieprawidłowy format numeru';
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

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      _showError('Wybierz datę urodzenia');
      return;
    }

    setState(() => _isLoading = true);
    final userService = UserService();

    try {
      final regResp = await userService.register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _selectedBirthDate!.toIso8601String().split('T')[0],
          gender: _selectedGender,
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim().replaceAll(' ', ''),
          password: _passwordController.text.trim()
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      if (regResp.statusCode == 200 || regResp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rejestracja zakończona pomyślnie! Teraz możesz się zalogować.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSwitch();
      } else {
        _showError('Błąd rejestracji: ${regResp.data}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Wystąpił błąd: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Min 13 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildHeader(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep == 0 ? widget.onBack : _previousStep,
        ),
        Expanded(
          child: Text(
            'Rejestracja ${_currentStep + 1}/3',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: index <= _currentStep ? AppColors.primaryColor : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    ).animate().slideX(duration: 300.ms);
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Podstawowe informacje',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 30),

            CustomTextField(
              labelText: 'Imię',
              controller: _firstNameController,
              validator: _nameValidator,
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'Nazwisko',
              controller: _lastNameController,
              validator: _nameValidator,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 15),

            // Birth date picker
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedBirthDate == null
                          ? 'Data urodzenia'
                          : '${_selectedBirthDate!.day.toString().padLeft(2, '0')}.${_selectedBirthDate!.month.toString().padLeft(2, '0')}.${_selectedBirthDate!.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _selectedBirthDate == null ? Colors.grey : AppColors.textColor,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primaryColor),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 15),

            // Gender selection
            Text(
              'Płeć',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Mężczyzna'),
                    value: 'MALE',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value!),
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Kobieta'),
                    value: 'FEMALE',
                    groupValue: _selectedGender,
                    onChanged: (value) => setState(() => _selectedGender = value!),
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

            const SizedBox(height: 40),

            // Navigation buttons for Step 1
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email i hasło',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 30),

            CustomTextField(
              labelText: 'Email',
              controller: _emailController,
              validator: _emailValidator,
              keyboardType: TextInputType.emailAddress,
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'Hasło',
              obscureText: true,
              controller: _passwordController,
              validator: _passwordValidator,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 15),

            CustomTextField(
              labelText: 'Powtórz hasło',
              obscureText: true,
              controller: _repeatPasswordController,
              validator: _repeatPasswordValidator,
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 40),

            // Navigation buttons for Step 2
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kontakt',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'W celu ułatwienia kontaktu schronisk z Tobą potrzebujemy Twój numer telefonu.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 20),

            CustomTextField(
              labelText: 'Numer telefonu',
              controller: _phoneController,
              validator: _phoneValidator,
              keyboardType: TextInputType.phone,
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 40),

            // Navigation buttons for Step 3
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
            ),
          )
              : PrimaryButton(
            text: _currentStep == 2 ? 'Utwórz konto' : 'Dalej',
            onPressed: _nextStep,
          ),
        ),

        const SizedBox(height: 10),

        if (_currentStep == 0)
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
    );
  }
}