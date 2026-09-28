import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class EditTransaksiPemilikScreen extends StatefulWidget {
  final TransaksiModel transaksiToEdit;

  const EditTransaksiPemilikScreen({super.key, required this.transaksiToEdit});

  @override
  State<EditTransaksiPemilikScreen> createState() => _EditTransaksiPemilikScreenState();
}

class _EditTransaksiPemilikScreenState extends State<EditTransaksiPemilikScreen> {
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
    _populateForm();
  }

  void _populateForm() {
    final trx = widget.transaksiToEdit;
    _deskripsiController.text = trx.deskripsi;
    _referensiController.text = trx.nomorReferensi ?? '';
    _jumlahController.text = NumberFormat.decimalPattern('id_ID').format(trx.jumlah);
    _detailPembayaranController.text = trx.detailMetodePembayaran ?? '';
    _selectedDate = trx.tanggal;
    _metodePembayaran = trx.metodePembayaran ?? 'Tunai';
    _jenisPenjualan = trx.jenisPenjualan ?? 'Offline';

    if (trx.kategori == 'Biaya Operasional' && _biayaOperasionalList.contains(trx.kategori)) {
      _selectedJenisBiaya = trx.kategori;
    }

    if (trx.items != null) {
      for (var item in trx.items!) {
        _cart.add(CartItem(name: item['name'], price: item['price'], quantity: item['quantity']));
      }
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

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final isPosForm = widget.transaksiToEdit.kategori == 'Penjualan Produk' || widget.transaksiToEdit.kategori == 'Pembelian Bahan & Stok';
    int totalAmount;
    List<Map<String, dynamic>>? itemsData;

    if (isPosForm) {
      if (_cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang tidak boleh kosong!')));
        setState(() => _loading = false);
        return;
      }
      totalAmount = _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
      itemsData = _cart.map((item) => {'name': item.name, 'price': item.price, 'quantity': item.quantity}).toList();
    } else {
      totalAmount = int.tryParse(_jumlahController.text.replaceAll('.', '')) ?? 0;
      itemsData = null;
    }

    final updatedTransaksi = TransaksiModel(
      id: widget.transaksiToEdit.id,
      userId: widget.transaksiToEdit.userId,
      tanggal: _selectedDate,
      jenis: widget.transaksiToEdit.jenis,
      kategori: _selectedJenisBiaya ?? widget.transaksiToEdit.kategori,
      jumlah: totalAmount,
      deskripsi: _deskripsiController.text.trim(),
      metodePembayaran: _metodePembayaran,
      detailMetodePembayaran: _metodePembayaran == 'Non-Tunai' ? _detailPembayaranController.text.trim() : null,
      nomorReferensi: _referensiController.text.trim(),
      items: itemsData,
      jenisPenjualan: widget.transaksiToEdit.jenis == 'Penerimaan' ? _jenisPenjualan : null,
      dicatatOlehUid: widget.transaksiToEdit.dicatatOlehUid,
      dicatatOlehNama: widget.transaksiToEdit.dicatatOlehNama,
    );

    final error = await _firebaseService.updateTransaksi(widget.transaksiToEdit.id!, updatedTransaksi);
    setState(() => _loading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $error')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil diperbarui!')));
        Navigator.of(context).pop();
      }
    }
  }
  
  void _showAddItemDialog() { // Identical to TransaksiFormScreen
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ${widget.transaksiToEdit.jenis == 'Penerimaan' ? 'Produk Dijual' : 'Produk Dibeli'}'),
        content: Form(key: dialogFormKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Produk'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
          TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Harga Satuan'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
          TextFormField(controller: qtyController, decoration: const InputDecoration(labelText: 'Jumlah'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () {
            if (dialogFormKey.currentState!.validate()) {
              setState(() => _cart.add(CartItem(name: nameController.text, price: int.parse(priceController.text), quantity: int.parse(qtyController.text))));
              Navigator.pop(context);
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPosForm = widget.transaksiToEdit.kategori == 'Penjualan Produk' || widget.transaksiToEdit.kategori == 'Pembelian Bahan & Stok';
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.transaksiToEdit.kategori}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: isPosForm ? _buildPosUI() : _buildSimpleFormUI(),
      ),
    );
  }
  
  // All build methods below are adapted from TransaksiFormScreen, but the save button calls _updateTransaction()

  Widget _buildPosUI() {
    final total = _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    bool isPenjualan = widget.transaksiToEdit.jenis == 'Penerimaan';
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildDropdownField(label: 'Metode Pembayaran', value: _metodePembayaran, items: ['Tunai', 'Non-Tunai'], onChanged: (val) => setState(() => _metodePembayaran = val!)),
        if (_metodePembayaran == 'Non-Tunai') ...[
          const SizedBox(height: 16),
          TextFormField(controller: _detailPembayaranController, decoration: const InputDecoration(labelText: 'Sumber Dana (e.g., BCA, Dana)', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Sumber dana wajib diisi' : null),
        ],
        const SizedBox(height: 16),
        if (isPenjualan) ...[
           _buildDropdownField(label: 'Jenis Penjualan', value: _jenisPenjualan, items: ['Offline', 'Online'], onChanged: (val) => setState(() => _jenisPenjualan = val!)),
           const SizedBox(height: 16),
        ],
        _buildDatePicker(),
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Produk', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)), IconButton(icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 30), onPressed: _showAddItemDialog, tooltip: 'Tambah Barang')]),
        const Divider(),
        _cart.isEmpty ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey)))) : Column(children: _cart.map((item) => _buildCartItemTile(item)).toList()),
        _buildNotesField(),
      ])),
      _buildSummaryAndSave(total, Colors.deepOrange, 'UPDATE TRANSAKSI', _updateTransaction),
    ]);
  }

  Widget _buildSimpleFormUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        _buildDropdownField(label: 'Metode Pembayaran', value: _metodePembayaran, items: ['Tunai', 'Non-Tunai'], onChanged: (val) => setState(() => _metodePembayaran = val!)),
        if (_metodePembayaran == 'Non-Tunai') ...[
          const SizedBox(height: 16),
          TextFormField(controller: _detailPembayaranController, decoration: const InputDecoration(labelText: 'Sumber Dana (e.g., BCA, Dana)', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Sumber dana wajib diisi' : null),
        ],
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 16),
        TextFormField(controller: _referensiController, decoration: const InputDecoration(labelText: 'No. Referensi / Keterangan', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextFormField(controller: _jumlahController, decoration: const InputDecoration(labelText: 'Total Biaya (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CurrencyInputFormatter()], validator: (val) => (val == null || val.isEmpty || val == '0') ? 'Jumlah tidak boleh nol' : null),
        const SizedBox(height: 16),
        _buildNotesField(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _updateTransaction,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size(double.infinity, 55)),
          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text('UPDATE TRANSAKSI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.quantity} x ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.price)}'),
        trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Tanggal Transaksi', border: OutlineInputBorder()),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd MMMM yyyy').format(_selectedDate)), const Icon(Icons.calendar_today, color: Colors.deepOrange)]),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  Widget _buildNotesField() {
    return TextFormField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: OutlineInputBorder()), maxLines: 2);
  }

  Widget _buildSummaryAndSave(int total, Color color, String buttonText, VoidCallback onSave) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, spreadRadius: -1)]),
      child: Column(children: [
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
      ]),
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
