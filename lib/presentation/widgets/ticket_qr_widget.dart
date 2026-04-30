import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketQRWidget extends StatelessWidget {
  final String ticketId;

  const TicketQRWidget({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text("Show this at the entrance", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          QrImageView(
            data: ticketId,
            version: QrVersions.auto,
            size: 200.0,
            gapless: false,
          ),
          Text("ID: $ticketId", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}