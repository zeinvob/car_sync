import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'package:car_sync/features/auth/presentation/pages/login_form_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final AuthService _authService = AuthService();
  bool _isResending = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Check every 3 seconds
    Future.delayed(const Duration(seconds: 3), _checkVerification);
  }

  Future<void> _checkVerification() async {
    if (!mounted) return;
    
    setState(() => _isChecking = true);
    
    try {
      bool isVerified = await _authService.checkEmailVerification();
      
      if (isVerified && mounted) {
        // Email verified! Navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verified successfully! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginFormPage()),
          (route) => false,
        );
      } else if (mounted) {
        // Not verified yet, check again
        setState(() => _isChecking = false);
        _startPeriodicCheck();
      }
    } catch (e) {
      setState(() => _isChecking = false);
      _startPeriodicCheck();
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    
    try {
      await _authService.resendVerificationEmail();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email resent! Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to resend: ${_authService.getErrorMessage(e)}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  "Verify Your Email",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Instructions
                Text(
                  "We've sent a verification email to:",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    widget.email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Instructions
                Text(
                  "Please click the link in the email to verify your account. Once verified, you'll be automatically redirected to login.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Checking indicator
                if (_isChecking)
                  const CircularProgressIndicator(color: Colors.white),
                
                const SizedBox(height: 20),
                
                // Resend button
                GradientButton(
                  text: "Resend Email",
                  onPressed: _isResending ? null : _resendVerification,
                  width: double.infinity,
                  height: 50,
                ),
                
                const SizedBox(height: 16),
                
                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginFormPage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    "Back to Login",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}