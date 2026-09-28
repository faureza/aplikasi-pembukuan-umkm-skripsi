// lib/screens/arus_kas_content.dart (FIXED: Added Expand/Collapse functionality)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

class ArusKasContent extends StatefulWidget {
  final String periode;

  const ArusKasContent({super.key, required this.periode});

  @override
  State<ArusKasContent> createState() => _ArusKasContentState();
}

class _ArusKasContentState extends State<ArusKasContent> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isExpanded = false; // [FIXED] Default to collapsed

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildItemRow(String label, double amount, {bool isSubItem = true}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16.0 : 0, top: 4, bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 14), overflow: TextOverflow.ellipsis)),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 14, color: amount < 0 ? Colors.red.shade700 : Colors.black87)),
      ]),
    );
  }

  Widget _buildTotalRow(String label, double amount, {FontWeight fontWeight = FontWeight.bold}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight))),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight, color: amount < 0 ? Colors.red.shade700 : Colors.black87)),
      ]),
    );
  }
  
  Widget _buildFinalResult(String title, double amount) {
    final Color color = amount >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis)),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              List<TransaksiModel> beforePeriodList = [];

              if (widget.periode == 'Bulan Ini') {
                final startOfMonth = DateTime(now.year, now.month, 1);
                filteredList = allTransactions.where((tx) => tx.tanggal.year == now.year && tx.tanggal.month == now.month).toList();
                beforePeriodList = allTransactions.where((tx) => tx.tanggal.isBefore(startOfMonth)).toList();
              } else if (widget.periode == 'Bulan Lalu') {
                final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
                final endOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
                filteredList = allTransactions.where((tx) => tx.tanggal.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) && tx.tanggal.isBefore(endOfLastMonth.add(const Duration(seconds: 1)))).toList();
                beforePeriodList = allTransactions.where((tx) => tx.tanggal.isBefore(startOfLastMonth)).toList();
              } else { // Semua Data
                filteredList = allTransactions;
              }

              if (filteredList.isEmpty && widget.periode != 'Semua Data') {
                return Center(child: Text('Tidak ada data transaksi untuk periode ini.', style: GoogleFonts.poppins()));
              }

              double saldoAwal = beforePeriodList.fold(0.0, (sum, tx) => sum + (tx.jenis == 'Penerimaan' ? tx.jumlah.toDouble() : -tx.jumlah.toDouble()));
              
              Map<String, double> operasiMasuk = {};
              Map<String, double> operasiKeluar = {};
              Map<String, double> pendanaanMasuk = {};
              Map<String, double> pendanaanKeluar = {};

              for (var tx in filteredList) {
                  switch (tx.kategori) {
                      case 'Modal Awal':
                      case 'Setor Modal (Investasi)':
                          pendanaanMasuk.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          break;
                      case 'Utang Bank':
                      case 'Utang Lainnya':
                          pendanaanMasuk.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          break;
                      case 'Tarik Modal (Prive)':
                          pendanaanKeluar.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          break;
                      case 'Pembayaran Utang':
                          pendanaanKeluar.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          break;
                      default:
                          if (tx.jenis == 'Penerimaan') {
                              operasiMasuk.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          } else {
                              operasiKeluar.update(tx.kategori, (value) => value + tx.jumlah.toDouble(), ifAbsent: () => tx.jumlah.toDouble());
                          }
                          break;
                  }
              }

              final double kasDariOperasi = operasiMasuk.values.fold(0.0, (sum, val) => sum + val) - operasiKeluar.values.fold(0.0, (sum, val) => sum + val);
              final double kasDariPendanaan = pendanaanMasuk.values.fold(0.0, (sum, val) => sum + val) - pendanaanKeluar.values.fold(0.0, (sum, val) => sum + val);

              final double kenaikanPenurunanKas = kasDariOperasi + kasDariPendanaan;
              final double saldoAkhir = saldoAwal + kenaikanPenurunanKas;

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
                        Text('Laporan Arus Kas', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Periode: ${widget.periode}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                        const SizedBox(height: 16),

                        _buildTotalRow('Saldo Kas Awal Periode', saldoAwal, fontWeight: FontWeight.normal),
                        const SizedBox(height: 16),
                        
                        // [NEW] AnimatedSize for smooth expansion
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded 
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Arus Kas dari Aktivitas Operasi'),
                                ...operasiMasuk.entries.map((e) => _buildItemRow(e.key, e.value)),
                                ...operasiKeluar.entries.map((e) => _buildItemRow(e.key, -e.value)), // Show as negative
                                const Divider(height: 10, indent: 16, endIndent: 16),
                              ], 
                            )
                          : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: _isExpanded ? 16.0 : 0),
                          child: _buildTotalRow('Arus Kas Bersih dari Operasi', kasDariOperasi, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded
                           ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Arus Kas dari Aktivitas Pendanaan'),
                                ...pendanaanMasuk.entries.map((e) => _buildItemRow(e.key, e.value)),
                                ...pendanaanKeluar.entries.map((e) => _buildItemRow(e.key, -e.value)), // Show as negative
                                const Divider(height: 10, indent: 16, endIndent: 16),
                              ],
                           )
                           : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: _isExpanded ? 16.0 : 0),
                          child: _buildTotalRow('Arus Kas Bersih dari Pendanaan', kasDariPendanaan, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1.5),
                        _buildTotalRow('Kenaikan (Penurunan) Kas Bersih', kenaikanPenurunanKas, fontWeight: FontWeight.bold),
                        const SizedBox(height: 24),
                        
                        // [NEW] Toggle Button
                        TextButton.icon(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.deepOrange),
                          label: Text(_isExpanded ? 'Sembunyikan Detail' : 'Lihat Detail', style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),

                        _buildFinalResult('SALDO KAS AKHIR PERIODE', saldoAkhir),

                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
