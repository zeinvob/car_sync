import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:car_sync/features/auth/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_sync/features/dummy/pages/home_scr.dart';
import 'package:car_sync/features/customer/pages/home.dart';
import 'package:car_sync/features/splash/pages/video_splash_scr.dart';
import 'package:car_sync/core/services/auth_service.dart';
import 'package:car_sync/features/admin/presentation/pages/admin_home_scr.dart';
import 'package:car_sync/core/constants/app_colors.dart';
import 'package:car_sync/core/theme/theme_controller.dart';
import 'package:car_sync/core/services/auth_nav_flag.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:car_sync/core/services/notification_service.dart';
import 'package:car_sync/core/theme/admin_theme_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Car Sync',
          debugShowCheckedModeBanner: false,
          themeMode: mode,

          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.gradientEnd,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1A1A1A),
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: const Color(0xFF0F1115),
            cardColor: const Color(0xFF171A21),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.gradientEnd,
              surface: Color(0xFF171A21),
              onSurface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF171A21),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          home: _showSplash
              ? VideoSplashScreen(
                  onVideoFinished: () {
                    setState(() {
                      _showSplash = false;
                    });
                  },
                )
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasData) {
                      return const RoleBasedHomeLoader();
                    }

                    return FutureBuilder<bool>(
                      future: AuthNavFlag.wasSignedOutRecently(),
                      builder: (context, flagSnap) {
                        if (flagSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final signedOutRecently = flagSnap.data ?? false;

                        if (signedOutRecently) {
                          return const LoginFormPage();
                        }

                        return const LoginPage();
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class RoleBasedHomeLoader extends StatelessWidget {
  const RoleBasedHomeLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<String?>(
      future: authService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Failed to load user role')),
          );
        }

        final role = snapshot.data;

        if (role == 'admin') {
          return const AdminThemeWrapper(child: AdminHomeScreen());
        } else if (role == 'technician' || role == 'foreman') {
          return const HomeScreen();
        } else {
          return const CustomerHomePage();
        }
      },
    );
  }
}

class AdminThemeWrapper extends StatelessWidget {
  final Widget child;

  const AdminThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeController.isDark,
      builder: (context, isDark, _) {
        return Theme(
          data: isDark
              ? ThemeData(
                  brightness: Brightness.dark,
                  fontFamily: 'Poppins',
                  primaryColor: AppColors.primary,
                  scaffoldBackgroundColor: const Color(0xFF0F1115),
                  cardColor: const Color(0xFF171A21),
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary,
                    secondary: AppColors.gradientEnd,
                    surface: Color(0xFF171A21),
                    onSurface: Colors.white,
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF171A21),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                )
              : ThemeData(
                  brightness: Brightness.light,
                  fontFamily: 'Poppins',
                  primaryColor: AppColors.primary,
                  scaffoldBackgroundColor: const Color(0xFFF3F4F6),
                  cardColor: Colors.white,
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    secondary: AppColors.gradientEnd,
                    surface: Colors.white,
                    onSurface: Color(0xFF1A1A1A),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF1A1A1A),
                    elevation: 0,
                  ),
                ),
          child: child,
        );
      },
    );
  }
}
