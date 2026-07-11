import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';

class HabitantQrScannerView extends StatefulWidget {
  const HabitantQrScannerView({super.key, required this.controller});

  final HabitantsController controller;

  @override
  State<HabitantQrScannerView> createState() => _HabitantQrScannerViewState();
}

class _HabitantQrScannerViewState extends State<HabitantQrScannerView> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });
    await _scannerController.stop();

    try {
      final habitant = await widget.controller.findHabitantByQrCode(rawValue);
      if (!mounted) return;

      if (habitant == null) {
        setState(() {
          _isProcessing = false;
          _successMessage = null;
          _errorMessage = 'QR Code invalide ou habitant introuvable.';
        });
        await _scannerController.start();
        return;
      }

      setState(() {
        _successMessage = 'Habitant trouvé: ${habitant.fullName}';
        _errorMessage = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      Navigator.of(context).pop<AppUser>(habitant);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _successMessage = null;
        _errorMessage = 'Lecture impossible: ${error.toString()}';
      });
      await _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101A31),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101A31),
        foregroundColor: Colors.white,
        title: const Text('Scanner habitant'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          const _ScannerFrame(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              children: [
                if (_successMessage != null) ...[
                  _ScannerMessage(
                    message: _successMessage!,
                    color: const Color(0xFF2E8B57),
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 14),
                ],
                if (_errorMessage != null) ...[
                  _ScannerMessage(
                    message: _errorMessage!,
                    color: Colors.red.shade700,
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Recherche de l'habitant...",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Placez le QR Code de l'habitant dans le cadre.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerMessage extends StatelessWidget {
  const _ScannerMessage({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF5A817), width: 4),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
