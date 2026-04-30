import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Logic Provider: Gives access to the functions (Add/Delete)
final organizerLogicProvider = Provider((ref) => OrganizerLogic());

// 2. Data Provider: Automatically listens to Firebase and updates the UI
final organizerEventsStreamProvider = StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('events')
      .where('organizerId', isEqualTo: user.uid)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

class OrganizerLogic {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add Event Logic
  Future<void> createEvent({
    required String title,
    required String location,
    required int capacity,
    required DateTime date,
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
    });
  }

  // Delete Event Logic
  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}