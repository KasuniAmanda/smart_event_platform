// ============================================================
// File: event_service.dart
// Assigned to: Member 3 (Database & Data Layer)
// ============================================================


import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to get events in real-time
  Stream<List<Event>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      // Explicitly telling Dart this is a List of Events
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          location: data['location'] ?? 'No Location Provided', 
          totalSeats: data['totalSeats'] ?? 0,
          availableSeats: data['availableSeats'] ?? 0,
          organizerId: data['organizerId'] ?? '',
        );
      }).toList(); 
    });
  }

  Future<void> createEvent(Event event) async {}

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }
}

// Handles Firestore event data by streaming real-time updates, mapping documents to Event objects, and supporting event deletion.
//