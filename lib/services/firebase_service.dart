import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/transaksi_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateUmkmToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ12345567890';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print(e); // For debugging
      return false;
    }
  }

  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'Tidak ada pengguna yang login.';
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Password saat ini salah.';
      } else if (e.code == 'weak-password') {
        return 'Password baru terlalu lemah.';
      }
      return e.message;
    } catch (e) {
      return 'Terjadi error tidak diketahui.';
    }
  }

  Future<String?> getActiveUmkmToken(String userIdPemilik) async {
    try {
      final tokenSnapshot = await _firestore.collection('umkm_tokens').where('userIdPemilik', isEqualTo: userIdPemilik).where('isUsed', isEqualTo: false).orderBy('createdAt', descending: true).limit(1).get();
      if (tokenSnapshot.docs.isNotEmpty) {
        return tokenSnapshot.docs.first.data()['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<QuerySnapshot> getProductsStream(String ownerId) {
    return _firestore.collection('products').where('ownerId', isEqualTo: ownerId).snapshots();
  }

  Future<void> addProduct(String ownerId, String productName, int price) async {
    await _firestore.collection('products').add({
      'ownerId': ownerId,
      'name': productName,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> registerUser({ required String name, required String email, required String password, String? nik, String? noTelp, String? umkmToken, String usaha = '', String namaBadanUsaha = '', String alamat = '', String kecamatan = '', String kelurahan = '', String pemilik = '', String deskripsi = '',}) async {
    UserCredential? userCred;
    try {
      final token = umkmToken?.trim().toUpperCase();
      final isKaryawan = token != null && token.isNotEmpty;
      userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCred.user!.uid;
      String role = 'pemilik';
      String idUmkmPemilik = uid;
      String dynamicNamaBadanUsaha = namaBadanUsaha;
      if (isKaryawan) {
        final tokenQuery = await _firestore.collection('umkm_tokens').where('token', isEqualTo: token).where('isUsed', isEqualTo: false).limit(1).get();
        if (tokenQuery.docs.isEmpty) {
          await userCred.user!.delete();
          return 'Token UMKM tidak valid atau sudah digunakan.';
        }
        final tokenDoc = tokenQuery.docs.first;
        final tokenData = tokenDoc.data();
        idUmkmPemilik = tokenData['userIdPemilik'] as String;
        dynamicNamaBadanUsaha = tokenData['namaUsaha'] as String;
        role = 'karyawan';
        await tokenDoc.reference.update({'isUsed': true, 'usedByUid': uid, 'usedAt': FieldValue.serverTimestamp()});
      }
      await _firestore.collection('users').doc(uid).set({
        'name': name, 'email': email, 'role': role,
        'id_umkm_pemilik': idUmkmPemilik,
        'noTelp': isKaryawan ? noTelp : 'N/A',
        'nik': isKaryawan ? '' : nik,
        'usaha': isKaryawan ? 'Karyawan' : usaha,
        'namaBadanUsaha': isKaryawan ? dynamicNamaBadanUsaha : namaBadanUsaha,
        'alamat': isKaryawan ? 'N/A' : alamat,
        'kecamatan': isKaryawan ? 'N/A' : kecamatan,
        'kelurahan': isKaryawan ? 'N/A' : kelurahan,
        'pemilik': isKaryawan ? name : pemilik,
        'deskripsi': isKaryawan ? 'N/A' : deskripsi,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (role == 'pemilik') {
        String newToken = _generateUmkmToken();
        await _firestore.collection('umkm_tokens').add({'token': newToken, 'userIdPemilik': uid, 'namaUsaha': namaBadanUsaha, 'isUsed': false, 'createdAt': FieldValue.serverTimestamp()});
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (userCred != null) {
        await userCred.user!.delete();
      }
      return '[${e.code}] ${e.message}';
    } catch (e) {
      if (userCred != null) {
        await userCred.user!.delete();
      }
      return e.toString();
    }
  }

  Future<String?> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<String?> generateUmkmToken({required String namaUsaha, required String userId}) async {
    try {
      if (userId.isEmpty) return 'Error: Pemilik tidak terautentikasi.';
      final tokenRef = _firestore.collection('umkm_tokens').doc();
      final String tokenValue = _generateUmkmToken();
      await tokenRef.set({'token': tokenValue, 'userIdPemilik': userId, 'namaUsaha': namaUsaha, 'isUsed': false, 'createdAt': FieldValue.serverTimestamp()});
      return tokenValue;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<List<Map<String, dynamic>>> getKaryawan(String userIdPemilik) {
    return _firestore.collection('users').where('id_umkm_pemilik', isEqualTo: userIdPemilik).where('role', isEqualTo: 'karyawan').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<String?> addTransaksi(TransaksiModel transaksi) async {
    try {
      await _firestore.collection('transaksi').add(transaksi.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTransaksi(String transaksiId, TransaksiModel transaksi) async {
    try {
      await _firestore.collection('transaksi').doc(transaksiId).update(transaksi.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  
  Future<String?> deleteTransaksi(String transaksiId) async {
    try {
      await _firestore.collection('transaksi').doc(transaksiId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // [MODIFIED] This function now correctly passes the document ID to the model
  Stream<List<TransaksiModel>> getTransaksi(String idUmkmPemilik, {DateTime? selectedDate}) {
    Query query = _firestore.collection('transaksi').where('userId', isEqualTo: idUmkmPemilik);

    if (selectedDate != null) {
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      query = query.where('tanggal', isGreaterThanOrEqualTo: startOfDay).where('tanggal', isLessThanOrEqualTo: endOfDay);
    }

    query = query.orderBy('tanggal', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // The magic happens here: TransaksiModel.fromFirestore now gets the whole doc
        return TransaksiModel.fromFirestore(doc);
      }).toList();
    });
  }

  Stream<List<TransaksiModel>> getTransaksiForKaryawan(String karyawanId, {DateTime? selectedDate}) {
    Query query = _firestore.collection('transaksi').where('dicatatOlehUid', isEqualTo: karyawanId);

    if (selectedDate != null) {
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      query = query.where('tanggal', isGreaterThanOrEqualTo: startOfDay).where('tanggal', isLessThanOrEqualTo: endOfDay);
    }

    query = query.orderBy('tanggal', descending: true);

    // Also apply the fix here for consistency
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransaksiModel.fromFirestore(doc);
      }).toList();
    });
  }
}
