import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isScanned = false;

  void _handleScan(BarcodeCapture capture) {
    if (isScanned) return;

    final barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final String? value = barcodes.first.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() {
      isScanned = true;
    });

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A2B),
        foregroundColor: Colors.white,
        title: const Text(
          "Scan Patient QR",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleScan),

          Center(
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF18C8C8), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          Positioned(
            left: 30,
            right: 30,
            bottom: 45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF18C8C8),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Scan Patient QR Code",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Place the QR code inside the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
