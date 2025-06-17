import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/colors.dart';
import '../services/volunteer_service.dart';
import '../services/cache/cache_manager.dart';

class VolunteerApplicationView extends StatefulWidget {
  const VolunteerApplicationView({super.key});

  @override
  State<VolunteerApplicationView> createState() => _VolunteerApplicationViewState();
}

class _VolunteerApplicationViewState extends State<VolunteerApplicationView> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _motivationController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _experienceController.dispose();
    _motivationController.dispose();
    _availabilityController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final volunteerService = VolunteerService();

      final applicationData = {
        'experience': _experienceController.text.trim(),
        'motivation': _motivationController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'skills': _skillsController.text.trim(),
      };

      final response = await volunteerService.submitApplication(applicationData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode >= 200 && response.statusCode < 300) {
          CacheManager.invalidatePattern('user_');
          print('🗑️ VolunteerApplicationView: Invalidated user cache after submitting application');

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                'Wniosek wysłany!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Twój wniosek o zostanie wolontariuszem został wysłany. '
                    'Otrzymasz powiadomienie o statusie rozpatrzenia wniosku.',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          String errorMessage = 'Wystąpił błąd podczas wysyłania wniosku';

          if (response.data is Map<String, dynamic>) {
            final errorData = response.data as Map<String, dynamic>;
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wystąpił nieoczekiwany błąd: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wniosek o wolontariat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          color: AppColors.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Zostań wolontariuszem',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pomóż zwierzętom w schroniskach! Wypełnij formularz, aby zostać wolontariuszem i umożliwić sobie umawianie spacerów z psami.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildTextFormField(
                controller: _experienceController,
                label: 'Doświadczenie z zwierzętami',
                hint: 'Opisz swoje doświadczenie w pracy/opiece nad zwierzętami...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  if (value.trim().length < 20) {
                    return 'Opis powinien zawierać co najmniej 20 znaków';
                  }
                  if (value.trim().length > 1000) {
                    return 'Opis nie może przekraczać 1000 znaków';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _motivationController,
                label: 'Motywacja',
                hint: 'Dlaczego chcesz zostać wolontariuszem? Co Cię motywuje?',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  if (value.trim().length < 30) {
                    return 'Opis powinien zawierać co najmniej 30 znaków';
                  }
                  if (value.trim().length > 1000) {
                    return 'Opis nie może przekraczać 1000 znaków';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _availabilityController,
                label: 'Dostępność',
                hint: 'Kiedy jesteś dostępny? (dni tygodnia, godziny)',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  if (value.trim().length < 10) {
                    return 'Opis dostępności powinien zawierać co najmniej 10 znaków';
                  }
                  if (value.trim().length > 500) {
                    return 'Opis nie może przekraczać 500 znaków';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _skillsController,
                label: 'Umiejętności i dodatkowe informacje',
                hint: 'Jakie umiejętności posiadasz? Dodatkowe informacje o sobie...',
                maxLines: 3,
                required: false,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && value.trim().length > 500) {
                    return 'Opis nie może przekraczać 500 znaków';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  )
                      : Text(
                    'Wyślij wniosek',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informacje o wolontariacie:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Twój wniosek zostanie rozpatrzony przez administrację schroniska\n'
                          '• Po akceptacji będziesz mógł umawiać się na spacery z psami w aplikacji\n'
                          '• Wolontariat to odpowiedzialne zadanie - wymagane jest regularne zaangażowanie',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            counterText: maxLines > 1 ? '' : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}