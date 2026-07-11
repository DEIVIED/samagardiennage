import '../models/app_user.dart';
import '../models/payment_record.dart';
import '../services/firestore_service.dart';

class HabitantsController {
  HabitantsController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  Future<List<AppUser>> fetchHabitants() {
    return _firestoreService.fetchHabitants();
  }

  Future<List<PaymentRecord>> fetchPaymentHistory(String habitantId) {
    return _firestoreService.fetchPaymentHistory(habitantId);
  }

  Future<void> savePayment(PaymentRecord payment) {
    return _firestoreService.savePaymentRecord(payment);
  }

  Future<void> createHabitant(AppUser habitant) {
    return _firestoreService.createHabitant(habitant);
  }

  Future<List<PaymentRecord>> fetchPaymentsForYear(int year) {
    return _firestoreService.fetchPaymentsForYear(year);
  }

  Future<AppUser?> findHabitantByQrCode(String qrCode) {
    return _firestoreService.findActiveHabitantByQrCode(qrCode);
  }
}
