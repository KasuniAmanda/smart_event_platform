import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final bookingProvider = Provider((ref) => BookingNotifier());

class BookingNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<void> bookTicket(
    String eventId,
    String userId,
    String eventTitle, {
    String userEmail = 'unknown@user.com',
    double ticketPrice = 0.0,
    String currency = 'LKR',
  }) async {
    final ticketRef = _firestore.collection('tickets').doc();

    // 1. Save to Firebase (Remote)
    await ticketRef.set({
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userEmail': userEmail,
      'status': 'booked',
      'bookedAt': Timestamp.now(),

      // NEW FIELDS (IMPORTANT)
      'ticketPrice': ticketPrice,
      'currency': currency,
    });

    // 2. Save to Local SQLite (Offline support)
    final db = await _localDb.database;
    await db.insert('local_tickets', {
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'seatNumber': 0,

      // Optional but useful for offline usage
      'ticketPrice': ticketPrice,
      'eventTitle': eventTitle,
    });
  }
}