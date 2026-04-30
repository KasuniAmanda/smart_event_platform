import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final bookingProvider = Provider((ref) => BookingNotifier());

class BookingNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<void> bookTicket(String eventId, String userId, String eventTitle) async {
    final ticketRef = _firestore.collection('tickets').doc();
    
    // 1. Remote Save (Firebase)
    await ticketRef.set({
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'userId': userId,
      'status': 'booked',
    });

    // 2. Local Save (Member 3: SQLite Relational Logic)
    final db = await _localDb.database;
    await db.insert('local_tickets', {
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'seatNumber': 0, // Simplified for now
    });
  }
}