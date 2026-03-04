import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/features/auth/presentation/pages/signup_page.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'login_form_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom
      end: Offset.zero, // End at normal position
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth =
        screenWidth > 600 ? 500.0 : screenWidth;

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          SizedBox.expand(
            child: Image.asset(
              "assets/images/login_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Overlay
          Container(color: Colors.black.withOpacity(0.6)),

          /// Content
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: [
                  const Spacer(),

                  /// HERO LOGO
                  Hero(
                    tag: "appLogo",
                    child: Image.asset(
                      "assets/logo/white_carsync.png",
                      height: 140,
                    ),
                  ),

                  const Spacer(),

                  /// Animated Bottom Card
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 80,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        children: [
                          /// LOGIN BUTTON
                          GradientButton(
                            width: double.infinity,
                            text: "LOGIN",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginFormPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          /// SIGN UP BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SignUpPage(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "SIGN UP",
                                style: GoogleFonts.poppins(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}