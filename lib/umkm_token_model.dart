// lib/umkm_token_model.dart (FILE BARU)

import 'package:cloud_firestore/cloud_firestore.dart';

class UmkmTokenModel {
  final String token;
  final String userIdPemilik;
  final String namaUsaha;
  final DateTime createdAt;

  UmkmTokenModel({
    required this.token,
    required this.userIdPemilik,
    required this.namaUsaha,
    required this.createdAt,
  });

  factory UmkmTokenModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UmkmTokenModel(
      token: doc.id, // ID dokumen adalah token itu sendiri
      userIdPemilik: data['userIdPemilik'] as String,
      namaUsaha: data['namaUsaha'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}