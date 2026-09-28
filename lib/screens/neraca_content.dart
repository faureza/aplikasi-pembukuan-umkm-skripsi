// lib/screens/neraca_content.dart (REVISED FOR MODAL & KEWAJIBAN)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

class NeracaContent extends StatefulWidget {
  final String periode;

  const NeracaContent({super.key, required this.periode});

  @override
  State<NeracaContent> createState() => _NeracaContentState();
}

class _NeracaContentState extends State<NeracaContent> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isExpanded = false; // [FIXED] Default to collapsed
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() => _isLocaleInitialized = true);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }

  Widget _buildItemRow(String label, double amount, {bool isSubItem = true, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16.0 : 0, top: 4, bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 14), overflow: TextOverflow.ellipsis)),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 14, color: valueColor)),
      ]),
    );
  }

  Widget _buildTotalRow(String label, double amount, {FontWeight fontWeight = FontWeight.bold}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight))),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight)),
      ]),
    );
  }

  Widget _buildBalanceIndicator(double totalAset, double totalKewajibanDanEkuitas) {
    final bool isBalanced = (totalAset - totalKewajibanDanEkuitas).abs() < 0.01;
    final String title = isBalanced ? 'NERACA SEIMBANG' : 'TIDAK SEIMBANG';
    final Color color = isBalanced ? Colors.green.shade700 : Colors.red.shade700;
    final double difference = totalAset - totalKewajibanDanEkuitas;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        Text(_formatCurrency(difference), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userIdPemilik = currentUser?.uid ?? '';

    return userIdPemilik.isEmpty
        ? const Center(child: Text('Sesi pemilik tidak aktif.'))
        : StreamBuilder<List<TransaksiModel>>(
            stream: _firebaseService.getTransaksi(userIdPemilik),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Tidak ada data transaksi.', style: GoogleFonts.poppins()));
              }

              final allTransactions = snapshot.data!;
              final now = DateTime.now();
              List<TransaksiModel> filteredList;
              
              DateTime endDate = now;
              DateTime startDate = DateTime(1900);

              if (widget.periode == 'Bulan Ini') {
                startDate = DateTime(now.year, now.month, 1);
                endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
              } else if (widget.periode == 'Bulan Lalu') {
                startDate = DateTime(now.year, now.month - 1, 1);
                endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
              }
              
              if (widget.periode != 'Semua Data') {
                filteredList = allTransactions.where((tx) => tx.tanggal.isAfter(startDate.subtract(const Duration(microseconds: 1))) && tx.tanggal.isBefore(endDate.add(const Duration(microseconds: 1)))).toList();
              } else {
                filteredList = allTransactions;
              }
              
              final cumulativeList = allTransactions.where((tx) => tx.tanggal.isBefore(endDate.add(const Duration(days: 1)))).toList();

              double kas = 0;
              double pendapatanOperasional = 0;
              double bebanOperasional = 0;
              double modalDisetor = 0;
              double prive = 0;
              double utang = 0;
              double pembayaranUtang = 0;

              for (var tx in cumulativeList) {
                  if (tx.jenis == 'Penerimaan') {
                      kas += tx.jumlah.toDouble();
                  } else if (tx.jenis == 'Pengeluaran') {
                      kas -= tx.jumlah.toDouble();
                  }
                  switch (tx.kategori) {
                      case 'Modal Awal':
                      case 'Setor Modal (Investasi)':
                          modalDisetor += tx.jumlah.toDouble();
                          break;
                      case 'Tarik Modal (Prive)':
                          prive += tx.jumlah.toDouble();
                          break;
                      case 'Utang Bank':
                      case 'Utang Lainnya':
                          utang += tx.jumlah.toDouble();
                          break;
                      case 'Pembayaran Utang':
                          pembayaranUtang += tx.jumlah.toDouble();
                          break;
                  }
              }
              
              for (var tx in filteredList) {
                if (!['Modal Awal', 'Setor Modal (Investasi)', 'Tarik Modal (Prive)', 'Utang Bank', 'Utang Lainnya', 'Pembayaran Utang'].contains(tx.kategori)) {
                  if (tx.jenis == 'Penerimaan') {
                    pendapatanOperasional += tx.jumlah.toDouble();
                  } else if (tx.jenis == 'Pengeluaran') {
                    bebanOperasional += tx.jumlah.toDouble();
                  }
                }
              }

              final double labaBersihPeriode = pendapatanOperasional - bebanOperasional;
              final double totalAset = kas;
              final double totalKewajiban = utang - pembayaranUtang;
              final double totalEkuitas = (modalDisetor - prive) + labaBersihPeriode;
              final double totalKewajibanDanEkuitas = totalKewajiban + totalEkuitas;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Laporan Neraca', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Per: ${DateFormat('dd MMMM yyyy', 'id_ID').format(endDate)}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                        const SizedBox(height: 16),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionHeader('ASET'),
                            _buildItemRow('Kas dan Setara Kas', kas),
                            const Divider(height: 20, thickness: 1),
                          ]) : const SizedBox.shrink(),
                        ),
                        _buildTotalRow('TOTAL ASET', totalAset),
                        const SizedBox(height: 24),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionHeader('KEWAJIBAN'),
                            _buildItemRow('Utang Bank & Lainnya', utang),
                            _buildItemRow('Pembayaran Utang', -pembayaranUtang, valueColor: Colors.red.shade700),
                            const Divider(height: 1, thickness: 1, indent: 100),
                            _buildTotalRow('TOTAL KEWAJIBAN', totalKewajiban, fontWeight: FontWeight.normal),
                            const SizedBox(height: 16),
                            _buildSectionHeader('EKUITAS'),
                            _buildItemRow('Modal Disetor', modalDisetor),
                            _buildItemRow('Prive (Penarikan Modal)', -prive, valueColor: Colors.red.shade700),
                            _buildItemRow('Laba Bersih Periode Berjalan', labaBersihPeriode),
                            const Divider(height: 1, thickness: 1, indent: 100),
                            _buildTotalRow('TOTAL EKUITAS', totalEkuitas, fontWeight: FontWeight.normal),
                            const Divider(height: 20, thickness: 1),
                          ]) : const SizedBox.shrink(),
                        ),
                        _buildTotalRow('TOTAL KEWAJIBAN & EKUITAS', totalKewajibanDanEkuitas),

                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.deepOrange),
                          label: Text(_isExpanded ? 'Sembunyikan Detail' : 'Lihat Detail', style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 2),
                        const SizedBox(height: 10),

                        _buildBalanceIndicator(totalAset, totalKewajibanDanEkuitas),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
