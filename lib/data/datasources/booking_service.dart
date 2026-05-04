// ============================================================
// File: booking_service.dart
// Assigned to: Member 3 (Database & Data Layer)
// ============================================================


import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///  Method to Book a Ticket
  Future<void> bookTicket({
    required String eventId,
    required String userId,
    required String userEmail,
    required double ticketPrice, // NEW: Pass the price from EventDetailsScreen
  }) async {
    final ticketRef = _db.collection('tickets').doc();
    WriteBatch batch = _db.batch();

    // Add the ticket document with financial data
    batch.set(ticketRef, {
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'userId': userId,
      'userEmail': userEmail,
      'bookedAt': Timestamp.now(),
      'status': 'valid', 
      'ticketPrice': ticketPrice, //  NEW: Saved for Revenue calculation
    });

    // Decrement available seats by 1
    DocumentReference eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'availableSeats': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  ///  Method to Cancel a Booking
  Future<void> cancelBooking({
    required String ticketId,
    required String eventId,
  }) async {
    WriteBatch batch = _db.batch();

    DocumentReference ticketRef = _db.collection('tickets').doc(ticketId);
    batch.delete(ticketRef);

    DocumentReference eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'availableSeats': FieldValue.increment(1),
    });

    await batch.commit();
  }
}
//
//