import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final error = await _firebaseService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      // Navigasi ditangani oleh RoleRouter, cukup tampilkan notifikasi.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login berhasil!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 100, color: Colors.deepOrange),
                const SizedBox(height: 20),
                Text(
                  'Masuk ke Akun',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Masuk', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: const Text('Belum punya akun? Daftar di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
