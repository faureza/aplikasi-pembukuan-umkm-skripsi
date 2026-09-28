// lib/screens/transaksi_history_screen.dart (UNIFIED EXPANSION TILE DESIGN)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'token_management_screen.dart';
import 'dashboard_screen.dart';
import 'tentang_screen.dart';
import 'edit_transaksi_pemilik_screen.dart'; 
import 'modal_kewajiban_screen.dart';

class HistoryPageData {
  final Map<String, dynamic> userProfile;
  final String umkmOwnerId;
  final bool isOwner;

  HistoryPageData({required this.userProfile, required this.umkmOwnerId, required this.isOwner});
}

class TransaksiHistoryScreen extends StatefulWidget {
  const TransaksiHistoryScreen({super.key});

  @override
  State<TransaksiHistoryScreen> createState() => _TransaksiHistoryScreenState();
}

class _TransaksiHistoryScreenState extends State<TransaksiHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<HistoryPageData?> _pageDataFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
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

  Future<HistoryPageData?> _loadPageData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Pengguna tidak login.');
    final userProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (userProfile == null) throw Exception('Profil tidak ditemukan.');
    
    final bool isOwner = userProfile['role'] == 'pemilik';
    final String umkmOwnerId = isOwner ? currentUser.uid : userProfile['id_umkm_pemilik'] ?? '';

    if (umkmOwnerId.isEmpty) {
      throw Exception('Akun tidak terhubung ke UMKM manapun.');
    }
    
    return HistoryPageData(userProfile: userProfile, umkmOwnerId: umkmOwnerId, isOwner: isOwner);
  }

  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);
    if (title == 'Riwayat Transaksi') return;
    if (title == 'Logout') {
      _firebaseService.logoutUser();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
    if (destination != null) Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
  }

  void _onEdit(TransaksiModel transaksi) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EditTransaksiPemilikScreen(transaksiToEdit: transaksi),
    )).then((_) {
      setState(() {
        _pageDataFuture = _loadPageData();
      });
    });
  }

  void _onDelete(String transaksiId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            final result = await _firebaseService.deleteTransaksi(transaksiId);
            if (mounted && result != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $result')));
            }
          }, child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoryPageData?>(
      future: _pageDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Error', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.deepOrange, iconTheme: const IconThemeData(color: Colors.white)),
            body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 16), textAlign: TextAlign.center))),
          );
        }

        final pageData = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Riwayat Transaksi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.deepOrange,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context), tooltip: 'Filter Tanggal')],
          ),
          drawer: _buildAppDrawer(pageData.userProfile),
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
              stream: _firebaseService.getTransaksi(pageData.umkmOwnerId, selectedDate: _selectedDate),
              builder: (context, trxSnapshot) {
                if (trxSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!trxSnapshot.hasData || trxSnapshot.data!.isEmpty) return Center(child: Text(_selectedDate == null ? 'Belum ada transaksi tercatat.' : 'Tidak ada transaksi pada tanggal ini.', style: GoogleFonts.poppins()));
                
                final transactions = trxSnapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    // [REVISED] Unified tile builder
                    return _buildTransactionTile(trx, pageData.isOwner);
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
    final String userName = profile['pemilik'] ?? 'Pemilik';
    final String umkmName = profile['namaBadanUsaha'] ?? 'UMKM';
    return Drawer(child: Container(
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
        _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, true),
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
    ));
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
  
  // [NEW] Unified Transaction Tile Builder
  Widget _buildTransactionTile(TransaksiModel trx, bool isOwner) {
    bool isPosTransaction = (trx.kategori == 'Penjualan Produk' || trx.kategori == 'Pembelian Bahan & Stok') && (trx.items?.isNotEmpty ?? false);
    bool isPenerimaan = trx.jenis == 'Penerimaan';
    Color amountColor = isPenerimaan ? Colors.green.shade700 : Colors.red.shade700;
    Color iconColor = isPenerimaan ? Colors.green : Colors.red;
    
    IconData iconData;
    if (isPosTransaction) {
        iconData = Icons.shopping_cart;
    } else if (_isModalOrKewajiban(trx.kategori)) {
        iconData = isPenerimaan ? Icons.add_card : Icons.receipt_long;
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
        trailing: isOwner ? _buildPopupMenu(trx) : null,
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

  bool _isModalOrKewajiban(String kategori) {
    return [
      'Modal Awal', 'Setor Modal (Investasi)', 'Tarik Modal (Prive)',
      'Utang Bank', 'Utang Lainnya', 'Pembayaran Utang'
    ].contains(kategori);
  }

  Widget _buildPopupMenu(TransaksiModel trx) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') _onEdit(trx);
        if (value == 'delete') _onDelete(trx.id!);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
        const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete), title: Text('Hapus'))),
      ],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('dd MMMM yyyy, HH:mm').format(trx.tanggal), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                if (trx.dicatatOlehNama != null && trx.dicatatOlehNama!.isNotEmpty)
                  Text('Dicatat oleh: ${trx.dicatatOlehNama}', style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
