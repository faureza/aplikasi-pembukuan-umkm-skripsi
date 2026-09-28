import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_karyawan_screen.dart'; 
import 'register_pemilik_screen.dart'; 

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendaftaran Akun'),
        backgroundColor: Colors.deepOrange,
        // [PERBAIKAN] Menambahkan foregroundColor untuk mengubah warna teks dan ikon menjadi putih
        foregroundColor: Colors.white, 
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anda Mendaftar Sebagai?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Tombol 1: DAFTAR SEBAGAI PEMILIK
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPemilikScreen()));
                  },
                  icon: const Icon(Icons.store, color: Colors.white),
                  label: Text('Pemilik UMKM', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol 2: DAFTAR SEBAGAI KARYAWAN
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterKaryawanScreen()));
                  },
                  icon: const Icon(Icons.person, color: Colors.deepOrange),
                  label: Text('Karyawan', style: GoogleFonts.poppins(color: Colors.black, fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}