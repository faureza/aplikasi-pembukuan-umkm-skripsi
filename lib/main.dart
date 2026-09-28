import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:umkmjambi/firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pembukuan UMKM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreenWrapper(),
    );
  }
}

// 1. Widget untuk menampilkan Splash Screen selama 2 detik
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // [FIX] Hanya navigasi ke OnboardingScreen, tanpa callback.
      // Navigasi selanjutnya ditangani oleh OnboardingScreen itu sendiri.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI Splash Screen (tidak berubah)
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Pembukuan UMKM",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. AuthGate untuk memeriksa status login setelah onboarding
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika sesi login ada, arahkan ke RoleRouter
        if (snapshot.hasData) {
          return const RoleRouter();
        }
        // Jika tidak ada sesi, arahkan ke LoginScreen
        return const LoginScreen();
      },
    );
  }
}
