import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collector.dart';

class FirestoreService {
  FirestoreService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _authOverride = auth,
       _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> saveAdminLoginTrace(User user) {
    return _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': 'administrateur',
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Collector?> findActiveCollectorByQrCode(String qrCode) async {
    final snapshot = await _firestore
        .collection('collecteurs')
        .where('qrCode', isEqualTo: qrCode.trim())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Collector.fromFirestore(doc.id, doc.data());
  }

  Future<void> saveCollectorLoginTrace(Collector collector) async {
    await _firestore.collection('collecteurs').doc(collector.id).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('collectorId', collector.id);
    await preferences.setString('collectorName', collector.fullName);
  }
}
