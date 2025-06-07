import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../styles/colors.dart';

class AdoptionFormView extends StatefulWidget {
  final Pet pet;

  const AdoptionFormView({Key? key, required this.pet}) : super(key: key);

  @override
  State<AdoptionFormView> createState() => _AdoptionFormViewState();
}

class _AdoptionFormViewState extends State<AdoptionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();

  bool _isLoading = false;

  // Kontrolery pól formularza
  final _motivationController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _housingTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isHouseOwner = false;
  bool _hasYard = false;
  bool _hasOtherPets = false;

  @override
  void dispose() {
    _motivationController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _housingTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _petService.createAdoptionForm(
        petId: widget.pet.id,
        motivationText: _motivationController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        housingType: _housingTypeController.text.trim(),
        isHouseOwner: _isHouseOwner,
        hasYard: _hasYard,
        hasOtherPets: _hasOtherPets,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 201) {
          // Sukces
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                'Formularz wysłany!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Twój formularz adopcji dla ${widget.pet.name} został wysłany do schroniska. '
                    'Skontaktujemy się z Tobą wkrótce.',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Zamknij dialog
                    Navigator.of(context).pop(); // Wróć do poprzedniego ekranu
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
          // Błąd
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wystąpił błąd podczas wysyłania formularza'),
              backgroundColor: Colors.red,
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
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
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
          'Formularz adopcji',
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
              // Informacje o zwierzęciu
              _buildPetInfo(),
              const SizedBox(height: 24),

              // Sekcja: Dane osobowe
              _buildSectionTitle('Dane osobowe'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _fullNameController,
                label: 'Imię i nazwisko',
                hint: 'Podaj swoje imię i nazwisko',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _phoneController,
                label: 'Numer telefonu',
                hint: '+48 123 456 789',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _addressController,
                label: 'Adres zamieszkania',
                hint: 'Ulica, miasto, kod pocztowy',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Sekcja: Warunki mieszkaniowe
              _buildSectionTitle('Warunki mieszkaniowe'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _housingTypeController,
                label: 'Typ mieszkania',
                hint: 'np. mieszkanie, dom, kawalerka',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildCheckboxTile(
                title: 'Jestem właścicielem mieszkania/domu',
                value: _isHouseOwner,
                onChanged: (value) => setState(() => _isHouseOwner = value ?? false),
              ),

              _buildCheckboxTile(
                title: 'Mam ogród lub balkon',
                value: _hasYard,
                onChanged: (value) => setState(() => _hasYard = value ?? false),
              ),

              _buildCheckboxTile(
                title: 'Mam inne zwierzęta w domu',
                value: _hasOtherPets,
                onChanged: (value) => setState(() => _hasOtherPets = value ?? false),
              ),

              const SizedBox(height: 24),

              // Sekcja: Motywacja
              _buildSectionTitle('Motywacja'),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _motivationController,
                label: 'Dlaczego chcesz adoptować ${widget.pet.name}?',
                hint: 'Opisz swoją motywację do adopcji tego zwierzęcia...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'To pole jest wymagane';
                  }
                  if (value.trim().length < 50) {
                    return 'Opis powinien zawierać co najmniej 50 znaków';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _descriptionController,
                label: 'Dodatkowe informacje (opcjonalne)',
                hint: 'Możesz dodać więcej informacji o sobie...',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Przycisk wysłania
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
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
                    'Wyślij formularz adopcji',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Wysyłając formularz, wyrażasz chęć adopcji ${widget.pet.name}. '
                      'Schronisko skontaktuje się z Tobą w celu omówienia szczegółów i '
                      'umówienia spotkania z zwierzęciem.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: widget.pet.imageUrl.startsWith('data:image/')
                  ? Image.memory(
                base64Decode(widget.pet.imageUrl.split(',')[1]),
                fit: BoxFit.cover,
              )
                  : Image.network(
                widget.pet.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.pets, color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pet.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.pet.breed ?? widget.pet.typeDisplayName} • ${widget.pet.age} ${_formatAge(widget.pet.age)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.pet.shelterName != null)
                  Text(
                    widget.pet.shelterName!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryColor,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  String _formatAge(int age) {
    if (age == 1) return 'rok';
    if (age >= 2 && age <= 4) return 'lata';
    return 'lat';
  }
}