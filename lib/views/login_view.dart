import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import '../models/app_user.dart';
import '../models/login_credentials.dart';
import 'collector_dashboard_view.dart';
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
  static const Color _success = Color(0xFF2E8B57);
  static const Color _danger = Color(0xFFD2473F);

  final LoginController _controller = LoginController();
  final TextEditingController _emailController = TextEditingController(
    text: 'moussa@sama-gardiennage.sn',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '1234',
  );

  bool _isLoading = false;
  bool _obscurePin = true;
  _LoginFeedbackData? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openDashboard(AppUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CollectorDashboardView(user: user)),
    );
  }

  void _showFeedback({required String message, required bool isSuccess}) {
    setState(() {
      _feedback = _LoginFeedbackData(message: message, isSuccess: isSuccess);
    });
  }

  Future<void> _submitLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.firebaseError != null) {
      _showFeedback(
        message: 'Firebase non configure. Verifiez google-services.json.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _feedback = null;
    });

    final credentials = LoginCredentials(
      email: _emailController.text,
      pin: _passwordController.text,
    );
    final result = await _controller.loginWithEmailAndPin(credentials);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isSuccess && result.user != null) {
      _showFeedback(
        message: 'Connexion reussie. Bienvenue ${result.user!.fullName}.',
        isSuccess: true,
      );
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: _success,
          content: Text('Connexion reussie: ${result.user!.fullName}'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      _openDashboard(result.user!);
      return;
    }

    _showFeedback(
      message: result.message ?? 'Connexion impossible.',
      isSuccess: false,
    );
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: _danger,
        content: Text(result.message ?? 'Connexion impossible.'),
      ),
    );
  }

  Future<void> _scanQrCode() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.firebaseError != null) {
      _showFeedback(
        message: 'Firebase non configure. Le scan QR est indisponible.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _feedback = null);
    final user = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => QrScannerView(loginController: _controller),
      ),
    );

    if (!mounted) return;
    if (user != null) {
      _showFeedback(
        message: 'QR Code valide. Bienvenue ${user.fullName}.',
        isSuccess: true,
      );
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: _success,
          content: Text('QR Code valide: ${user.fullName}'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      _openDashboard(user);
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
                            'CONNEXION UTILISATEUR',
                            style: TextStyle(
                              color: Color(0xFF566073),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (_feedback != null) ...[
                            _LoginFeedback(data: _feedback!),
                            const SizedBox(height: 18),
                          ],
                          _LabeledField(
                            label: 'Adresse email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          _LabeledField(
                            label: 'PIN',
                            controller: _passwordController,
                            obscureText: _obscurePin,
                            suffixIcon: IconButton(
                              tooltip: _obscurePin
                                  ? 'Afficher le PIN'
                                  : 'Masquer le PIN',
                              onPressed: () {
                                setState(() => _obscurePin = !_obscurePin);
                              },
                              icon: Icon(
                                _obscurePin
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
                            onPressed: _isLoading ? null : _submitLogin,
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

class _LoginFeedbackData {
  const _LoginFeedbackData({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;
}

class _LoginFeedback extends StatelessWidget {
  const _LoginFeedback({required this.data});

  final _LoginFeedbackData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isSuccess
        ? _LoginViewState._success
        : _LoginViewState._danger;
    final icon = data.isSuccess
        ? Icons.check_circle_outline
        : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
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
