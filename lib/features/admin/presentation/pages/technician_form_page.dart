import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicianFormPage extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? existingData;

  const TechnicianFormPage({
    super.key,
    this.documentId,
    this.existingData,
  });

  @override
  State<TechnicianFormPage> createState() => _TechnicianFormPageState();
}

class _TechnicianFormPageState extends State<TechnicianFormPage> {
  final AuthService _authService = AuthService(
    clientId:
        '925167052954-qoinl478sq840p93jubk7jrc3o6162um.apps.googleusercontent.com',
  );

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workshopIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool get _isEdit => widget.documentId != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit && widget.existingData != null) {
      final data = widget.existingData!;
      _fullNameController.text = (data['fullName'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _workshopIdController.text = (data['workshopId'] ?? '').toString();

      final dob = data['dateOfBirth'];
      if (dob is Timestamp) {
        _selectedDate = dob.toDate();
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workshopIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateInputs() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorAlert("Name Required", "Please enter technician full name");
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorAlert("Email Required", "Please enter technician email");
      return false;
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorAlert("Invalid Email", "Please enter a valid email address");
      return false;
    }

    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phone.length < 10) {
      _showErrorAlert("Invalid Phone", "Please enter a valid phone number");
      return false;
    }

    if (_workshopIdController.text.trim().isEmpty) {
      _showErrorAlert("Workshop Required", "Please enter workshop ID");
      return false;
    }

    if (_selectedDate == null) {
      _showErrorAlert("Date of Birth Required", "Please select date of birth");
      return false;
    }

    final today = DateTime.now();
    int age = today.year - _selectedDate!.year;
    if (today.month < _selectedDate!.month ||
        (today.month == _selectedDate!.month &&
            today.day < _selectedDate!.day)) {
      age--;
    }

    if (age < 18) {
      _showErrorAlert("Age Restriction", "Technician must be at least 18 years old");
      return false;
    }

    if (!_isEdit) {
      if (_passwordController.text.isEmpty) {
        _showErrorAlert("Password Required", "Please enter password");
        return false;
      }

      if (_passwordController.text.length < 6) {
        _showErrorAlert("Weak Password", "Password must be at least 6 characters");
        return false;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorAlert("Password Mismatch", "Passwords do not match");
        return false;
      }
    }

    return true;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.documentId)
            .update({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
          'dateOfBirth': Timestamp.fromDate(_selectedDate!),
          'workshopId': _workshopIdController.text.trim(),
          'role': 'technician',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _authService.technicianSignUpByAdmin(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
          dateOfBirth: _selectedDate!,
          workshopId: _workshopIdController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Technician updated successfully'
                : 'Technician account created successfully',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showErrorAlert('Failed', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Technician' : 'Add Technician';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Full Name'),
                const SizedBox(height: 8),
                _textField(
                  controller: _fullNameController,
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 18),

                _label('Email'),
                const SizedBox(height: 8),
                _textField(
                  controller: _emailController,
                  hint: 'Enter email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isEdit,
                ),
                const SizedBox(height: 18),

                _label('Phone Number'),
                const SizedBox(height: 8),
                _textField(
                  controller: _phoneController,
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),

                _label('Date of Birth'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Select date of birth'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                _label('Workshop ID'),
                const SizedBox(height: 8),
                _textField(
                  controller: _workshopIdController,
                  hint: 'Enter workshop ID',
                  icon: Icons.store_mall_directory_outlined,
                ),

                if (!_isEdit) ...[
                  const SizedBox(height: 18),
                  _label('Password'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _passwordController,
                    hint: 'Create password',
                    icon: Icons.lock_outline,
                    obscure: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label('Confirm Password'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm password',
                    icon: Icons.lock_outline,
                    obscure: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                GradientButton(
                  text: _isEdit ? 'UPDATE TECHNICIAN' : 'CREATE TECHNICIAN',
                  width: double.infinity,
                  onPressed: _isLoading ? null : _handleSubmit,
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}