import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Impor main.dart untuk mengakses AuthGate

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNext();
  }

  Future<void> _goToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Mengarahkan ke AuthGate untuk memeriksa status login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
