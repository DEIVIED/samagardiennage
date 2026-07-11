import '../models/app_user.dart';
import '../models/login_credentials.dart';
import '../services/firestore_service.dart';

enum LoginStatus { success, invalidFields, firebaseNotConfigured, failed }

class LoginResult {
  const LoginResult({required this.status, this.message, this.user});

  final LoginStatus status;
  final String? message;
  final AppUser? user;

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
      final credential = await _firestoreService.signInFirebaseAdmin(
        email: credentials.email,
        password: credentials.pin,
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

  Future<LoginResult> loginWithEmailAndPin(LoginCredentials credentials) async {
    if (!credentials.isValid) {
      return const LoginResult(
        status: LoginStatus.invalidFields,
        message: 'Veuillez renseigner votre email et votre PIN.',
      );
    }

    try {
      final user = await _firestoreService.findActiveUserByEmailAndPin(
        email: credentials.email,
        pin: credentials.pin,
      );

      if (user == null) {
        return const LoginResult(
          status: LoginStatus.failed,
          message: 'Email ou PIN incorrect.',
        );
      }

      await _firestoreService.saveAppUserLoginTrace(user);
      return LoginResult(status: LoginStatus.success, user: user);
    } catch (error) {
      return LoginResult(
        status: LoginStatus.failed,
        message: 'Connexion impossible: ${error.toString()}',
      );
    }
  }

  Future<AppUser?> authenticateCollectorWithQrCode(String qrCode) async {
    final user = await _firestoreService.findActiveCollectorByQrCode(qrCode);
    if (user != null) {
      await _firestoreService.saveAppUserLoginTrace(user);
    }
    return user;
  }
}
