import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to access ticket validation logic
final ticketValidationProvider = Provider((ref) => TicketValidationLogic());

// Result model to pass data back to the UI
class ScanResult {
  final String title;
  final String message;
  final bool success;
  final bool alreadyScanned;

  ScanResult({required this.title, required this.message, this.success = false, this.alreadyScanned = false});
}

class TicketValidationLogic {
  final _db = FirebaseFirestore.instance;

  Future<ScanResult> validateTicket(String ticketId) async {
    try {
      final ticketDoc = await _db.collection('tickets').doc(ticketId).get();

      if (!ticketDoc.exists) {
        return ScanResult(
          title: "Invalid Ticket",
          message: "This ticket does not exist in our records.",
        );
      }

      final data = ticketDoc.data() as Map<String, dynamic>;
      final String status = (data['status'] ?? 'valid').toString().toLowerCase();

      if (status == 'scanned') {
        return ScanResult(
          title: "Already Used",
          message: "This ticket was already scanned!",
          alreadyScanned: true,
        );
      } else {
        // Update database
        await ticketDoc.reference.update({
          'status': 'Scanned',
          'checkInTime': FieldValue.serverTimestamp(),
        });

        return ScanResult(
          title: "Entry Allowed",
          message: "Ticket is valid. Welcome to the event!",
          success: true,
        );
      }
    } catch (e) {
      return ScanResult(title: "Error", message: "Database error: $e");
    }
  }
}