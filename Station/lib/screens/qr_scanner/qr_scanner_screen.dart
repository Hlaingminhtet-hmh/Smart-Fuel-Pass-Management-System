import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../vehicle_verification/vehicle_verification_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCode(String value) {
    if (_handled || value.trim().isEmpty) return;
    _handled = true;
    _controller.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VehicleVerificationScreen(qrPayload: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Vehicle QR'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null) {
                  _handleCode(value);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Card(
              color: Colors.black.withValues(alpha: .75),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position the vehicle QR code inside the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Petro Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
