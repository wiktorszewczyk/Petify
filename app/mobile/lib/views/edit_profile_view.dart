import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/user_service.dart';
import '../styles/colors.dart ';

class EditProfileView extends StatefulWidget {
  final User user;

  const EditProfileView({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _profileImage;
  bool _isImageLoading = false;
  late final bool _canEditFirstName;
  late final bool _canEditLastName;
  late final bool _canEditBirthDate;
  late final bool _canEditGender;

  bool _isLoading = false;
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _emailController.text = widget.user.email ?? '';
    _phoneController.text = widget.user.phoneNumber ?? '';
    _selectedGender = widget.user.gender;
    _selectedBirthDate = widget.user.birthDate;
    _canEditFirstName = widget.user.firstName == null;
    _canEditLastName = widget.user.lastName == null;
    _canEditBirthDate = widget.user.birthDate == null;
    _canEditGender = widget.user.gender == null;
    if (widget.user.hasProfileImage) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    setState(() => _isImageLoading = true);
    final url = await UserService().getProfileImage();
    if (mounted) {
      setState(() {
        _profileImage = url;
        _isImageLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
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

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _isImageLoading = true);
    final success = await UserService().uploadProfileImage(picked.path);
    if (success) {
      await _loadProfileImage();
    } else if (mounted) {
      setState(() => _isImageLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się przesłać zdjęcia')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_emailController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj email lub numer telefonu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserService();

      final updateData = <String, dynamic>{};

      if (_canEditFirstName) {
        updateData['firstName'] = _firstNameController.text.trim();
      }
      if (_canEditLastName) {
        updateData['lastName'] = _lastNameController.text.trim();
      }
      if (_canEditGender && _selectedGender != null) {
        updateData['gender'] = _selectedGender;
      }
      if (_canEditBirthDate && _selectedBirthDate != null) {
        updateData['birthDate'] =
        _selectedBirthDate!.toIso8601String().split('T')[0];
      }

      if (_emailController.text.trim().isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }

      if (_phoneController.text.trim().isNotEmpty) {
        updateData['phoneNumber'] = _phoneController.text.trim();
      }

      final response = await userService.updateUserProfile(updateData);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil został zaktualizowany pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd: ${response['error'] ?? 'Nieznany błąd'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas aktualizacji profilu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edytuj profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Zapisz',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      backgroundImage: _profileImage != null
                          ? (_profileImage!.startsWith('http') || _profileImage!.startsWith('data:'))
                          ? NetworkImage(_profileImage!) as ImageProvider
                          : FileImage(File(_profileImage!))
                          : null,
                      child: _profileImage == null
                          ? Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primaryColor,
                      )
                          : null,
                    ),
                    if (_isImageLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _changeProfileImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionHeader('Podstawowe informacje'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _firstNameController,
                label: 'Imię',
                icon: Icons.person_outline,
                enabled: _canEditFirstName,
                validator: _canEditFirstName
                    ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Imię jest wymagane';
                  }
                  if (value.trim().length < 2) {
                    return 'Imię musi mieć co najmniej 2 znaki';
                  }
                  return null;
                }
                    : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _lastNameController,
                label: 'Nazwisko',
                icon: Icons.person_outline,
                enabled: _canEditLastName,
                validator: _canEditLastName
                    ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwisko jest wymagane';
                  }
                  if (value.trim().length < 2) {
                    return 'Nazwisko musi mieć co najmniej 2 znaki';
                  }
                  return null;
                }
                    : null,
              ),
              const SizedBox(height: 16),

              _buildDateField(),
              const SizedBox(height: 16),

              _buildGenderField(),
              const SizedBox(height: 30),

              _buildSectionHeader('Informacje kontaktowe'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
                      return 'Podaj prawidłowy adres email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Numer telefonu',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(value.replaceAll(' ', ''))) {
                      return 'Podaj prawidłowy numer telefonu';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : Text(
                    'Zapisz zmiany',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _canEditBirthDate ? _selectBirthDate : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: AppColors.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data urodzenia',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                        : 'Wybierz datę urodzenia',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: _canEditBirthDate
                          ? (_selectedBirthDate != null ? Colors.black87 : Colors.grey[500])
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            _canEditBirthDate ? Icon(Icons.chevron_right, color: Colors.grey[400]) : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    if (!_canEditGender && _selectedGender != null) {
      final genderLabel = _selectedGender == 'MALE'
          ? 'Mężczyzna'
          : _selectedGender == 'FEMALE'
          ? 'Kobieta'
          : 'Inne';
      return _buildTextField(
        controller: TextEditingController(text: genderLabel),
        label: 'Płeć',
        icon: Icons.person_outline,
        enabled: false,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primaryColor),
              const SizedBox(width: 16),
              Text(
                'Płeć',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenderOption('Mężczyzna', 'MALE')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderOption('Kobieta', 'FEMALE')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderOption('Inne', 'OTHER')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _selectedGender == value;

    return InkWell(
      onTap: _canEditGender
          ? () {
        setState(() {
          _selectedGender = value;
        });
      }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primaryColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}