class LoginCredentials {
  const LoginCredentials({required this.email, required this.password});

  final String email;
  final String password;

  bool get isValid => email.trim().isNotEmpty && password.isNotEmpty;
}
