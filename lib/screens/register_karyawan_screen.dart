import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class RegisterKaryawanScreen extends StatefulWidget {
  const RegisterKaryawanScreen({super.key});

  @override
  State<RegisterKaryawanScreen> createState() => _RegisterKaryawanScreenState();
}

class _RegisterKaryawanScreenState extends State<RegisterKaryawanScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _umkmTokenController = TextEditingController();

  bool _loading = false;

  Future<void> _submitKaryawan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final error = await _firebaseService.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      noTelp: _phoneController.text.trim(),
      nik: '', // NIK tidak lagi diwajibkan untuk karyawan
      umkmToken: _umkmTokenController.text.trim(),
    );

    setState(() => _loading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pendaftaran Gagal: $error')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran Berhasil! Silakan Login.')));
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Karyawan'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Masukkan Data Pribadi dan Token UMKM',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const Divider(color: Colors.deepOrange),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap Karyawan', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon Aktif', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 9) ? 'Nomor telepon tidak valid' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (Untuk Login)', border: OutlineInputBorder()),
                  validator: (v) => (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata Sandi', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 25),

                TextFormField(
                  controller: _umkmTokenController,
                  // [PERBAIKAN] Menghapus textAlign: TextAlign.center
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Token Rahasia dari Pemilik',
                    prefixIcon: Icon(Icons.vpn_key),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Token wajib diisi' : null,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitKaryawan,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Daftar Sebagai Karyawan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
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
