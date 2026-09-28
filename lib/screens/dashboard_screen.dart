// lib/screens/dashboard_screen.dart (REWORKED with Calendar & Date Range Picker)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:umkmjambi/main.dart';
import '../services/firebase_service.dart';
import 'modal_kewajiban_screen.dart';
import 'token_management_screen.dart';
import 'transaksi_history_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'tentang_screen.dart';
import '../models/transaksi_model.dart';
import 'package:intl/intl.dart';

enum DateFilterType { today, thisWeek, thisMonth, allTime, custom }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>?> _profileFuture;

  // State untuk filter kalender baru
  DateFilterType _selectedFilterType = DateFilterType.allTime;
  DateTimeRange? _selectedDateRange;
  String _activeMenu = 'Beranda';

  @override
  void initState() {
    super.initState();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileFuture = _firebaseService.getUserProfile(currentUser.uid);
    }
    _updateDateRange(); // Set initial range
  }

  void _updateDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      switch (_selectedFilterType) {
        case DateFilterType.today:
          _selectedDateRange = DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
          break;
        case DateFilterType.thisWeek:
          final weekStart = today.subtract(Duration(days: now.weekday - 1));
          _selectedDateRange = DateTimeRange(start: weekStart, end: weekStart.add(const Duration(days: 7)));
          break;
        case DateFilterType.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          final nextMonthStart = DateTime(now.year, now.month + 1, 1);
          _selectedDateRange = DateTimeRange(start: monthStart, end: nextMonthStart);
          break;
        case DateFilterType.allTime:
          _selectedDateRange = null; // null signifies all time
          break;
        case DateFilterType.custom:
          // Ditangani oleh _showCustomDateRangePicker
          break;
      }
    });
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepOrange, onPrimary: Colors.white, onSurface: Colors.black),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilterType = DateFilterType.custom;
        _selectedDateRange = picked;
      });
    }
  }

  String _getFilterDisplayName() {
    if (_selectedDateRange == null) {
      return 'Semua Data';
    }
    switch (_selectedFilterType) {
      case DateFilterType.today:
        return 'Hari Ini';
      case DateFilterType.thisWeek:
        return 'Minggu Ini';
      case DateFilterType.thisMonth:
        return 'Bulan Ini';
      case DateFilterType.custom:
        final start = DateFormat('d/M/yy', 'id_ID').format(_selectedDateRange!.start);
        final end = DateFormat('d/M/yy', 'id_ID').format(_selectedDateRange!.end);
        return '$start - $end';
      default:
        return 'Semua Data';
    }
  }
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(leading: const Icon(Icons.today), title: const Text('Hari Ini'), onTap: () {
              setState(() => _selectedFilterType = DateFilterType.today);
              _updateDateRange();
              Navigator.pop(context);
            }),
            ListTile(leading: const Icon(Icons.date_range), title: const Text('Minggu Ini'), onTap: () {
              setState(() => _selectedFilterType = DateFilterType.thisWeek);
              _updateDateRange();
              Navigator.pop(context);
            }),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Bulan Ini'), onTap: () {
              setState(() => _selectedFilterType = DateFilterType.thisMonth);
               _updateDateRange();
              Navigator.pop(context);
            }),
            ListTile(leading: const Icon(Icons.event_repeat), title: const Text('Semua Data'), onTap: () {
              setState(() => _selectedFilterType = DateFilterType.allTime);
               _updateDateRange();
              Navigator.pop(context);
            }),
             const Divider(height: 1),
            ListTile(leading: const Icon(Icons.edit_calendar), title: const Text('Pilih Rentang Tanggal...'), onTap: () {
              Navigator.pop(context);
              _showCustomDateRangePicker();
            }),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _firebaseService.logoutUser();
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, VoidCallback action) {
    bool isActive = title == _activeMenu;
    VoidCallback newOnTap = () {
      Navigator.pop(context);
      if (['Kelola Akses Karyawan', 'Riwayat Transaksi', 'Laporan', 'Pengaturan', 'Tentang', 'Input Modal & Kewajiban'].contains(title)) {
        Widget targetScreen;
        switch (title) {
          case 'Kelola Akses Karyawan':
            targetScreen = const TokenManagementScreen();
            break;
          case 'Riwayat Transaksi':
            targetScreen = const TransaksiHistoryScreen();
            break;
          case 'Laporan':
            targetScreen = const LaporanScreen();
            break;
          case 'Pengaturan':
            targetScreen = const PengaturanScreen();
            break;
          case 'Tentang':
            targetScreen = const TentangScreen();
            break;
          case 'Input Modal & Kewajiban':
            targetScreen = const ModalKewajibanScreen();
            break;
          default:
            return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen)).then((_) {
          setState(() => _activeMenu = 'Beranda');
        });
      } else {
        setState(() => _activeMenu = title);
        action();
      }
    };
    return Container(
      color: isActive ? Colors.deepOrange : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white70),
        title: Text(title, style: GoogleFonts.poppins(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.w500)),
        onTap: newOnTap,
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String title, required double amount, required double percentage}) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.rectangle, color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text('${percentage.toStringAsFixed(1)}% dari total', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDonutChart(double income, double expense) {
    final double total = income + expense;
    if (total == 0) {
      return _buildChartPlaceholder('Data perbandingan kas belum tersedia.');
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      height: 200,
      decoration: _chartBoxDecoration(),
      child: Row(
        children: [
          const SizedBox(width: 20),
          SizedBox(
            width: 140,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(color: Colors.green, value: income, title: '', radius: 55),
                  PieChartSectionData(color: Colors.red, value: expense, title: '', radius: 55),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 25,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(color: Colors.green, title: 'Penerimaan', amount: income, percentage: (income / total) * 100),
                const SizedBox(height: 20),
                _buildLegendItem(color: Colors.red, title: 'Pengeluaran', amount: expense, percentage: (expense / total) * 100),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildBarChart(double income, double expense) {
    if (income == 0 && expense == 0) {
      return _buildChartPlaceholder('Data tren penerimaan & pengeluaran belum tersedia.');
    }
    final barGroups = [
      _makeBarGroupData(0, income, Colors.green),
      _makeBarGroupData(1, expense, Colors.red),
    ];
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label = group.x == 0 ? 'Penerimaan' : 'Pengeluaran';
                return BarTooltipItem(
                  '$label',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [TextSpan(text: _formatCurrency(rod.toY), style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500))],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: _leftTitleWidgets)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitleWidgets, reservedSize: 38)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)))]);
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0 || value > meta.max) return const SizedBox.shrink();
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}Rb';
    } else {
      text = value.toStringAsFixed(0);
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 5, child: Text(text, style: GoogleFonts.poppins(fontSize: 10)));
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    String text = '';
    if (value.toInt() == 0) text = 'Penerimaan';
    if (value.toInt() == 1) text = 'Pengeluaran';
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)));
  }

  BoxDecoration _chartBoxDecoration() {
    return BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]);
  }

  Widget _buildChartPlaceholder(String message) {
    return Container(height: 220, alignment: Alignment.center, decoration: _chartBoxDecoration(), child: Text(message, style: GoogleFonts.poppins(color: Colors.grey[600]), textAlign: TextAlign.center));
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.08),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700)), Icon(icon, color: color, size: 20)]),
            const SizedBox(height: 5),
            Text(_formatCurrency(amount), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (profileSnapshot.hasError || !profileSnapshot.hasData || profileSnapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
          return const Scaffold(body: Center(child: Text('Gagal memuat data profil. Silakan login ulang.')));
        }
        final String namaUsaha = profileSnapshot.data?['namaBadanUsaha'] ?? 'UMKM Jambi';
        final String userName = profileSnapshot.data?['pemilik'] ?? currentUser?.email?.split('@').first ?? 'Pemilik';
        final String userIdPemilik = currentUser?.uid ?? '';
        return Scaffold(
          appBar: AppBar(
              title: Text('Beranda', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: Colors.deepOrange,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout')]),
          drawer: Drawer(
            child: Container(
              color: Colors.deepOrange,
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text('Hi, $userName', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                    accountEmail: Text(namaUsaha, style: GoogleFonts.poppins(color: Colors.white70)),
                    currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.deepOrange)),
                    decoration: const BoxDecoration(color: Colors.deepOrange),
                  ),
                  _buildDrawerItem(context, 'Beranda', Icons.home, () {}),
                  _buildDrawerItem(context, 'Input Modal & Kewajiban', Icons.account_balance_wallet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModalKewajibanScreen()))),
                  _buildDrawerItem(context, 'Kelola Akses Karyawan', Icons.vpn_key, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TokenManagementScreen()))),
                  _buildDrawerItem(context, 'Riwayat Transaksi', Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransaksiHistoryScreen()))),
                  _buildDrawerItem(context, 'Laporan', Icons.list_alt, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen()))),
                  _buildDrawerItem(context, 'Pengaturan', Icons.settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PengaturanScreen()))),
                  _buildDrawerItem(context, 'Tentang', Icons.info_outline, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TentangScreen()))),
                  const Spacer(),
                  ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.white), title: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)), onTap: _logout),
                  Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 8.0), child: Text('Copyright @2025 SI-AKU Jambi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))),
                ],
              ),
            ),
          ),
          body: userIdPemilik.isEmpty
              ? const Center(child: Text('Gagal memuat ID Pemilik.'))
              : StreamBuilder<List<TransaksiModel>>(
            stream: _firebaseService.getTransaksi(userIdPemilik),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allTransactions = snapshot.data ?? [];
              
              List<TransaksiModel> filteredTransactions;
              if (_selectedDateRange == null) {
                filteredTransactions = allTransactions; // Tampilkan semua jika tidak ada filter rentang
              } else {
                final rangeEnd = _selectedDateRange!.end;
                // Jika rentang hanya 1 hari (start & end sama), pastikan mencakup hingga akhir hari
                final effectiveEnd = (_selectedDateRange!.start.isAtSameMomentAs(rangeEnd))
                    ? rangeEnd.add(const Duration(days: 1))
                    : rangeEnd;

                filteredTransactions = allTransactions.where((tx) {
                  final txDate = tx.tanggal;
                  return txDate.isAfter(_selectedDateRange!.start.subtract(const Duration(microseconds: 1))) && txDate.isBefore(effectiveEnd);
                }).toList();
              }

              double totalPenerimaan = filteredTransactions.where((tx) => tx.jenis == 'Penerimaan').fold(0.0, (sum, tx) => sum + tx.jumlah);
              double totalPengeluaran = filteredTransactions.where((tx) => tx.jenis == 'Pengeluaran').fold(0.0, (sum, tx) => sum + tx.jumlah);
              final double saldoAkhir = totalPenerimaan - totalPengeluaran;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Tampilkan Data:", style: GoogleFonts.poppins(fontSize: 16)),
                        ActionChip(
                          onPressed: _showFilterOptions,
                          avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.deepOrange),
                          label: Text(_getFilterDisplayName(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.deepOrange)),
                          backgroundColor: Colors.deepOrange.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Card(
                      color: saldoAkhir >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Saldo Kas Bersih", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700)),
                            Text(_formatCurrency(saldoAkhir.abs()),
                                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: saldoAkhir >= 0 ? Colors.green.shade700 : Colors.red.shade700))
                          ]),
                          Icon(saldoAkhir >= 0 ? Icons.trending_up : Icons.trending_down, size: 40, color: saldoAkhir >= 0 ? Colors.green.shade400 : Colors.red.shade400),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: _buildSummaryCard("Penerimaan", totalPenerimaan, Colors.blue, Icons.arrow_downward)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildSummaryCard("Pengeluaran", totalPengeluaran, Colors.orange, Icons.arrow_upward)),
                    ]),
                    const SizedBox(height: 30),
                    Text("Perbandingan Kas", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 15),
                    _buildDonutChart(totalPenerimaan, totalPengeluaran),
                    const SizedBox(height: 30),
                    Text('Total Penerimaan vs Pengeluaran', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 15),
                    _buildBarChart(totalPenerimaan, totalPengeluaran),
                    const SizedBox(height: 30),
                    Text('Akses Laporan Cepat', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildMenuCard(context, Icons.trending_up, 'Laba Rugi', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen(initialTab: 'Laba Rugi')))),
                        _buildMenuCard(context, Icons.account_balance_wallet, 'Arus Kas', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen(initialTab: 'Arus Kas')))),
                        _buildMenuCard(context, Icons.balance, 'Neraca', Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen(initialTab: 'Neraca')))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
