import 'package:car_sync/features/auth/pages/signup_page.dart';
import 'package:car_sync/features/dummy/pages/home_scr.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/auth/pages/verify_email_page.dart';
import 'package:car_sync/features/auth/pages/complete_profile_page.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_home_scr.dart';
import 'package:car_sync/features/customer/pages/home.dart';
import 'package:car_sync/main.dart';

class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final AuthService _authService = AuthService(
    clientId:
        '925167052954-qoinl478sq840p93jubk7jrc3o6162um.apps.googleusercontent.com',
  ); // client ID
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); // For forgot password
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isResetLoading = false; // For forgot password loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // Add this validation method
  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorAlert("Email Required", "Please enter your email address");
      return false;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showErrorAlert("Password Required", "Please enter your password");
      return false;
    }

    // Optional: Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorAlert("Invalid Email", "Please enter a valid email address");
      return false;
    }

    return true;
  }

  // Add this alert method
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
  void _showSuccessAlert(String title, String message) {
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
              color: Colors.green,
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

  // Show forgot password bottom sheet
  void _showForgotPasswordSheet() {
    _resetEmailController.clear(); // Clear previous input

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    40, // Added extra 40px bottom padding
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    "Reset Password",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Enter your email address and we'll send you a link to reset your password.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email field
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
                      controller: _resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
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
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: _isResetLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Send button
                      Expanded(
                        child: GradientButton(
                          text: _isResetLoading ? "" : "Send Link",
                          onPressed: _isResetLoading
                              ? null
                              : () => _handleForgotPassword(setSheetState),
                          height: 50,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),

                  // Added extra space at the bottom
                  const SizedBox(height: 40), // Additional space after buttons
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Handle forgot password
  Future<void> _handleForgotPassword(StateSetter setSheetState) async {
    // Validate email
    if (_resetEmailController.text.trim().isEmpty) {
      _showErrorAlert("Email Required", "Please enter your email address");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_resetEmailController.text.trim())) {
      _showErrorAlert("Invalid Email", "Please enter a valid email address");
      return;
    }

    setSheetState(() {
      _isResetLoading = true;
    });

    try {
      // Call your AuthService method for password reset
      await _authService.resetPassword(_resetEmailController.text.trim());

      // Close the bottom sheet
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        _showSuccessAlert(
          "Email Sent",
          "Password reset link has been sent to ${_resetEmailController.text.trim()}",
        );
      }
    } catch (e) {
      print("Password reset failed: $e");

      // Custom error messages
      String errorMessage = "Failed to send reset email. Please try again.";

      if (e.toString().contains('user-not-found')) {
        errorMessage = "No account found with this email address.";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "The email address is not valid.";
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = "Network error. Please check your internet connection.";
      }

      if (mounted) {
        _showErrorAlert("Reset Failed", errorMessage);
      }
    } finally {
      if (mounted) {
        setSheetState(() {
          _isResetLoading = false;
        });
      }
    }
  }

  // Update your login method
  Future<void> _handleLogin() async {
    // Validate inputs first
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Calling signInWithEmail");
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // If we get here, login was successful!
      if (user != null && mounted) {
        print("Login successful! User: ${user.uid}");

        // Get user role from Firestore
        String? userRole = await _authService.getCurrentUserRole();
        print("User role: $userRole");

        // Navigate to appropriate home screen based on role
        if (userRole == 'admin') {
          // Navigate to Admin Home Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          );
        } else if (userRole == 'technician') {
          // Navigate to Technician Home Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Default to Customer Home Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerHomePage()),
          );
        }
      }
    } catch (e) {
      print("Login failed with error: $e");

      // Check for email not verified
      if (e.toString().contains('email-not-verified')) {
        print("Email not verified, navigating to verification page");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerifyEmailPage(email: _emailController.text.trim()),
            ),
          );
        }
        return;
      }

      // Handle other Firebase errors
      String errorMessage = "Could not log in. Please check your credentials.";

      if (e.toString().contains('user-not-found')) {
        errorMessage = "No account found with this email address.";
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = "Incorrect password. Please try again.";
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = "The email address is not valid.";
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = "This account has been disabled.";
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = "Too many failed attempts. Try again later.";
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = "Network error. Check your connection.";
      }

      if (mounted) {
        _showErrorAlert("Login Failed", errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google Sign-In handler
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result['cancelled'] == true) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (result['success'] == true) {
        final needsProfileCompletion = result['needsProfileCompletion'];

        print("Google Sign-In successful");
        print("Needs profile completion: $needsProfileCompletion");

        if (needsProfileCompletion == true) {
          // Navigate to profile completion page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CompleteProfilePage(),
            ),
          );
        } else {
          // Profile complete - navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleBasedHomeLoader(),
            ),
          );
        }
      } else {
        throw result['error'] ?? Exception('Google Sign-In failed');
      }
    } catch (e) {
      print("Google Sign-In failed: $e");
      if (mounted) {
        _showErrorAlert(
          "Google Sign-In Failed",
          _authService.getErrorMessage(e),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          /// Background
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
                /// HERO LOGO
                const SizedBox(height: 60),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Hero(
                        tag: "appLogo",
                        child: Image.asset(
                          "assets/logo/white_carsync.png",
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                /// White Form Container
                Expanded(
                  flex: 4,
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
                          const SizedBox(height: 20),

                          /// EMAIL with Icon
                          Text(
                            "Email",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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

                          /// PASSWORD with Icon and visibility toggle
                          Text(
                            "Password",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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
                                hintText: "Enter your password",
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

                          /// Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _showForgotPasswordSheet, // Updated to show bottom sheet
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                "Forgot password?",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// LOGIN BUTTON
                          Center(
                            child: GradientButton(
                              text: "LOGIN",
                              width: double.infinity,
                              onPressed: _handleLogin,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Divider with "Or"
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Colors.grey),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  "Or",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Colors.grey),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// Google Sign In Button
                          Center(
                            child: InkWell(
                              onTap: _handleGoogleSignIn,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/logo/google_logo.png",
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Sign in with Google",
                                      style: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
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
                                      builder: (context) => const SignUpPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Sign up",
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
