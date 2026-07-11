class LoginCredentials {
  const LoginCredentials({required this.email, required this.pin});

  final String email;
  final String pin;

  bool get isValid => email.trim().isNotEmpty && pin.trim().isNotEmpty;
}
