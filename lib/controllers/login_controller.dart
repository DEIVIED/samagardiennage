import '../models/login_credentials.dart';
import '../models/collector.dart';
import '../services/firestore_service.dart';

enum LoginStatus {
  success,
  invalidFields,
  firebaseNotConfigured,
  failed,
}

class LoginResult {
  const LoginResult({
    required this.status,
    this.message,
  });

  final LoginStatus status;
  final String? message;

  bool get isSuccess => status == LoginStatus.success;
}

class LoginController {
  LoginController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  Future<LoginResult> loginAdmin(LoginCredentials credentials) async {
    if (!credentials.isValid) {
      return const LoginResult(
        status: LoginStatus.invalidFields,
        message: 'Veuillez renseigner vos identifiants.',
      );
    }

    try {
      final credential = await _firestoreService.signInAdmin(
        email: credentials.email,
        password: credentials.password,
      );
      final user = credential.user;
      if (user != null) {
        await _firestoreService.saveAdminLoginTrace(user);
      }
      return const LoginResult(status: LoginStatus.success);
    } catch (error) {
      return LoginResult(
        status: LoginStatus.failed,
        message: 'Connexion impossible: ${error.toString()}',
      );
    }
  }

  Future<Collector?> authenticateCollectorWithQrCode(String qrCode) async {
    final collector = await _firestoreService.findActiveCollectorByQrCode(
      qrCode,
    );
    if (collector != null) {
      await _firestoreService.saveCollectorLoginTrace(collector);
    }
    return collector;
  }
}
