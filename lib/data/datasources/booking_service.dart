import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🎫 Method to Book a Ticket
  Future<void> bookTicket({
    required String eventId,
    required String userId,
    required String userEmail,
  }) async {
    // 1. Create a reference for the new ticket
    final ticketRef = _db.collection('tickets').doc();

    // 2. Use a WriteBatch to ensure atomicity
    WriteBatch batch = _db.batch();

    // Add the ticket document
    batch.set(ticketRef, {
      'ticketId': ticketRef.id,
      'eventId': eventId,
      'userId': userId,
      'userEmail': userEmail,
      'bookedAt': Timestamp.now(),
      'status': 'valid', 
    });

    // Decrement available seats by 1
    DocumentReference eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'availableSeats': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// 🚫 Method to Cancel a Booking
  /// This returns the seat to the event pool and removes the ticket record.
  Future<void> cancelBooking({
    required String ticketId,
    required String eventId,
  }) async {
    // We use a WriteBatch again to keep data consistent
    WriteBatch batch = _db.batch();

    // 1. Delete the ticket document
    DocumentReference ticketRef = _db.collection('tickets').doc(ticketId);
    batch.delete(ticketRef);

    // 2. Increment available seats by 1 (returning the seat)
    DocumentReference eventRef = _db.collection('events').doc(eventId);
    batch.update(eventRef, {
      'availableSeats': FieldValue.increment(1),
    });

    await batch.commit();
  }
}