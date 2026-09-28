// lib/screens/laba_rugi_content.dart (REVISED TO EXCLUDE MODAL/KEWAJIBAN)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

class LabaRugiContent extends StatefulWidget {
  final String periode;

  const LabaRugiContent({super.key, required this.periode});

  @override
  State<LabaRugiContent> createState() => _LabaRugiContentState();
}

class _LabaRugiContentState extends State<LabaRugiContent> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isExpanded = false; // [FIXED] Default to collapsed

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }

  Widget _buildItemRow(String label, double amount, {bool isSubItem = true}) {
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 16.0 : 0, top: 4, bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: GoogleFonts.poppins(fontSize: 14), overflow: TextOverflow.ellipsis)),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 14)),
      ]),
    );
  }

  Widget _buildTotalRow(String label, double amount, {FontWeight fontWeight = FontWeight.bold}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight)),
        Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 15, fontWeight: fontWeight)),
      ]),
    );
  }
  
  Widget _buildFinalResult(double labaBersih) {
    final bool isLaba = labaBersih >= 0;
    final String title = isLaba ? 'LABA BERSIH' : 'RUGI BERSIH';
    final Color color = isLaba ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(_formatCurrency(labaBersih.abs()), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
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

              final now = DateTime.now();
              List<TransaksiModel> filteredList = snapshot.data!;
              if (widget.periode == 'Bulan Ini') {
                filteredList = snapshot.data!.where((tx) => tx.tanggal.year == now.year && tx.tanggal.month == now.month).toList();
              } else if (widget.periode == 'Bulan Lalu') {
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                 filteredList = snapshot.data!.where((tx) => tx.tanggal.year == lastMonth.year && tx.tanggal.month == lastMonth.month).toList();
              }
              if (filteredList.isEmpty) {
                return Center(child: Text('Tidak ada data transaksi untuk periode ini.', style: GoogleFonts.poppins()));
              }

              const nonLabaRugiCategories = {
                'Modal Awal',
                'Setor Modal (Investasi)',
                'Tarik Modal (Prive)',
                'Utang Bank',
                'Utang Lainnya',
                'Pembayaran Utang',
              };

              double totalPendapatan = 0;
              double totalBeban = 0;
              Map<String, double> pendapatanDetails = {};
              Map<String, double> bebanDetails = {};

              for (var tx in filteredList) {
                if (!nonLabaRugiCategories.contains(tx.kategori)) {
                  if (tx.jenis == 'Penerimaan') {
                    totalPendapatan += tx.jumlah;
                    pendapatanDetails.update(tx.kategori, (value) => value + tx.jumlah, ifAbsent: () => tx.jumlah.toDouble());
                  } else if (tx.jenis == 'Pengeluaran') {
                    totalBeban += tx.jumlah;
                    bebanDetails.update(tx.kategori, (value) => value + tx.jumlah, ifAbsent: () => tx.jumlah.toDouble());
                  }
                }
              }
              
              final double labaBersih = totalPendapatan - totalBeban;

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
                        Text('Laporan Laba Rugi', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Periode: ${widget.periode}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)),
                        const SizedBox(height: 16),
                        
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded 
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('PENDAPATAN USAHA'),
                                  ...pendapatanDetails.entries.map((e) => _buildItemRow(e.key, e.value)).toList(),
                                  const Divider(height: 20, thickness: 1),
                                ],
                              )
                            : const SizedBox.shrink(),
                        ),

                        _buildTotalRow('Total Pendapatan', totalPendapatan),
                        const SizedBox(height: 24),
                        
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isExpanded 
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('BEBAN USAHA'),
                                  ...bebanDetails.entries.map((e) => _buildItemRow(e.key, e.value)).toList(),
                                  const Divider(height: 20, thickness: 1),
                                ],
                              ) 
                            : const SizedBox.shrink(),
                        ),

                        _buildTotalRow('Total Beban', totalBeban),
                        const SizedBox(height: 24),
                        const Divider(thickness: 2),
                        const SizedBox(height: 10),

                        TextButton.icon(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.deepOrange),
                          label: Text(_isExpanded ? 'Sembunyikan Detail' : 'Lihat Detail', style: GoogleFonts.poppins(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 10),
                        _buildFinalResult(labaBersih),

                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
