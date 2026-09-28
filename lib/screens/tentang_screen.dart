// lib/screens/tentang_screen.dart (FINAL & STABLE)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'token_management_screen.dart';
import 'transaksi_history_screen.dart';
import 'modal_kewajiban_screen.dart'; // Import added

class TentangPageData {
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic> umkmProfile;
  TentangPageData({required this.userProfile, required this.umkmProfile});
}

class TentangScreen extends StatefulWidget {
  const TentangScreen({super.key});

  @override
  State<TentangScreen> createState() => _TentangScreenState();
}

class _TentangScreenState extends State<TentangScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<TentangPageData?> _pageDataFuture;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  Future<TentangPageData?> _loadPageData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    
    // Assume the user of this screen is the owner
    final umkmProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (umkmProfile == null) return null; // Can't build screen without profile

    // The user profile is the same as the UMKM profile for the owner
    return TentangPageData(userProfile: umkmProfile, umkmProfile: umkmProfile);
  }

  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);

    if (title == 'Tentang') return;

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
      case 'Pengaturan':
        destination = const PengaturanScreen();
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

  Widget _buildAppDrawer(Map<String, dynamic> umkmProfile) {
    final userName = umkmProfile['pemilik'] ?? 'Pemilik';
    final umkmName = umkmProfile['namaBadanUsaha'] ?? 'UMKM';

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
          _buildDrawerItem(context, 'Beranda', Icons.home, false),
          _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, false),
          _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, false),
          _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
          _buildDrawerItem(context, 'Laporan', Icons.list_alt, false),
          _buildDrawerItem(context, 'Pengaturan', Icons.settings, false),
          _buildDrawerItem(context, 'Tentang', Icons.info_outline, true), // Active
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TentangPageData?>(
      future: _pageDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Tentang Usaha', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.deepOrange, iconTheme: const IconThemeData(color: Colors.white)),
            body: Center(child: Text('Gagal memuat informasi usaha.', style: GoogleFonts.poppins())),
          );
        }

        final pageData = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Tentang Usaha', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: _buildAppDrawer(pageData.umkmProfile),
          body: _buildTentangBody(pageData.umkmProfile),
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
