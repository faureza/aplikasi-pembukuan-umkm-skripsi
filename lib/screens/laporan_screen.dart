// lib/screens/laporan_screen.dart (FINAL & STABLE)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'laba_rugi_content.dart';
import 'arus_kas_content.dart';
import 'neraca_content.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pdf_service.dart';
import 'token_management_screen.dart';
import 'transaksi_history_screen.dart';
import 'pengaturan_screen.dart';
import 'tentang_screen.dart';
import 'modal_kewajiban_screen.dart';

class LaporanScreen extends StatefulWidget {
  final String initialTab;

  const LaporanScreen({super.key, this.initialTab = 'Laba Rugi'});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<String> _tabs = ['Laba Rugi', 'Arus Kas', 'Neraca'];

  String _selectedPeriode = 'Semua Data';
  final List<String> _availablePeriode = ['Semua Data', 'Bulan Ini', 'Bulan Lalu'];

  final FirebaseService _firebaseService = FirebaseService();
  final PdfService _pdfService = PdfService();

  String _userName = 'Pengguna';
  String _namaUsaha = 'Tungku Nyai';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();

    int initialIndex = _tabs.indexOf(widget.initialTab);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final profile = await _firebaseService.getUserProfile(currentUser.uid);

    if (mounted && profile != null) {
      setState(() {
        _userName = profile['pemilik'] ?? currentUser.email?.split('@').first ?? 'Pemilik';
        _namaUsaha = profile['namaBadanUsaha'] ?? 'Tungku Nyai';
      });
    }
  }

  void _handlePrint() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat mencetak, pengguna tidak terautentikasi.')),
      );
      return;
    }

    final String currentTab = _tabs[_tabController.index];
    final String userId = currentUser.uid;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mempersiapkan dokumen untuk $currentTab...')),
    );

    switch (currentTab) {
      case 'Laba Rugi':
        _pdfService.generateAndPrintLabaRugi(
          periode: _selectedPeriode,
          userIdPemilik: userId,
          namaUsaha: _namaUsaha,
          pemilik: _userName,
        );
        break;
      case 'Arus Kas':
        _pdfService.generateAndPrintArusKas(
          periode: _selectedPeriode,
          userIdPemilik: userId,
          namaUsaha: _namaUsaha,
          pemilik: _userName,
        );
        break;
      case 'Neraca':
        _pdfService.generateAndPrintNeraca(
          periode: _selectedPeriode,
          userIdPemilik: userId,
          namaUsaha: _namaUsaha,
          pemilik: _userName,
        );
        break;
    }
  }

  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);

    if (title == 'Laporan') return;

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
  
  Widget _getBodyContent(String reportType) {
    switch (reportType) {
      case 'Laba Rugi':
        return LabaRugiContent(periode: _selectedPeriode);
      case 'Arus Kas':
        return ArusKasContent(periode: _selectedPeriode);
      case 'Neraca':
        return NeracaContent(periode: _selectedPeriode);
      default:
        return const Center(child: Text("Pilih jenis Laporan.", style: TextStyle(fontSize: 18)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Keuangan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            }
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white, 
          unselectedLabelColor: Colors.white70, 
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          tabs: _tabs.map((name) => Tab(text: name)).toList(),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.deepOrange,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('Hi, $_userName', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                accountEmail: Text(_namaUsaha, style: GoogleFonts.poppins(color: Colors.white70)),
                currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
                decoration: const BoxDecoration(color: Colors.deepOrange),
              ),
              _buildDrawerItem(context, 'Beranda', Icons.home, false),
              _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, false),
              _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, false),
              _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
              _buildDrawerItem(context, 'Laporan', Icons.list_alt, true),
              _buildDrawerItem(context, 'Pengaturan', Icons.settings, false),
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

      floatingActionButton: FloatingActionButton(
        onPressed: _handlePrint,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.print, color: Colors.white),
        tooltip: 'Cetak Laporan',
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Periode Laporan:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: _selectedPeriode,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  underline: Container(height: 2, color: Colors.deepOrange),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPeriode = newValue!;
                    });
                  },
                  items: _availablePeriode.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _getBodyContent('Laba Rugi'),
                _getBodyContent('Arus Kas'),
                _getBodyContent('Neraca'),
              ],
            ),
          ),
        ],
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
}