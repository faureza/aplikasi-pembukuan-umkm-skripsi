// lib/services/pdf_service.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

class PdfService {
  final FirebaseService _firebaseService = FirebaseService();

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // --- Common PDF Generation Logic ---
  Future<void> _generateAndPrintPdf({
    required String title,
    required String periode,
    required String namaUsaha,
    required String pemilik,
    required pw.Widget content,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildHeader(context, title, namaUsaha, pemilik, periode),
        footer: _buildFooter,
        build: (pw.Context context) => [
          content,
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeader(pw.Context context, String title, String namaUsaha, String pemilik, String periode) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(namaUsaha, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Text(periode),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }


  // --- LABA RUGI ---
  Future<void> generateAndPrintLabaRugi({
      required String periode,
      required String userIdPemilik,
      required String namaUsaha,
      required String pemilik,
  }) async {
    // 1. Fetch Data
    final transactions = await _firebaseService.getTransaksi(userIdPemilik).first;

    // 2. Filter Data (logic updated)
    final now = DateTime.now();
    List<TransaksiModel> filteredList = transactions;
    if (periode == 'Bulan Ini') {
      filteredList = transactions.where((tx) => tx.tanggal.year == now.year && tx.tanggal.month == now.month).toList();
    } else if (periode == 'Bulan Lalu') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      filteredList = transactions.where((tx) => tx.tanggal.year == lastMonth.year && tx.tanggal.month == lastMonth.month).toList();
    }

    // 3. Calculate Data (logic updated)
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

    // 4. Build PDF content
    final content = _buildLabaRugiContent(pendapatanDetails, totalPendapatan, bebanDetails, totalBeban, labaBersih);

    // 5. Generate and Print
    await _generateAndPrintPdf(
      title: 'Laporan Laba Rugi',
      periode: 'Periode: $periode',
      namaUsaha: namaUsaha,
      pemilik: pemilik,
      content: content,
    );
  }

  pw.Widget _buildLabaRugiContent(Map<String, double> pendapatanDetails, double totalPendapatan, Map<String, double> bebanDetails, double totalBeban, double labaBersih) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildPdfSectionHeader('PENDAPATAN USAHA'),
          ...pendapatanDetails.entries.map((e) => _buildPdfItemRow(e.key, e.value)),
          pw.Divider(height: 15, thickness: 0.5),
          _buildPdfTotalRow('Total Pendapatan', totalPendapatan),
          pw.SizedBox(height: 20),

          _buildPdfSectionHeader('BEBAN USAHA'),
          ...bebanDetails.entries.map((e) => _buildPdfItemRow(e.key, e.value)),
          pw.Divider(height: 15, thickness: 0.5),
          _buildPdfTotalRow('Total Beban', totalBeban),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 10),

          _buildPdfFinalResult(
            labaBersih >= 0 ? 'LABA BERSIH' : 'RUGI BERSIH',
            labaBersih.abs(),
            labaBersih >= 0 ? PdfColors.green : PdfColors.red,
          ),
        ],
      );
  }


  // --- ARUS KAS ---
  Future<void> generateAndPrintArusKas({
      required String periode,
      required String userIdPemilik,
      required String namaUsaha,
      required String pemilik,
  }) async {
      // 1. Fetch data
      final allTransactions = await _firebaseService.getTransaksi(userIdPemilik).first;

      // 2. Filter & Calculate (logic updated)
      final now = DateTime.now();
      List<TransaksiModel> filteredList;
      List<TransaksiModel> beforePeriodList = [];

      if (periode == 'Bulan Ini') {
          final startOfMonth = DateTime(now.year, now.month, 1);
          filteredList = allTransactions.where((tx) => tx.tanggal.year == now.year && tx.tanggal.month == now.month).toList();
          beforePeriodList = allTransactions.where((tx) => tx.tanggal.isBefore(startOfMonth)).toList();
      } else if (periode == 'Bulan Lalu') {
          final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
          final endOfLastMonth = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
          filteredList = allTransactions.where((tx) => tx.tanggal.isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) && tx.tanggal.isBefore(endOfLastMonth.add(const Duration(seconds: 1)))).toList();
          beforePeriodList = allTransactions.where((tx) => tx.tanggal.isBefore(startOfLastMonth)).toList();
      } else { // Semua Data
          filteredList = allTransactions;
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

      // 3. Build PDF content
      final content = _buildArusKasContent(saldoAwal, operasiMasuk, operasiKeluar, kasDariOperasi, pendanaanMasuk, pendanaanKeluar, kasDariPendanaan, kenaikanPenurunanKas, saldoAkhir);

      // 4. Generate and Print
      await _generateAndPrintPdf(
        title: 'Laporan Arus Kas',
        periode: 'Periode: $periode',
        namaUsaha: namaUsaha,
        pemilik: pemilik,
        content: content,
      );
  }

  pw.Widget _buildArusKasContent(double saldoAwal, Map<String, double> operasiMasuk, Map<String, double> operasiKeluar, double kasDariOperasi, Map<String, double> pendanaanMasuk, Map<String, double> pendanaanKeluar, double kasDariPendanaan, double kenaikanPenurunanKas, double saldoAkhir) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildPdfTotalRow('Saldo Kas Awal Periode', saldoAwal, fontWeight: pw.FontWeight.normal),
        pw.SizedBox(height: 15),

        _buildPdfSectionHeader('Arus Kas dari Aktivitas Operasi'),
        ...operasiMasuk.entries.map((e) => _buildPdfItemRow(e.key, e.value)),
        ...operasiKeluar.entries.map((e) => _buildPdfItemRow(e.key, -e.value)),
        pw.Divider(height: 10, indent: 12, endIndent: 12),
        _buildPdfTotalRow('Arus Kas Bersih dari Operasi', kasDariOperasi, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 20),

        _buildPdfSectionHeader('Arus Kas dari Aktivitas Pendanaan'),
        ...pendanaanMasuk.entries.map((e) => _buildPdfItemRow(e.key, e.value)),
        ...pendanaanKeluar.entries.map((e) => _buildPdfItemRow(e.key, -e.value)),
        pw.Divider(height: 10, indent: 12, endIndent: 12),
        _buildPdfTotalRow('Arus Kas Bersih dari Pendanaan', kasDariPendanaan, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 15),
        pw.Divider(thickness: 1),
        _buildPdfTotalRow('Kenaikan (Penurunan) Kas Bersih', kenaikanPenurunanKas),
        pw.SizedBox(height: 20),

        _buildPdfFinalResult('SALDO KAS AKHIR PERIODE', saldoAkhir, saldoAkhir >= 0 ? PdfColors.blue : PdfColors.red),
      ],
    );
  }

  // --- NERACA ---
  Future<void> generateAndPrintNeraca({
      required String periode,
      required String userIdPemilik,
      required String namaUsaha,
      required String pemilik,
  }) async {
    // 1. Fetch Data
    final allTransactions = await _firebaseService.getTransaksi(userIdPemilik).first;

    // 2. Filter & Calculate (logic updated)
    final now = DateTime.now();
    List<TransaksiModel> filteredList;
    DateTime endDate = now;
    DateTime startDate = DateTime(1900);

    if (periode == 'Bulan Ini') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (periode == 'Bulan Lalu') {
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    }
    
    if (periode != 'Semua Data') {
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

    // 3. Build PDF content
    final content = _buildNeracaContent(endDate, kas, totalAset, utang, pembayaranUtang, totalKewajiban, modalDisetor, prive, labaBersihPeriode, totalEkuitas, totalKewajibanDanEkuitas);

    // 4. Generate and Print
    final String perDate = 'Per: ${DateFormat('dd MMMM yyyy', 'id_ID').format(endDate)}';
    await _generateAndPrintPdf(
      title: 'Laporan Neraca',
      periode: perDate,
      namaUsaha: namaUsaha,
      pemilik: pemilik,
      content: content,
    );
  }

  pw.Widget _buildNeracaContent(DateTime endDate, double kas, double totalAset, double utang, double pembayaranUtang, double totalKewajiban, double modalDisetor, double prive, double labaBersihPeriode, double totalEkuitas, double totalKewajibanDanEkuitas) {
     final bool isBalanced = (totalAset - totalKewajibanDanEkuitas).abs() < 0.01;
     final double difference = totalAset - totalKewajibanDanEkuitas;

     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildPdfSectionHeader('ASET'),
        _buildPdfItemRow('Kas dan Setara Kas', kas),
        pw.Divider(height: 15, thickness: 0.5),
        _buildPdfTotalRow('TOTAL ASET', totalAset),
        pw.SizedBox(height: 20),

        _buildPdfSectionHeader('KEWAJIBAN'),
        _buildPdfItemRow('Utang Bank & Lainnya', utang),
        _buildPdfItemRow('Pembayaran Utang', -pembayaranUtang),
        _buildPdfTotalRow('TOTAL KEWAJIBAN', totalKewajiban, fontWeight: pw.FontWeight.normal),
        pw.SizedBox(height: 15),

        _buildPdfSectionHeader('EKUITAS'),
        _buildPdfItemRow('Modal Disetor', modalDisetor),
        _buildPdfItemRow('Prive (Penarikan Modal)', -prive),
        _buildPdfItemRow('Laba Bersih Periode Berjalan', labaBersihPeriode),
        _buildPdfTotalRow('TOTAL EKUITAS', totalEkuitas, fontWeight: pw.FontWeight.normal),
        pw.Divider(height: 15, thickness: 0.5),
        _buildPdfTotalRow('TOTAL KEWAJIBAN & EKUITAS', totalKewajibanDanEkuitas),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 10),

        _buildPdfFinalResult(
          isBalanced ? 'NERACA SEIMBANG' : 'TIDAK SEIMBANG',
          difference,
          isBalanced ? PdfColors.green : PdfColors.red,
        ),
      ],
     );
  }

  // --- PDF Widget Builders ---
  pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600, fontSize: 11)),
    );
  }

  pw.Widget _buildPdfItemRow(String label, double amount, {bool isSubItem = true}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: isSubItem ? 12.0 : 0, top: 2, bottom: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(child: pw.Text(label, textAlign: pw.TextAlign.left)),
        pw.Text(_formatCurrency(amount), style: pw.TextStyle(color: amount < 0 ? PdfColors.red : PdfColors.black)),
      ]),
    );
  }

  pw.Widget _buildPdfTotalRow(String label, double amount, {pw.FontWeight? fontWeight}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6.0),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: fontWeight ?? pw.FontWeight.bold, fontSize: 12)),
        pw.Text(_formatCurrency(amount), style: pw.TextStyle(fontWeight: fontWeight ?? pw.FontWeight.bold, fontSize: 12, color: amount < 0 ? PdfColors.red : PdfColors.black)),
      ]),
    );
  }

  pw.Widget _buildPdfFinalResult(String title, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color, fontSize: 13)),
        pw.Text(_formatCurrency(amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }
}
