// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final String currentPassword = _currentPasswordController.text;
    final String newPassword = _newPasswordController.text;

    // TODO: Implement the change password logic in FirebaseService
    final String? error = await _firebaseService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah. Silakan login kembali.'),
            backgroundColor: Colors.green,
          ),
        );
        // Logout and navigate to login screen
        await _firebaseService.logoutUser();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ganti Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_currentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_currentPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Password saat ini tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_newPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                   suffixIcon: IconButton(
                    icon: Icon(_newPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password minimal harus 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock_clock),
                   suffixIcon: IconButton(
                    icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Konfirmasi password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Ubah Password', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
