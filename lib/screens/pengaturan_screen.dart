// lib/screens/pengaturan_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
// Import untuk navigasi Drawer
import 'laporan_screen.dart';
import 'token_management_screen.dart';
import 'transaksi_history_screen.dart';
import 'tentang_screen.dart'; 
import 'change_password_screen.dart';
import 'modal_kewajiban_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _namaPemilikController = TextEditingController();
  final _namaUsahaController = TextEditingController();

  bool _isLoading = true;
  String _userId = '';

  String _namaUsahaHeader = 'Memuat Nama Usaha...';
  String _userNameHeader = 'Pemilik';

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  @override
  void dispose() {
    _namaPemilikController.dispose();
    _namaUsahaController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadProfileData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data: Anda tidak login.')),
        );
        setState(() => _isLoading = false);
      }
      return null;
    }

    _userId = currentUser.uid;
    final profile = await _firebaseService.getUserProfile(_userId);

    if (mounted) {
      if (profile != null) {
        _namaPemilikController.text = profile['pemilik'] ?? '';
        _namaUsahaController.text = profile['namaBadanUsaha'] ?? '';

        _namaUsahaHeader = profile['namaBadanUsaha'] ?? 'UMKM Jambi';
        _userNameHeader = profile['pemilik'] ?? currentUser.email?.split('@').first ?? 'Pemilik';
      }
      setState(() => _isLoading = false);
    }
    return profile;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newProfileData = {
        'pemilik': _namaPemilikController.text.trim(),
        'namaBadanUsaha': _namaUsahaController.text.trim(),
      };

      bool success = await _firebaseService.updateUserProfile(_userId, newProfileData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui.')),
          );
          setState(() {
            _userNameHeader = newProfileData['pemilik']!;
            _namaUsahaHeader = newProfileData['namaBadanUsaha']!;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memperbarui profil. Coba lagi nanti.')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);

    if (title == 'Pengaturan') return;

    if (title == 'Logout') {
      _firebaseService.logoutUser();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    Widget? destination;
    switch (title) {
      case 'Beranda':
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Input Modal & Kewajiban':
        destination = const ModalKewajibanScreen();
        break;
      case 'Kelola Akses Karyawan':
        destination = const TokenManagementScreen();
        break;
      case 'Riwayat Transaksi':
        destination = const TransaksiHistoryScreen();
        break;
      case 'Laporan':
        destination = const LaporanScreen();
        break;
      case 'Tentang':
        destination = const TentangScreen();
        break;
    }

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, bool isActive) {
    return ListTile(
      tileColor: isActive ? Colors.black.withOpacity(0.2) : null,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      onTap: () => _handleDrawerNavigation(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Pengaturan Akun', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: Drawer(
            child: Container(
              color: Colors.deepOrange,
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text('Hi, $_userNameHeader', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                    accountEmail: Text(_namaUsahaHeader, style: GoogleFonts.poppins(color: Colors.white70)),
                    currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
                    decoration: const BoxDecoration(color: Colors.deepOrange),
                  ),
                  _buildDrawerItem(context, 'Beranda', Icons.home, false),
                  _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, false),
                  _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, false),
                  _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
                  _buildDrawerItem(context, 'Laporan', Icons.list_alt, false),
                  _buildDrawerItem(context, 'Pengaturan', Icons.settings, true),
                  _buildDrawerItem(context, 'Tentang', Icons.info_outline, false),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.white),
                    title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
                    onTap: () => _handleDrawerNavigation('Logout'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Profil Pemilik',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _namaPemilikController,
                          decoration: InputDecoration(
                            labelText: 'Nama Pemilik',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama pemilik tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Informasi Usaha',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _namaUsahaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Usaha',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.store),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama usaha tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Simpan Perubahan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepOrange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Ganti Password', style: GoogleFonts.poppins(color: Colors.deepOrange, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
