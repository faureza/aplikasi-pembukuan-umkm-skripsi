// lib/models/karyawan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class KaryawanModel {
  final String id;
  final String userIdPemilik; // UID Pemilik UMKM yang terikat
  final String nama;
  final String posisi;
  final String noTelp;
  final int gaji;

  // Field untuk Autentikasi Karyawan
  final String? emailKaryawan;
  final String? uidKaryawan; // UID Karyawan dari Firebase Auth

  final DateTime tglMasuk;

  KaryawanModel({
    this.id = '',
    required this.userIdPemilik,
    required this.nama,
    required this.posisi,
    required this.noTelp,
    required this.gaji,
    this.emailKaryawan,
    this.uidKaryawan,
    required this.tglMasuk,
  });

  // Digunakan untuk menyimpan data karyawan BARU di Firestore (dipanggil oleh addKaryawanWithAuth)
  Map<String, dynamic> toMapWithUID(String uidPemilik) {
    return {
      'userIdPemilik': uidPemilik, // KUNCI: Untuk Query Pemilik
      'nama': nama,
      'posisi': posisi,
      'noTelp': noTelp,
      'gaji': gaji,
      'emailKaryawan': emailKaryawan,
      'uidKaryawan': uidKaryawan, // UID Karyawan (diambil dari Auth)
      'tglMasuk': Timestamp.fromDate(tglMasuk),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Digunakan untuk mengambil data dari Firestore ke aplikasi
  factory KaryawanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KaryawanModel(
      id: doc.id,
      userIdPemilik: data['userIdPemilik'] as String,
      nama: data['nama'] as String,
      posisi: data['posisi'] as String? ?? 'Pencatat',
      noTelp: data['noTelp'] as String? ?? '',
      gaji: (data['gaji'] as num).toInt(), // Menggunakan num.toInt() untuk safety
      emailKaryawan: data['emailKaryawan'] as String?,
      uidKaryawan: data['uidKaryawan'] as String?,
      tglMasuk: (data['tglMasuk'] as Timestamp).toDate(),
    );
  }
}