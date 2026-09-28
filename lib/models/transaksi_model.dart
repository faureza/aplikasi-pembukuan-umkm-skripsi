import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  // [ADDED] ID field to store the document ID
  final String? id;
  final String userId; // ID Pemilik UMKM
  final DateTime tanggal;
  final String jenis;
  final String kategori;
  final int jumlah;
  final String deskripsi;
  final String? dicatatOlehUid;
  final String? dicatatOlehNama;
  final String? metodePembayaran;
  final String? detailMetodePembayaran;
  final String? nomorReferensi;
  final List<Map<String, dynamic>>? items;
  final String? jenisPenjualan;

  TransaksiModel({
    this.id, // Made ID optional in constructor
    required this.userId,
    required this.tanggal,
    required this.jenis,
    required this.kategori,
    required this.jumlah,
    this.deskripsi = '',
    this.dicatatOlehUid,
    this.dicatatOlehNama,
    this.metodePembayaran,
    this.detailMetodePembayaran,
    this.nomorReferensi,
    this.items,
    this.jenisPenjualan,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tanggal': Timestamp.fromDate(tanggal),
      'jenis': jenis,
      'kategori': kategori,
      'jumlah': jumlah,
      'deskripsi': deskripsi,
      'dicatatOlehUid': dicatatOlehUid,
      'dicatatOlehNama': dicatatOlehNama,
      'metodePembayaran': metodePembayaran,
      'detailMetodePembayaran': detailMetodePembayaran,
      'nomorReferensi': nomorReferensi,
      'items': items,
      'jenisPenjualan': jenisPenjualan,
    };
  }

  // [MODIFIED] Factory constructor now accepts the document ID
  factory TransaksiModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransaksiModel(
      id: doc.id, // Assign the document ID here
      userId: data['userId'] ?? '',
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      jenis: data['jenis'] ?? '',
      kategori: data['kategori'] ?? '',
      jumlah: data['jumlah'] ?? 0,
      deskripsi: data['deskripsi'] ?? '',
      dicatatOlehUid: data['dicatatOlehUid'],
      dicatatOlehNama: data['dicatatOlehNama'],
      metodePembayaran: data['metodePembayaran'],
      detailMetodePembayaran: data['detailMetodePembayaran'],
      nomorReferensi: data['nomorReferensi'],
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
      jenisPenjualan: data['jenisPenjualan'],
    );
  }
}
