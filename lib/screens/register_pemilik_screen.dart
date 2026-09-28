// lib/screens/register_pemilik_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class RegisterPemilikScreen extends StatefulWidget {
  const RegisterPemilikScreen({super.key});

  @override
  State<RegisterPemilikScreen> createState() => _RegisterPemilikScreenState();
}

class _RegisterPemilikScreenState extends State<RegisterPemilikScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  // Controller input
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  final TextEditingController _namaBadanC = TextEditingController();
  final TextEditingController _alamatC = TextEditingController();
  final TextEditingController _noTelpC = TextEditingController();
  final TextEditingController _pemilikC = TextEditingController();
  final TextEditingController _deskripsiC = TextEditingController();
  final TextEditingController _nikC = TextEditingController();

  String? _selectedJenisUsaha;
  String? _selectedKecamatan;
  String? _selectedKelurahan;
  bool _loading = false;

  // Daftar jenis usaha (Tetap)
  final List<String> _jenisUsaha = [
    'Kuliner', 'Fashion / Pakaian', 'Kue & Roti', 'Minuman', 'Kerajinan / Souvenir',
    'Jasa (Salon, Laundry, Layanan)', 'Elektronik & Aksesoris', 'Pertanian / Perkebunan',
    'Perikanan', 'Toko Kelontong / Minimarket', 'Digital / IT', 'Transportasi / Logistik', 'Lainnya',
  ];

  // Data Kecamatan -> Kelurahan (Kota Jambi) (Tetap)
  final Map<String, List<String>> _kecamatanKelurahan = {
    'Telanaipura': ['Rawang', 'Kendali', 'Lebak Bandung', 'Sungai Penuh', 'Pasir Putih'],
    'Jambi Selatan': ['Pakuan Baru', 'Pasir Putih', 'Tambak Sari', 'The Hok', 'Wijaya Pura'],
    'Jambi Timur': ['Budiman', 'Kasang', 'Kasang Jaya', 'Rajawali', 'Sejinjang', 'Talang Banjar', 'Tanjung Pinang', 'Tanjung Sari'],
    'Pasar Jambi': ['Orang Kayo Hitam', 'Pelayangan', 'Pembina', 'Talang Banjar'],
    'Danau Teluk': ['Olak Kemang', 'Pasir Panjang', 'Tanjung Pasir', 'Tanjung Raden', 'Ulu Gedong'],
    'Pelayangan': ['Mudung Laut', 'Pasir Putih', 'Tanjung Johor'],
    'Jelutung': ['Lebak Bandung', 'Suka Jaya', 'Talang Jauh'],
    'Kota Baru': ['Kampung Baru', 'Rajawali', 'Simpang III Sipin'],
    'Alam Barajo': ['Bagan Pete', 'Beliung', 'Kenali Besar', 'Mayang Mangurai', 'Rawa Sari'],
    'Paal Merah': ['Lingkar Selatan', 'Lingkar Utara', 'Talang Bakung'],
    'Danau Sipin': ['Legok', 'Murni', 'Selamat', 'Solok Sipin', 'Sungai Putri'],
  };

  Future<void> _submitPemilik() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKecamatan == null || _selectedKelurahan == null || _selectedJenisUsaha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih jenis usaha, kecamatan, dan kelurahan terlebih dahulu.')));
      return;
    }

    setState(() => _loading = true);

    // KOREKSI LOGIKA: Mengirim umkmToken: null
    final error = await _firebaseService.registerUser(
      name: _pemilikC.text.trim(),
      email: _emailC.text.trim(),
      password: _passwordC.text.trim(),
      usaha: _selectedJenisUsaha!,
      namaBadanUsaha: _namaBadanC.text.trim(),
      alamat: _alamatC.text.trim(),
      kecamatan: _selectedKecamatan!,
      kelurahan: _selectedKelurahan!,
      noTelp: _noTelpC.text.trim(),
      pemilik: _pemilikC.text.trim(),
      deskripsi: _deskripsiC.text.trim(),
      nik: _nikC.text.trim(),
      umkmToken: null, // KUNCI: Tidak ada token saat pendaftaran Pemilik
    );

    setState(() => _loading = false);

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pendaftaran Gagal: $error')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran Berhasil! Silakan login.')));
        Navigator.pop(context); // Kembali ke halaman Login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelurahanList = _selectedKecamatan != null ? _kecamatanKelurahan[_selectedKecamatan!] ?? [] : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pemilik Usaha'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // BAGIAN 1: DATA UMKM & PEMILIK
                Text(
                  'Data UMKM & Pemilik',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const Divider(color: Colors.deepOrange),

                TextFormField(
                  controller: _namaBadanC,
                  decoration: const InputDecoration(labelText: 'Nama Badan Usaha', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama badan usaha wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _pemilikC,
                  decoration: const InputDecoration(labelText: 'Nama Pemilik', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pemilik wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordC,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata Sandi', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Kata sandi wajib diisi';
                    if (v.trim().length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedJenisUsaha,
                  decoration: const InputDecoration(labelText: 'Jenis Usaha', border: OutlineInputBorder()),
                  items: _jenisUsaha.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedJenisUsaha = v),
                  validator: (v) => v == null ? 'Pilih jenis usaha' : null,
                ),
                const SizedBox(height: 12),

                // --- Alamat & Lokasi ---
                TextFormField(
                  controller: _alamatC,
                  decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()),
                  minLines: 1,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedKecamatan,
                  decoration: const InputDecoration(labelText: 'Kecamatan', border: OutlineInputBorder()),
                  items: _kecamatanKelurahan.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedKecamatan = v;
                      _selectedKelurahan = null;
                    });
                  },
                  validator: (v) => v == null ? 'Pilih Kelurahan' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedKelurahan,
                  decoration: const InputDecoration(labelText: 'Kelurahan', border: OutlineInputBorder()),
                  items: kelurahanList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (v) => setState(() => _selectedKelurahan = v),
                  validator: (v) => v == null ? 'Pilih kelurahan' : null,
                ),
                const SizedBox(height: 12),

                // --- Kontak & Legal ---
                TextFormField(
                  controller: _noTelpC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon', border: OutlineInputBorder(), prefixText: '+62 '),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nomor telepon wajib diisi';
                    if (v.replaceAll(RegExp(r'\\D'), '').length < 8) return 'Nomor tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _deskripsiC,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Deskripsi Usaha', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nikC,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  decoration: const InputDecoration(labelText: 'Nomor NIK (KTP)', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
                    if (v.length < 16) return 'NIK harus 16 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Tombol Daftar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitPemilik,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Daftar Sekarang', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}