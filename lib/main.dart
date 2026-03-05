import 'package:car_sync/features/auth/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_sync/features/auth/pages/login_form_page.dart';
import 'package:car_sync/features/dummy/pages/home_scr.dart';
import 'package:car_sync/features/splash/pages/video_splash_scr.dart';
import 'firebase_options.dart';
import 'package:car_sync/core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    return MaterialApp(
      title: 'Car Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
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
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  return const RoleBasedHomeLoader();
                }

                return const LoginPage();
              },
            ),
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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Failed to load user role'),
            ),
          );
        }

        final role = snapshot.data;

        if (role == 'admin') {
          return const HomeScreen();
        } else if (role == 'technician' || role == 'foreman') {
          return const HomeScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}