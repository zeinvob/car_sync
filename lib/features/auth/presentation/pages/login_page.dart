import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_sync/features/auth/presentation/pages/signup_page.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/widgets/gradient_button.dart';
import 'login_form_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 500.0 : screenWidth;

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
          // ignore: deprecated_member_use
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

                  /// Bottom Card
                  Container(
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
                        /// LOGIN BUTTON (Reusable)
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
                                  builder: (_) => const SignUpPage(),
                                )
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}