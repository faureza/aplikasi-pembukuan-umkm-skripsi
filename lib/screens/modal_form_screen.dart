// lib/screens/modal_form_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaksi_model.dart';

class ModalFormScreen extends StatefulWidget {
  final String kategori;
  final String jenis; // Penerimaan atau Pengeluaran

  const ModalFormScreen({
    super.key,
    required this.kategori,
    required this.jenis,
  });

  @override
  State<ModalFormScreen> createState() => _ModalFormScreenState();
}

class _ModalFormScreenState extends State<ModalFormScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _jumlahController = TextEditingController();
  final _deskripsiController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
      setState(() => _isLoading = true);

      final jumlah = int.tryParse(_jumlahController.text.replaceAll('.', ''));
      final deskripsi = _deskripsiController.text;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (jumlah == null || currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data jumlah tidak valid.')));
        setState(() => _isLoading = false);
        return;
      }

      final newTransaksi = TransaksiModel(
        userId: currentUser.uid,
        tanggal: _selectedDate,
        jenis: widget.jenis,
        kategori: widget.kategori,
        jumlah: jumlah,
        deskripsi: deskripsi,
        dicatatOlehUid: currentUser.uid,
        dicatatOlehNama: 'Pemilik',
      );

      final result = await _firebaseService.addTransaksi(newTransaksi);
      
      if (mounted) {
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.kategori} berhasil disimpan!')),
          );
          Navigator.of(context).pop(); // Go back to the previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $result')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catat ${widget.kategori}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _jumlahController,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Jumlah tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                title: Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save, color: Colors.white),
                  label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Simpan Data', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
