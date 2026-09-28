// lib/screens/karyawan_tentang_screen.dart (FINAL & STABLE LOGOUT)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // [ADDED] For AuthGate navigation
import '../services/firebase_service.dart';
import 'transaksi_input_screen.dart';
import 'karyawan_transaksi_history_screen.dart';

class KaryawanTentangScreen extends StatefulWidget {
  const KaryawanTentangScreen({super.key});

  @override
  State<KaryawanTentangScreen> createState() => _KaryawanTentangScreenState();
}

class _KaryawanTentangScreenState extends State<KaryawanTentangScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  late Future<Map<String, dynamic>?> _karyawanProfileFuture;
  Future<Map<String, dynamic>?>? _umkmProfileFuture;

  @override
  void initState() {
    super.initState();
    _karyawanProfileFuture = _loadKaryawanProfile();
  }

  Future<Map<String, dynamic>?> _loadKaryawanProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Pengguna tidak ditemukan.');
    final karyawanProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (karyawanProfile == null) throw Exception('Profil karyawan tidak ditemukan.');

    final ownerId = karyawanProfile['id_umkm_pemilik'] as String?;
    if (ownerId != null && ownerId.isNotEmpty) {
      _umkmProfileFuture = _firebaseService.getUserProfile(ownerId);
    } else {
      _umkmProfileFuture = Future.error(Exception('Akun Anda belum terhubung dengan UMKM.'));
    }

    return karyawanProfile;
  }

  // [FIXED] Using robust pushAndRemoveUntil for logout
  void _handleDrawerNavigation(String title) async {
    Navigator.pop(context);
    if (title == 'Tentang') return;

    if (title == 'Logout') {
      await _firebaseService.logoutUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    Widget? destination;
    if (title == 'Catat Transaksi') {
      destination = const TransaksiInputScreen();
    } else if (title == 'Riwayat Transaksi') {
      destination = const KaryawanTransaksiHistoryScreen();
    }
    if (destination != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  Widget _buildAppDrawer(Map<String, dynamic> karyawanProfile) {
    final String userName = karyawanProfile['name'] ?? 'Karyawan';
    final String umkmName = karyawanProfile['namaBadanUsaha'] ?? 'UMKM';
    return Drawer(
      child: Container(
        color: Colors.deepOrange,
        child: Column(children: [
          UserAccountsDrawerHeader(
            accountName: Text('Hi, $userName', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            accountEmail: Text(umkmName, style: GoogleFonts.poppins(color: Colors.white70)),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
            decoration: const BoxDecoration(color: Colors.deepOrange),
          ),
          _buildDrawerItem(context, 'Catat Transaksi', Icons.edit_document, false),
          _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
          _buildDrawerItem(context, 'Tentang', Icons.info_outline, true),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.white),
            title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () => _handleDrawerNavigation('Logout'),
          ),
          Padding(padding: const EdgeInsets.all(16.0), child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))),
        ]),
      ),
    );
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _karyawanProfileFuture,
      builder: (context, karyawanSnapshot) {
        if (karyawanSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (karyawanSnapshot.hasError || !karyawanSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.deepOrange, iconTheme: const IconThemeData(color: Colors.white)),
            body: Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(karyawanSnapshot.error.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center),
            )),
          );
        }

        final karyawanProfile = karyawanSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Tentang UMKM', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: _buildAppDrawer(karyawanProfile),
          body: FutureBuilder<Map<String, dynamic>?>(
            future: _umkmProfileFuture,
            builder: (context, umkmSnapshot) {
              if (umkmSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (umkmSnapshot.hasError || !umkmSnapshot.hasData) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(umkmSnapshot.error.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center),
                ));
              }

              final umkmData = umkmSnapshot.data!;
              return _buildTentangBody(umkmData);
            },
          ),
        );
      },
    );
  }

  Widget _buildTentangBody(Map<String, dynamic> data) {
    final noTelp = (data['noTelp'] == null || data['noTelp'] == 'N/A') ? '-' : data['noTelp'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text(data['namaBadanUsaha'] ?? 'Nama Usaha Tidak Tersedia', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            if (data['deskripsi'] != null && data['deskripsi'].isNotEmpty && data['deskripsi'] != 'N/A') ...[
              const SizedBox(height: 8),
              Center(child: Text(data['deskripsi'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700), textAlign: TextAlign.center)),
            ],
            const SizedBox(height: 20),
            const Divider(),
            _buildInfoTile(Icons.business, 'Jenis Usaha', data['usaha'] ?? '-'),
            _buildInfoTile(Icons.person_pin_rounded, 'Nama Pemilik', data['pemilik'] ?? '-'),
            _buildInfoTile(Icons.phone, 'No. Telepon', noTelp),
            _buildInfoTile(Icons.location_on, 'Alamat', data['alamat'] ?? '-'),
            _buildInfoTile(Icons.map_outlined, 'Kecamatan', data['kecamatan'] ?? '-'),
            _buildInfoTile(Icons.map, 'Kelurahan', data['kelurahan'] ?? '-'),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      leading: Icon(icon, color: Colors.deepOrange, size: 30),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 15)),
    );
  }
}
