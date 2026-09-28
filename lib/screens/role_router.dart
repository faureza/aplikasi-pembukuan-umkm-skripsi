import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'dashboard_screen.dart';
import 'transaksi_input_screen.dart';
import 'login_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final User? user = FirebaseAuth.instance.currentUser;

    // [FIXED] Perubahan utama ada di sini.
    if (user == null) {
      // Jika user null saat RoleRouter pertama kali dibangun (karena timing issue),
      // tampilkan loading. AuthGate sudah menjamin bahwa widget ini hanya
      // akan dipanggil saat user terautentikasi, jadi ini adalah state sementara.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
      );
    }

    // Menggunakan StreamBuilder untuk mendengarkan perubahan pada dokumen pengguna.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firebaseService.userDocumentStream(user.uid),
      builder: (context, snapshot) {

        // KASUS 1: Menunggu koneksi atau data pertama.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
          );
        }

        // KASUS 2: Dokumen pengguna tidak ada.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Tampilkan loading, mungkin dokumen sedang dalam proses pembuatan.
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepOrange),
                  SizedBox(height: 10),
                  Text('Menunggu data pengguna...')
                ],
              ),
            ),
          );
        }

        // KASUS 3: Dokumen sudah ada, ambil perannya.
        final String? role = snapshot.data!.data()?['role'];

        // Arahkan berdasarkan peran.
        switch (role) {
          case 'pemilik':
            return const DashboardScreen();
          case 'karyawan':
            return const TransaksiInputScreen();
          default:
            // Jika peran tidak valid atau null, tetap tampilkan loading.
            // Ini memberikan waktu bagi stream untuk update jika ada keterlambatan.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
            );
        }
      },
    );
  }
}
