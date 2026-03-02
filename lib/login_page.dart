import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Max width for web
    final contentWidth = screenWidth > 600 ? 500.0 : screenWidth;

    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.png", fit: BoxFit.cover),
          ),

          /// Dark overlay
          Container(color: Colors.black.withOpacity(0.6)),

          /// Centered Content
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: [
                  const Spacer(),

                  /// Logo
                  Image.asset("assets/logo/white_carsync.png", height: 140),

                  const SizedBox(height: 10),

                  /*const Text(
                    "CARSYNC",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),*/
                  const Spacer(),

                  /// Bottom Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 100,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF293C54), Color(0xFF366A96)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.transparent, // IMPORTANT
                                shadowColor:
                                    Colors.transparent, // Remove default shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "LOGIN",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF2F4F6F),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                                "SIGN UP",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 1, 60, 128),
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
