import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/dummy/pages/home_scr.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final AuthService _authService = AuthService(
    clientId:
        '925167052954-qoinl478sq840p93jubk7jrc3o6162um.apps.googleusercontent.com',
  ); // client ID
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showErrorAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs() {
    // Phone number: must be exactly 10 digits, no other characters
    String phone = _phoneController.text.trim().replaceAll(
      RegExp(r'\D'),
      '',
    ); // Remove non-digits
    if (phone.isEmpty) {
      _showErrorAlert("Phone Required", "Please enter your phone number");
      return false;
    }
    if (phone.length != 10) {
      _showErrorAlert(
        "Invalid Phone",
        "Please enter a valid 10-digit phone number (numbers only)",
      );
      return false;
    }

    if (_selectedDate == null) {
      _showErrorAlert(
        "Date of Birth Required",
        "Please select your date of birth",
      );
      return false;
    }

    // Precise age calculation
    final today = DateTime.now();
    final birthDate = _selectedDate!;
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    if (age < 18) {
      _showErrorAlert("Age Restriction", "You must be at least 18 years old");
      return false;
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.completeUserProfile(
        phone: _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
        dateOfBirth: _selectedDate!,
      );

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      _showErrorAlert("Error", "Failed to save profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome! We need a little more information to complete your profile:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Phone Number
            Text(
              'Phone Number',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date of Birth
            Text(
              'Date of Birth',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Select your date of birth'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: GoogleFonts.poppins(
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            Center(
              child: GradientButton(
                text: 'COMPLETE PROFILE',
                onPressed: _isLoading ? null : _handleSubmit,
                width: double.infinity,
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
