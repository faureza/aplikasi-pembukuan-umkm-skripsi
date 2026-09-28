// lib/screens/auth_gate.dart (KODE FINAL)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_router.dart'; // Import RoleRouter

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan state login Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // State 1: Menunggu koneksi (Loading)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // State 2: User sudah login (User != null)
        if (snapshot.hasData && snapshot.data != null) {
          // Jika sudah login, serahkan ke RoleRouter untuk menentukan screen
          return const RoleRouter();
        }

        // State 3: User belum login (User == null)
        // RoleRouter akan mengarahkannya ke LoginScreen
        return const RoleRouter();
      },
    );
  }
}