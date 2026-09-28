// lib/screens/token_management_screen.dart (FINAL & STABLE)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:umkmjambi/screens/pengaturan_screen.dart';
import '../services/firebase_service.dart';
import 'transaksi_history_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'tentang_screen.dart';
import 'modal_kewajiban_screen.dart';

class TokenManagementScreen extends StatefulWidget {
  const TokenManagementScreen({super.key});

  @override
  State<TokenManagementScreen> createState() => _TokenManagementScreenState();
}

class _TokenManagementScreenState extends State<TokenManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String _currentToken = 'Memuat token...';
  bool _loading = false;
  String _namaUsaha = 'Memuat Nama Usaha...';
  String _userName = 'Pemilik';
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>?> _fetchProfileData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    final profile = await _firebaseService.getUserProfile(currentUser.uid);
    if (mounted) {
      setState(() {
        _namaUsaha = profile?['namaBadanUsaha'] ?? 'UMKM Jambi';
        _userName = profile?['pemilik'] ?? currentUser.email?.split('@').first ?? 'Pemilik';
      });
    }
    return profile;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveToken();
  }

  Future<void> _loadActiveToken() async {
    if(!mounted) return;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userId = currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _currentToken = 'Anda belum login.');
      return;
    }
    final existingToken = await _firebaseService.getActiveUmkmToken(userId);
    if (mounted && existingToken != null) {
      setState(() => _currentToken = existingToken);
    } else if (mounted && existingToken == null) {
      setState(() => _currentToken = 'Tekan tombol untuk membuat token.');
    }
  }

  Future<void> _generateToken() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Autentikasi gagal. Silakan login ulang.')));
      return;
    }
    setState(() => _loading = true);
    final result = await _firebaseService.generateUmkmToken(namaUsaha: _namaUsaha, userId: currentUser.uid);
    setState(() => _loading = false);
    if (mounted) {
      if (result != null && !result.contains('Error')) {
        setState(() => _currentToken = result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token baru berhasil dibuat!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat token: ${result ?? "Unknown Error"}')));
      }
    }
  }

  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);
    if (title == 'Kelola Akses Karyawan') return;

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
      case 'Riwayat Transaksi':
        destination = const TransaksiHistoryScreen();
        break;
      case 'Laporan':
        destination = const LaporanScreen();
        break;
      case 'Pengaturan':
        destination = const PengaturanScreen();
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('Pendaftaran Karyawan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
          ),
          drawer: Drawer(
            child: Container(
              color: Colors.deepOrange,
              child: Column(children: [
                UserAccountsDrawerHeader(
                  accountName: Text('Hi, $_userName', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                  accountEmail: Text(_namaUsaha, style: GoogleFonts.poppins(color: Colors.white70)),
                  currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
                  decoration: const BoxDecoration(color: Colors.deepOrange),
                ),
                _buildDrawerItem(context, 'Beranda', Icons.home, false),
                _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, false),
                _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, true),
                _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
                _buildDrawerItem(context, 'Laporan', Icons.list_alt, false),
                _buildDrawerItem(context, 'Pengaturan', Icons.settings, false),
                _buildDrawerItem(context, 'Tentang', Icons.info_outline, false),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.white),
                  title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
                  onTap: () => _handleDrawerNavigation('Logout'),
                ),
                Padding(padding: const EdgeInsets.all(16.0), child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))),
              ]),
            ),
          ),
          body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30.0), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Buat Token untuk $_namaUsaha', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Text('Kode Token Aktif:', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.deepOrange, width: 2), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(child: SelectableText(_currentToken, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                ]),
              ),
              const SizedBox(height: 30),
              Text('Token ini mengikat pendaftar baru ke UMKM Anda. Setelah token dibuat, berikan kodenya kepada Karyawan yang akan bertugas mencatat transaksi.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _generateToken,
                  icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.refresh, color: Colors.white),
                  label: Text('Buat Token Baru', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
              ),
            ],
          ))),
        );
      },
    );
  }
}
