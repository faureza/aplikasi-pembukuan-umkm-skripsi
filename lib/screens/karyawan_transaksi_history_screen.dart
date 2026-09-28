// lib/screens/karyawan_transaksi_history_screen.dart (REVAMPED with Unified Tiles)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import 'transaksi_input_screen.dart';
import 'karyawan_tentang_screen.dart';

class KaryawanTransaksiHistoryScreen extends StatefulWidget {
  const KaryawanTransaksiHistoryScreen({super.key});

  @override
  State<KaryawanTransaksiHistoryScreen> createState() => _KaryawanTransaksiHistoryScreenState();
}

class _KaryawanTransaksiHistoryScreenState extends State<KaryawanTransaksiHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late Future<Map<String, dynamic>?> _profileFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _profileFuture = _firebaseService.getUserProfile(_currentUserId!);
    }
  }

  void _handleDrawerNavigation(String title) async {
    Navigator.pop(context);
    if (title == 'Riwayat Transaksi') return;

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
    } else if (title == 'Tentang') {
      destination = const KaryawanTentangScreen();
    }
    if (destination != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text('Sesi tidak valid. Silakan login ulang.', style: GoogleFonts.poppins())));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (profileSnapshot.hasError || !profileSnapshot.hasData || profileSnapshot.data == null) {
          return Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text('Gagal memuat profil karyawan.', style: GoogleFonts.poppins())));
        }
        
        final profile = profileSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Riwayat Transaksi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context), tooltip: 'Filter Tanggal')],
          ),
          drawer: _buildAppDrawer(profile),
          body: Column(children: [
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text('Filter: ${DateFormat('dd MMMM yyyy').format(_selectedDate!)}'),
                  onDeleted: () => setState(() => _selectedDate = null),
                  backgroundColor: Colors.deepOrange.shade100,
                  deleteIconColor: Colors.deepOrange,
                ),
              ),
            Expanded(child: StreamBuilder<List<TransaksiModel>>(
              stream: _firebaseService.getTransaksiForKaryawan(_currentUserId!, selectedDate: _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(_selectedDate == null ? 'Anda belum mencatat transaksi apapun.' : 'Tidak ada transaksi pada tanggal ini.', style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center),
                  );
                }
                final transactions = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    // [REVISED] Use the unified tile builder
                    return _buildTransactionTile(trx);
                  },
                );
              },
            )),
          ]),
        );
      },
    );
  }

  Widget _buildAppDrawer(Map<String, dynamic> profile) {
    final String userName = profile['name'] ?? 'Karyawan';
    final String umkmName = profile['namaBadanUsaha'] ?? 'UMKM';
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
          _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, true),
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // [NEW] Unified Transaction Tile Builder for Karyawan
  Widget _buildTransactionTile(TransaksiModel trx) {
    bool isPosTransaction = (trx.kategori == 'Penjualan Produk' || trx.kategori == 'Pembelian Bahan & Stok') && (trx.items?.isNotEmpty ?? false);
    bool isPenerimaan = trx.jenis == 'Penerimaan';
    Color amountColor = isPenerimaan ? Colors.green.shade700 : Colors.red.shade700;
    Color iconColor = isPenerimaan ? Colors.green : Colors.red;
    
    IconData iconData;
    if (isPosTransaction) {
        iconData = Icons.shopping_cart;
    } else {
        iconData = isPenerimaan ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(trx.kategori, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          _formatCurrency(trx.jumlah.toDouble()),
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: amountColor),
        ),
        // Karyawan has no pop-up menu, so trailing is null
        trailing: const SizedBox.shrink(), 
        children: [
          const Divider(height: 1),
          if (isPosTransaction && trx.items != null)
            ...trx.items!.map((item) => ListTile(
                  dense: true,
                  title: Text(item['name'] ?? 'Nama Barang'),
                  subtitle: Text('${item['quantity']} x ${_formatCurrency((item['price'] ?? 0).toDouble())}'),
                  trailing: Text(_formatCurrency(((item['quantity'] ?? 0) * (item['price'] ?? 0)).toDouble())),
                )).toList(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildFooterInfo(trx),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooterInfo(TransaksiModel trx) {
    String paymentInfo = trx.metodePembayaran ?? '';
    if (trx.metodePembayaran == 'Non-Tunai' && trx.detailMetodePembayaran != null && trx.detailMetodePembayaran!.isNotEmpty) {
      paymentInfo += ' (${trx.detailMetodePembayaran})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
         if (trx.deskripsi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('Deskripsi: ${trx.deskripsi}', style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic)),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Flexible(
              child: Text(
                paymentInfo.isNotEmpty ? 'Pembayaran: $paymentInfo' : '',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ),
            Text(DateFormat('dd MMMM yyyy, HH:mm').format(trx.tanggal), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }
}
