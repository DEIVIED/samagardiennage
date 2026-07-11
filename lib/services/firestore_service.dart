import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/payment_record.dart';

/// Levée lorsqu'une cotisation existe déjà pour l'habitant et la période.
class DuplicatePaymentException implements Exception {
  const DuplicatePaymentException();

  @override
  String toString() => 'Cette période est déjà payée.';
}

class FirestoreService {
  FirestoreService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  static const String _paymentCollection = 'payment';

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  // Broadcast stream to notify listeners of data changes (payments/habitants).
  static final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  static Stream<void> get changes => _changesController.stream;

  Future<UserCredential> signInFirebaseAdmin({
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
      'type': AppUserType.admin.value,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultCollectorUser() {
    const user = AppUser(
      id: 'collecteur_daouda_diouf',
      fullName: 'Daouda Diouf',
      email: 'daouda@sama-gardiennage.sn',
      type: AppUserType.collecteur,
      isActive: true,
      pin: '1234',
      qrCode: 'SAMA-COLLECTEUR-DD-001',
      phone: '771021959',
      address: 'Juste 208',
      quartierId: 'quartier_medina',
      quartierName: 'Quartier Medina',
    );

    return _firestore.collection('users').doc(user.id).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'seededAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultHabitantsAndPayments() async {
    // Les données de démonstration ne doivent jamais écraser un paiement réel
    // lorsqu'on relance l'application.
    final alreadySeeded = await _firestore
        .collection(_paymentCollection)
        .doc('payment_habitant_amadou_juillet')
        .get();
    if (alreadySeeded.exists) return;

    final habitants = <AppUser>[
      const AppUser(
        id: 'habitant_amadou_diallo',
        fullName: 'Amadou Diallo',
        email: 'amadou.diallo@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000101',
        address: 'Villa 12, Rue A',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-AMADOU',
      ),
      const AppUser(
        id: 'habitant_fatou_ndiaye',
        fullName: 'Fatou Ndiaye',
        email: 'fatou.ndiaye@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000102',
        address: 'Appartement 5B',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-FATOU',
      ),
      const AppUser(
        id: 'habitant_ibrahima_sow',
        fullName: 'Ibrahima Sow',
        email: 'ibrahima.sow@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000103',
        address: 'Villa 8, Rue B',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-IBRAHIMA',
      ),
      const AppUser(
        id: 'habitant_mariama_bah',
        fullName: 'Mariama Bah',
        email: 'mariama.bah@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000104',
        address: 'Maison 3, Allee C',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-MARIAMA',
      ),

      const AppUser(
        id: 'habitant_ousmane_sarr',
        fullName: 'Ousmane Sarr',
        email: 'ousmane.sarr@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000105',
        address: 'Villa 20, Rue D',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-OUSMANE',
      ),
      const AppUser(
        id: 'habitant_aissatou_diop',
        fullName: 'Aissatou Diop',
        email: 'aissatou.diop@sama-gardiennage.sn',
        type: AppUserType.habitant,
        isActive: true,
        phone: '770000106',
        address: 'Appartement 2A',
        quartierId: 'quartier_medina',
        quartierName: 'Quartier Medina',
        qrCode: 'SAMA-HABITANT-AISSATOU',
      ),
    ];

    final batch = _firestore.batch();
    for (final habitant in habitants) {
      batch.set(_firestore.collection('users').doc(habitant.id), {
        ...habitant.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'seededAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> savePaymentRecord(PaymentRecord payment) {
    return _savePaymentInternal(payment);
  }

  Future<void> _savePaymentInternal(PaymentRecord payment) async {
    final paymentId = PaymentRecord.periodDocumentId(
      habitantId: payment.habitantId,
      month: payment.month,
      year: payment.year,
    );
    final paymentRef = _firestore.collection(_paymentCollection).doc(paymentId);

    // Compatibilité avec les anciens reçus, créés avant l'identifiant stable.
    // Ils doivent également empêcher un second encaissement de la période.
    final residentPayments = await _firestore
        .collection(_paymentCollection)
        .where('habitantId', isEqualTo: payment.habitantId)
        .get();
    final hasLegacyPaidPayment = residentPayments.docs.any((document) {
      final existingPayment = PaymentRecord.fromFirestore(
        document.id,
        document.data(),
      );
      return document.id != paymentId &&
          existingPayment.year == payment.year &&
          existingPayment.month == payment.month &&
          existingPayment.isPaid;
    });
    if (hasLegacyPaidPayment) {
      throw const DuplicatePaymentException();
    }

    // Le document est identifié par habitant + année + mois. La transaction
    // protège aussi les doubles validations provenant de deux écrans ouverts.
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(paymentRef);
      if (existing.exists) {
        final data = existing.data();
        if ((data?['status'] ?? '').toString().trim().toLowerCase() == 'paye') {
          throw const DuplicatePaymentException();
        }
      }

      transaction.set(paymentRef, {
        ...payment.toFirestore(),
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    // Notify listeners that data changed (e.g., a payment was recorded).
    try {
      _changesController.add(null);
    } catch (_) {}
  }

  Future<void> createHabitant(AppUser habitant) {
    return _firestore.collection('users').doc(habitant.id).set({
      ...habitant.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> findActiveHabitantByQrCode(String qrCode) async {
    final snapshot = await _firestore
        .collection('users')
        .where('qrCode', isEqualTo: qrCode.trim())
        .where('type', isEqualTo: AppUserType.habitant.value)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return AppUser.fromFirestore(doc.id, doc.data());
  }

  Future<AppUser?> findActiveUserByEmailAndPin({
    required String email,
    required String pin,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .where('pin', isEqualTo: pin.trim())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return AppUser.fromFirestore(doc.id, doc.data());
  }

  Future<AppUser?> findActiveCollectorByQrCode(String qrCode) async {
    final snapshot = await _firestore
        .collection('users')
        .where('qrCode', isEqualTo: qrCode.trim())
        .where('type', isEqualTo: AppUserType.collecteur.value)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return AppUser.fromFirestore(doc.id, doc.data());
  }

  Future<void> saveAppUserLoginTrace(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('userId', user.id);
    await preferences.setString('userName', user.fullName);
    await preferences.setString('userType', user.type.value);
  }

  Future<List<AppUser>> fetchHabitants() async {
    final snapshot = await _firestore
        .collection('users')
        .where('type', isEqualTo: AppUserType.habitant.value)
        .where('isActive', isEqualTo: true)
        .get(const GetOptions(source: Source.server));

    final habitants = snapshot.docs
        .map((doc) => AppUser.fromFirestore(doc.id, doc.data()))
        .toList();
    habitants.sort((a, b) => a.fullName.compareTo(b.fullName));
    return habitants;
  }

  Future<List<PaymentRecord>> fetchPaymentHistory(String habitantId) async {
    final snapshot = await _firestore
        .collection(_paymentCollection)
        .where('habitantId', isEqualTo: habitantId)
        .get(const GetOptions(source: Source.server));

    final payments = snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc.id, doc.data()))
        .toList();
    payments.sort((a, b) {
      final periodA = a.year * 100 + a.month;
      final periodB = b.year * 100 + b.month;
      final periodComparison = periodB.compareTo(periodA);
      if (periodComparison != 0) return periodComparison;
      final aDate = a.paidAt ?? DateTime(1900);
      final bDate = b.paidAt ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
    print(
      'Fetched ${payments.length} payment records for habitant $habitantId',
    );
    return payments;
  }

  Future<List<PaymentRecord>> fetchPaymentsForYear(int year) async {
    final snapshot = await _firestore
        .collection(_paymentCollection)
        .where('year', isEqualTo: year)
        .get(const GetOptions(source: Source.server));
    final payments = snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc.id, doc.data()))
        .toList();
    payments.sort((a, b) {
      final periodA = a.year * 100 + a.month;
      final periodB = b.year * 100 + b.month;
      return periodB.compareTo(periodA);
    });
    return payments;
  }
}
