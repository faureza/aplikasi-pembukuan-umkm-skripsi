// lib/screens/modal_kewajiban_screen.dart (Reverted to Original Single Form Design)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

// Drawer imports
import 'transaksi_history_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'tentang_screen.dart';
import 'token_management_screen.dart';

class ModalKewajibanScreen extends StatefulWidget {
  const ModalKewajibanScreen({super.key});

  @override
  State<ModalKewajibanScreen> createState() => _ModalKewajibanScreenState();
}

class _ModalKewajibanScreenState extends State<ModalKewajibanScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  late Future<Map<String, dynamic>?> _profileFuture;

  final _jumlahController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = const [
    'Modal Awal',
    'Setor Modal (Investasi)',
    'Tarik Modal (Prive)',
    'Utang Bank',
    'Utang Lainnya',
    'Pembayaran Utang',
  ];
  
  final List<String> _relevantCategories = const [
    'Modal Awal',
    'Setor Modal (Investasi)',
    'Tarik Modal (Prive)',
    'Utang Bank',
    'Utang Lainnya',
    'Pembayaran Utang',
  ];

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileFuture = _firebaseService.getUserProfile(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final jumlah = int.tryParse(_jumlahController.text.replaceAll('.', ''));
      final deskripsi = _deskripsiController.text;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (jumlah == null || _selectedCategory == null || currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tidak valid.')));
        return;
      }
      
      String jenis;
      if (['Tarik Modal (Prive)', 'Pembayaran Utang'].contains(_selectedCategory!)) {
        jenis = 'Pengeluaran';
      } else {
        jenis = 'Penerimaan';
      }

      final newTransaksi = TransaksiModel(
        userId: currentUser.uid,
        tanggal: _selectedDate,
        jenis: jenis,
        kategori: _selectedCategory!,
        jumlah: jumlah,
        deskripsi: deskripsi,
        dicatatOlehUid: currentUser.uid,
        dicatatOlehNama: 'Pemilik',
      );

      final result = await _firebaseService.addTransaksi(newTransaksi);
      
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan!')));
        _formKey.currentState!.reset();
        _jumlahController.clear();
        _deskripsiController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $result')));
      }
    }
  }
  
  void _handleDrawerNavigation(String title) {
    Navigator.pop(context);
    if (title == 'Input Modal & Kewajiban') return;
    if (title == 'Logout') {
      _firebaseService.logoutUser().then((_) => Navigator.of(context).popUntil((route) => route.isFirst));
      return;
    }
    Widget? destination;
    switch (title) {
      case 'Beranda':
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Kelola Akses Karyawan': destination = const TokenManagementScreen(); break;
      case 'Riwayat Transaksi': destination = const TransaksiHistoryScreen(); break;
      case 'Laporan': destination = const LaporanScreen(); break;
      case 'Pengaturan': destination = const PengaturanScreen(); break;
      case 'Tentang': destination = const TentangScreen(); break;
    }
    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Sesi tidak valid.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Input Modal & Kewajiban', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final String userName = snapshot.data?['pemilik'] ?? currentUser.email?.split('@').first ?? 'Pemilik';
          final String umkmName = snapshot.data?['namaBadanUsaha'] ?? 'UMKM Jambi';
          return Drawer(
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
                  _buildDrawerItem(context, 'Beranda', Icons.home, false),
                  _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, true),
                  _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, false),
                  _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, false),
                  _buildDrawerItem(context, 'Laporan', Icons.list_alt, false),
                  _buildDrawerItem(context, 'Pengaturan', Icons.settings, false),
                  _buildDrawerItem(context, 'Tentang', Icons.info_outline, false),
                  const Spacer(),
                  ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.white), title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)), onTap: () => _handleDrawerNavigation('Logout')),
                  Padding(padding: const EdgeInsets.all(16.0), child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))),
                ],
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('Tambah Data Baru', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  initiallyExpanded: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                              onChanged: (value) => setState(() => _selectedCategory = value),
                              validator: (value) => value == null ? 'Pilih kategori' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jumlahController,
                              decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Masukkan jumlah' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _deskripsiController,
                              decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _pickDate(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _submitForm,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: Text('Simpan Data', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(thickness: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text('Riwayat Terbaru', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<TransaksiModel>>(
              stream: _firebaseService.getTransaksi(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat data.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada data modal atau kewajiban.'));
                }
                
                final relevantTransactions = snapshot.data!.where((tx) => _relevantCategories.contains(tx.kategori)).toList();
                relevantTransactions.sort((a, b) => b.tanggal.compareTo(a.tanggal));

                if (relevantTransactions.isEmpty) {
                  return const Center(child: Text('Belum ada riwayat tercatat.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: relevantTransactions.length,
                  itemBuilder: (context, index) {
                    final trx = relevantTransactions[index];
                    final isPengeluaran = trx.jenis == 'Pengeluaran';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isPengeluaran ? Colors.red : Colors.green).withOpacity(0.1),
                          child: Icon(
                            isPengeluaran ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPengeluaran ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(trx.kategori, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggal), style: GoogleFonts.poppins(fontSize: 12)),
                        trailing: Text(
                          _formatCurrency(trx.jumlah.toDouble()),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isPengeluaran ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
