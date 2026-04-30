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
          location: data['location'] ?? 'No Location Provided', // Fixed Error 1
          totalSeats: data['totalSeats'] ?? 0,
          availableSeats: data['availableSeats'] ?? 0,
          organizerId: data['organizerId'] ?? '',
        );
      }).toList(); // Fixed Error 2 by ensuring correct mapping
    });
  }

  Future<void> createEvent(Event event) async {}
}