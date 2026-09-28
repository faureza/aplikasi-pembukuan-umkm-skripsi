// lib/screens/transaksi_form_screen.dart (FINAL & STABLE)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaksi_history_screen.dart';
import 'karyawan_transaksi_history_screen.dart';


// Model untuk item di dalam keranjang belanja
class CartItem {
  final String name;
  final int price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class TransaksiFormScreen extends StatefulWidget {
  final String kategori;
  final String jenis;
  final String id_umkm_pemilik;
  final String userRole;

  const TransaksiFormScreen({
    super.key,
    required this.kategori,
    required this.jenis,
    required this.id_umkm_pemilik,
    required this.userRole,
  });

  @override
  State<TransaksiFormScreen> createState() => _TransaksiFormScreenState();
}

class _TransaksiFormScreenState extends State<TransaksiFormScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final _referensiController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _detailPembayaranController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _metodePembayaran = 'Tunai';
  String _jenisPenjualan = 'Offline';

  final List<String> _biayaOperasionalList = ['Listrik', 'Air', 'Internet', 'Sewa', 'Gaji', 'Transportasi', 'Lain-lain'];
  String? _selectedJenisBiaya;

  final List<CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
    if (widget.kategori == 'Biaya Operasional') {
      _selectedJenisBiaya = _biayaOperasionalList.first;
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _referensiController.dispose();
    _jumlahController.dispose();
    _detailPembayaranController.dispose();
    super.dispose();
  }

