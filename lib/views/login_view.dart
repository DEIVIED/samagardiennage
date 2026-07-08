import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import '../models/collector.dart';
import '../models/login_credentials.dart';
import 'qr_scanner_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const Color _navy = Color(0xFF172747);
  static const Color _gold = Color(0xFFF5A817);
  static const Color _surface = Color(0xFFF4F2EC);

  final LoginController _controller = LoginController();
  final TextEditingController _emailController = TextEditingController(
    text: 'admin@sama-gardiennage.sn',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'password',
  );

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAdminLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.firebaseError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Firebase non configuré: ${widget.firebaseError.toString()}',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final credentials = LoginCredentials(
      email: _emailController.text,
      password: _passwordController.text,
    );
    final result = await _controller.loginAdmin(credentials);

    if (!mounted) return;
    setState(() => _isLoading = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Connexion administrateur en cours...'
              : result.message ?? 'Connexion impossible.',
        ),
      ),
    );
  }

  Future<void> _scanQrCode() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.firebaseError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Firebase non configuré: ${widget.firebaseError.toString()}',
          ),
        ),
      );
      return;
    }

    final collector = await Navigator.of(context).push<Collector>(
      MaterialPageRoute(
        builder: (_) => QrScannerView(loginController: _controller),
      ),
    );

    if (!mounted) return;
    if (collector != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Bienvenue ${collector.fullName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: _surface,
              child: Column(
                children: [
                  const _LoginHeader(navy: _navy, gold: _gold),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 30, 32, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'CONNEXION ADMINISTRATEUR',
                            style: TextStyle(
                              color: Color(0xFF566073),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _LabeledField(
                            label: 'Adresse email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          _LabeledField(
                            label: 'Mot de passe',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submitAdminLogin,
                            child: _isLoading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 28),
                          const _DividerLabel(),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: const Color(0xFF201706),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _scanQrCode,
                            icon: const Icon(Icons.qr_code_2, size: 20),
                            label: const Text(
                              'Scanner mon QR Code',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Collecteur ? Utilisez votre QR Code personnel',
                      style: TextStyle(
                        color: Color(0xFF7C8490),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.navy, required this.gold});

  final Color navy;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 215,
      width: double.infinity,
      decoration: BoxDecoration(
        color: navy,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            child: Container(
              width: 126,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B36),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.shield_outlined, color: navy, size: 30),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sama Gardiennage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'COLLECTE SECURISEE',
                style: TextStyle(
                  color: Color(0xFFD9DEE9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF22314E),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(
            color: Color(0xFF172747),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC8CED8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC8CED8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF172747),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFD4D1CA))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou',
            style: TextStyle(
              color: Color(0xFF8A8D92),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD4D1CA))),
      ],
    );
  }
}
