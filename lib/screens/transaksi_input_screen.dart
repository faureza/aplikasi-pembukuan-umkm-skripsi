// lib/screens/transaksi_input_screen.dart (FINAL & STABLE LOGOUT)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // [ADDED] For AuthGate navigation
import '../services/firebase_service.dart';
import 'transaksi_form_screen.dart';
import 'karyawan_transaksi_history_screen.dart';
import 'karyawan_tentang_screen.dart';

class TransaksiInputScreen extends StatefulWidget {
  const TransaksiInputScreen({super.key});

  @override
  State<TransaksiInputScreen> createState() => _TransaksiInputScreenState();
}

class _TransaksiInputScreenState extends State<TransaksiInputScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final List<Map<String, dynamic>> _penerimaanCategories = [
    {'title': 'Penjualan Produk', 'desc': 'Mencatat semua hasil penjualan.', 'icon': Icons.shopping_cart_outlined, 'jenis': 'Penerimaan'},
  ];

  final List<Map<String, dynamic>> _pengeluaranCategories = [
    {'title': 'Pembelian Bahan & Stok', 'desc': 'Pembelian bahan baku atau barang dagangan.', 'icon': Icons.inventory_2_outlined, 'jenis': 'Pengeluaran'},
    {'title': 'Biaya Operasional', 'desc': 'Biaya harian (listrik, transport, kebersihan).', 'icon': Icons.receipt_long_outlined, 'jenis': 'Pengeluaran'},
  ];

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _firebaseService.getUserProfile(FirebaseAuth.instance.currentUser!.uid);
  }

  // [FIXED] Using robust pushAndRemoveUntil for logout
  Future<void> _handleDrawerTap(String title) async {
    Navigator.pop(context);
    if (title == 'Catat Transaksi') return;

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
    if (title == 'Riwayat Transaksi') {
      destination = const KaryawanTransaksiHistoryScreen();
    } else if (title == 'Tentang') {
      destination = const KaryawanTentangScreen();
    }

    if (destination != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon) {
    bool isActive = title == 'Catat Transaksi';
    return ListTile(
      tileColor: isActive ? Colors.black.withOpacity(0.2) : null,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      onTap: () => _handleDrawerTap(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
           return Scaffold(
            appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.deepOrange, iconTheme: const IconThemeData(color: Colors.white)),
            body: const Center(child: Text('Gagal memuat profil karyawan.')),
          );
        }

        final karyawanProfile = snapshot.data!;
        final String userName = karyawanProfile['name'] ?? 'Karyawan';
        final String umkmName = karyawanProfile['namaBadanUsaha'] ?? 'Nama UMKM tidak ditemukan';
        final String? idUmkmPemilik = karyawanProfile['id_umkm_pemilik'];

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text('Catat Transaksi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          drawer: Drawer(
            child: Container(
              color: Colors.deepOrange,
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text('Hi, $userName', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                    accountEmail: Text(umkmName, style: GoogleFonts.poppins(color: Colors.white70)),
                    currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
                    decoration: const BoxDecoration(color: Colors.deepOrange),
                  ),
                  _buildDrawerItem(context, 'Catat Transaksi', Icons.edit_document),
                  _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history),
                  _buildDrawerItem(context, 'Tentang', Icons.info_outline),
                  const Spacer(),
                  ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.white), title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)), onTap: () => _handleDrawerTap('Logout')),
                  Padding(padding: const EdgeInsets.all(16.0), child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Penerimaan / Pemasukan', Icons.arrow_downward, Colors.green),
                ..._penerimaanCategories.map((cat) => _buildCategoryCard(cat, idUmkmPemilik)).toList(),
                const SizedBox(height: 20),
                _buildSectionHeader('Pengeluaran / Biaya', Icons.arrow_upward, Colors.red),
                ..._pengeluaranCategories.map((cat) => _buildCategoryCard(cat, idUmkmPemilik)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87))]),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, String? idUmkmPemilik) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: Icon(category['icon'], size: 40, color: Colors.deepOrange.shade700),
          title: Text(category['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          subtitle: Text(category['desc'], style: GoogleFonts.poppins(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (idUmkmPemilik == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuat transaksi. Akun tidak terhubung ke UMKM.')));
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransaksiFormScreen(
                  kategori: category['title'],
                  jenis: category['jenis'],
                  id_umkm_pemilik: idUmkmPemilik,
                  userRole: 'karyawan',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
