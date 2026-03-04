import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:car_sync/features/auth/pages/verify_email_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService(
    clientId: '925167052954-qoinl478sq840p93jubk7jrc3o6162um.apps.googleusercontent.com',
  ); // client ID 
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Date of birth
  DateTime? _selectedDate;

  // UI states
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validation methods
  bool _validateInputs() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorAlert("Name Required", "Please enter your full name");
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorAlert("Email Required", "Please enter your email address");
      return false;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorAlert("Invalid Email", "Please enter a valid email address");
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showErrorAlert("Phone Required", "Please enter your phone number");
      return false;
    }

    // Basic phone validation (10 digits)
    if (_phoneController.text.trim().length < 10) {
      _showErrorAlert(
        "Invalid Phone",
        "Please enter a valid 10-digit phone number",
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

    // Age validation (must be at least 18 years old)
    final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
    if (age < 18) {
      _showErrorAlert(
        "Age Restriction",
        "You must be at least 18 years old to sign up",
      );
      return false;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorAlert("Password Required", "Please enter a password");
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showErrorAlert(
        "Weak Password",
        "Password must be at least 6 characters",
      );
      return false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showErrorAlert("Confirm Password", "Please confirm your password");
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorAlert("Password Mismatch", "Passwords do not match");
      return false;
    }

    if (!_acceptTerms) {
      _showErrorAlert(
        "Terms Required",
        "Please accept the terms and conditions",
      );
      return false;
    }

    return true;
  }

  // Show error alert
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
                "OK",
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show success message
  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: Text(
            message,
            style: GoogleFonts.poppins(),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login after success
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginFormPage(),
                  ),
                );
              },
              child: Text(
                "LOGIN NOW",
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Date picker function
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Default to 18 years ago
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Handle sign up
  Future<void> _handleSignUp() async {
    if (!_validateInputs()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      // Create user in Firebase Auth and save data to Firestore
      final user = await _authService.customerSignUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDate!,
      );

      // In _handleSignUp method, after successful signup
      if (user != null && mounted) {
        // Navigate to verification page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyEmailPage(email: _emailController.text.trim()),
          ),
        );
      }
    } catch (e) {
      print("Sign up failed: $e");

      String errorMessage = "Failed to create account. Please try again.";

      if (e.toString().contains('email-already-in-use')) {
        errorMessage =
            "This email is already registered. Please login instead.";
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "Password is too weak. Please use a stronger password.";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "The email address is not valid.";
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = "Network error. Please check your internet connection.";
      }
      if (mounted) {
        _showErrorAlert("Sign Up Failed", errorMessage);
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
      body: Stack(
        children: [
          /// Background (same as login page)
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),

          /// Overlay
          Container(color: Colors.black.withOpacity(0.6)),

          /// Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          /// Main Content
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                /// Back Button and Title
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Create Account",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// White Form Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          /// Full Name Field
                          Text(
                            "Full Name",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                                hintText: "Enter your full name",
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Email Field
                          Text(
                            "Email",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primary,
                                ),
                                hintText: "Enter your email",
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Phone Number Field
                          Text(
                            "Phone Number",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: AppColors.primary,
                                ),
                                hintText: "Enter your phone number",
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Date of Birth Field
                          Text(
                            "Date of Birth",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
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
                                borderRadius: BorderRadius.circular(12),
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
                                  const Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? "Select your date of birth"
                                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: _selectedDate == null
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Password Field
                          Text(
                            "Password",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                hintText: "Create a password",
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Confirm Password Field
                          Text(
                            "Confirm Password",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                hintText: "Confirm your password",
                                hintStyle: GoogleFonts.poppins(fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Terms and Conditions
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "I agree to the Terms & Conditions and Privacy Policy",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// Sign Up Button
                          Center(
                            child: GradientButton(
                              text: "SIGN UP",
                              width: double.infinity,
                              onPressed: _handleSignUp,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginFormPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Login",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
