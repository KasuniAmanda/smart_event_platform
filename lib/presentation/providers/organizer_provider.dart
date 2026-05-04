import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. LOGIC PROVIDER
final organizerLogicProvider = Provider((ref) => OrganizerLogic());

// 2. REACTIVE EVENTS STREAM
final organizerEventsStreamProvider =
    StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('events')
      .where('organizerId', isEqualTo: user.uid)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

// ORGANIZER LOGIC
class OrganizerLogic {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CREATE EVENT
  Future<void> createEvent({
    required String title,
    required String location,
    required int capacity,
    required DateTime date,

    // PAYMENT SUPPORT
    double ticketPrice = 0.0,
  }) async {
    await _db.collection('events').add({
      'title': title,
      'location': location,
      'totalSeats': capacity,
      'availableSeats': capacity,

      'organizerId': _auth.currentUser?.uid,

      'date': Timestamp.fromDate(date),

      'description': 'Event managed via Smart Event Platform',
      'createdAt': FieldValue.serverTimestamp(),

      // PAYMENT FIELDS
      'ticketPrice': ticketPrice,
      'isPaidEvent': ticketPrice > 0,
      'currency': 'LKR',
    });
  }

  // DELETE EVENT
  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}