  Future<Map<String, String?>> _getCurrentUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return {};
    final profile = await _firebaseService.getUserProfile(currentUser.uid);
    return {
      'userId': currentUser.uid,
      'userName': profile?['name'] as String?,
      'role': profile?['role'] as String?,
    };
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.add_box_outlined, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Text(
              'Tambah ${widget.jenis == 'Penerimaan' ? 'Produk' : 'Item'}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextFormField(controller: nameController, decoration: _inputDecoration(label: 'Nama Produk', icon: Icons.label_outline), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: priceController, decoration: _inputDecoration(label: 'Harga Satuan', icon: Icons.attach_money_outlined), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: qtyController, decoration: _inputDecoration(label: 'Jumlah', icon: Icons.format_list_numbered_outlined), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dialogFormKey.currentState!.validate()) {
                setState(() {
                  _cart.add(CartItem(
                    name: nameController.text,
                    price: int.parse(priceController.text),
                    quantity: int.parse(qtyController.text),
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.kategori == 'Penjualan Produk' || widget.kategori == 'Pembelian Bahan & Stok') {
      await _savePosTransaction();
    } else {
      await _saveSimpleTransaction();
    }
  }

  Future<void> _navigateToHistory(String? role) async {
    if (!mounted) return;

    Widget destinationScreen;
    if (role == 'pemilik') {
      destinationScreen = const TransaksiHistoryScreen();
    } else if (role == 'karyawan') {
      destinationScreen = const KaryawanTransaksiHistoryScreen();
    } else {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  Future<void> _savePosTransaction() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong!')));
      return;
    }

    setState(() => _loading = true);
    final userInfo = await _getCurrentUserInfo();
    final totalAmount = _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));

    final newTransaksi = TransaksiModel(
      userId: widget.id_umkm_pemilik,
      tanggal: _selectedDate,
      jenis: widget.jenis,
      kategori: widget.kategori,
      jumlah: totalAmount,
      metodePembayaran: _metodePembayaran,
      detailMetodePembayaran: _metodePembayaran == 'Non-Tunai' ? _detailPembayaranController.text.trim() : null,
      jenisPenjualan: widget.jenis == 'Penerimaan' ? _jenisPenjualan : null,
      deskripsi: _deskripsiController.text.trim(),
      items: _cart.map((item) => {'name': item.name, 'price': item.price, 'quantity': item.quantity}).toList(),
      dicatatOlehUid: userInfo['userId'],
      dicatatOlehNama: userInfo['userName'],
    );

    final error = await _firebaseService.addTransaksi(newTransaksi);
    setState(() => _loading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $error')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.kategori} berhasil dicatat!')));
        _navigateToHistory(userInfo['role']);
      }
    }
  }

  Future<void> _saveSimpleTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final userInfo = await _getCurrentUserInfo();

    final newTransaksi = TransaksiModel(
      userId: widget.id_umkm_pemilik,
      tanggal: _selectedDate,
      jenis: widget.jenis,
      kategori: _selectedJenisBiaya ?? widget.kategori,
      jumlah: int.tryParse(_jumlahController.text.replaceAll('.', '')) ?? 0,
      deskripsi: _deskripsiController.text.trim(),
      metodePembayaran: _metodePembayaran,
      detailMetodePembayaran: _metodePembayaran == 'Non-Tunai' ? _detailPembayaranController.text.trim() : null,
      nomorReferensi: _referensiController.text.trim(),
      dicatatOlehUid: userInfo['userId'],
      dicatatOlehNama: userInfo['userName'],
    );

    final error = await _firebaseService.addTransaksi(newTransaksi);
    setState(() => _loading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $error')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.kategori} berhasil dicatat!')));
        _navigateToHistory(userInfo['role']);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstAllowedDate = widget.userRole == 'karyawan'
        ? DateTime(now.year, now.month, now.day)
        : DateTime(2020);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstAllowedDate,
      lastDate: now,
    );

    if (picked != null) {
      final nowForTime = DateTime.now();
      final newDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        nowForTime.hour,
        nowForTime.minute,
      );
      setState(() {
        _selectedDate = newDateTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPosForm = widget.kategori == 'Penjualan Produk' || widget.kategori == 'Pembelian Bahan & Stok';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.kategori, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: isPosForm ? _buildPosUI() : _buildSimpleFormUI(),
      ),
    );
  }

  Widget _buildPosUI() {
    final total = _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    bool isPenjualan = widget.jenis == 'Penerimaan';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDropdownField(icon: Icons.account_balance_wallet_outlined, label: 'Metode Pembayaran', value: _metodePembayaran, items: ['Tunai', 'Non-Tunai'], onChanged: (val) => setState(() => _metodePembayaran = val!)),
              if (_metodePembayaran == 'Non-Tunai') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _detailPembayaranController,
                  decoration: _inputDecoration(label: 'Sumber Dana (e.g., BCA, Dana)', icon: Icons.credit_card_outlined),
                  validator: (v) => (v == null || v.isEmpty) ? 'Sumber dana wajib diisi' : null,
                ),
              ],
              const SizedBox(height: 16),
              if (isPenjualan) ...[
                _buildDropdownField(icon: Icons.store_outlined, label: 'Jenis Penjualan', value: _jenisPenjualan, items: ['Offline', 'Online'], onChanged: (val) => setState(() => _jenisPenjualan = val!)),
                const SizedBox(height: 16),
              ],
              _buildDatePicker(),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Produk', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)), IconButton(icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 30), onPressed: _showAddItemDialog, tooltip: 'Tambah Barang')]),
              const Divider(),
              _cart.isEmpty
                  ? Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.deepOrange),
                      SizedBox(height: 16),
                      Text('Keranjang masih kosong', style: TextStyle(color: Colors.deepOrange, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text('Tambahkan produk dengan menekan tombol + di atas.', style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
                  : Column(children: _cart.map((item) => _buildCartItemTile(item)).toList()),
              const SizedBox(height: 16),
              _buildNotesField(),
            ],
          ),
        ),
        _buildSummaryAndSave(total, Colors.deepOrange, 'SIMPAN ${isPenjualan ? 'PENJUALAN' : 'PEMBELIAN'}', _saveTransaction),
      ],
    );
  }

  Widget _buildSimpleFormUI() {
    bool isBiayaOperasional = widget.kategori == 'Biaya Operasional';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDropdownField(icon: Icons.account_balance_wallet_outlined, label: 'Metode Pembayaran', value: _metodePembayaran, items: ['Tunai', 'Non-Tunai'], onChanged: (val) => setState(() => _metodePembayaran = val!)),
          if (_metodePembayaran == 'Non-Tunai') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailPembayaranController,
              decoration: _inputDecoration(label: 'Sumber Dana (e.g., BCA, Dana)', icon: Icons.credit_card_outlined),
              validator: (v) => (v == null || v.isEmpty) ? 'Sumber dana wajib diisi' : null,
            ),
          ],
          const SizedBox(height: 16),
          if (isBiayaOperasional) ...[
            _buildDropdownField(icon: Icons.receipt_long_outlined, label: 'Jenis Biaya', value: _selectedJenisBiaya!, items: _biayaOperasionalList, onChanged: (val) => setState(() => _selectedJenisBiaya = val!)),
            const SizedBox(height: 16),
          ],
          _buildDatePicker(),
          const SizedBox(height: 16),
          TextFormField(controller: _referensiController, decoration: _inputDecoration(label: 'No. Referensi / Keterangan', icon: Icons.article_outlined)),
          const SizedBox(height: 16),
          TextFormField(controller: _jumlahController, decoration: _inputDecoration(label: 'Total Biaya (Rp)', icon: Icons.monetization_on_outlined), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CurrencyInputFormatter()], validator: (val) => (val == null || val.isEmpty || val == '0') ? 'Jumlah tidak boleh nol' : null),
          const SizedBox(height: 16),
          _buildNotesField(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _saveSimpleTransaction,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text('SIMPAN BIAYA', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS REUSABLE & RAPIH ---

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepOrange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.quantity} x ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.price)}'),
        trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged, required IconData icon}) {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(label: label, icon: icon),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: _inputDecoration(label: 'Tanggal Transaksi', icon: Icons.calendar_today_outlined),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd MMMM yyyy').format(_selectedDate)), const Icon(Icons.calendar_today, color: Colors.deepOrange)]),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _deskripsiController,
      decoration: _inputDecoration(label: 'Catatan (Opsional)', icon: Icons.note_alt_outlined),
      maxLines: 2,
    );
  }

  Widget _buildSummaryAndSave(int total, Color color, String buttonText, VoidCallback onSave) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, spreadRadius: -1)]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(total), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : onSave,
            style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final formatter = NumberFormat.decimalPattern('id_ID');
    String newText = formatter.format(int.parse(newValue.text.replaceAll('.', '')));
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}