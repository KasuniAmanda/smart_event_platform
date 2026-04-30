import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/scanner_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool isScanning = true;

  void _handleScan(String code) async {
    setState(() => isScanning = false);

    // ✅ CALL THE LOGIC LAYER
    final result = await ref.read(ticketValidationProvider).validateTicket(code);

    if (!mounted) return;

    // Determine color based on result
    Color dialogColor = Colors.red;
    if (result.success) dialogColor = Colors.green;
    if (result.alreadyScanned) dialogColor = Colors.orange;

    _showResultDialog(result, dialogColor);
  }

  void _showResultDialog(ScanResult result, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: color,
        title: Text(result.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(result.message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: const Text("Scan Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Entry QR"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (isScanning) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}