import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event.dart';

// FIRESTORE INSTANCE

final FirebaseFirestore _db = FirebaseFirestore.instance;

// 1. SERVICE PROVIDER
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

class EventService {
  Future<void> createEvent(Event event) async {
    await _db.collection('events').add({
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
      'location': event.location,
      'totalSeats': event.totalSeats,
      'availableSeats': event.availableSeats,
      'organizerId': event.organizerId,
      'isFeatured': event.isFeatured,

      // 💰 Ticket system (FULL SUPPORT)
      'ticketPrice': event.ticketPrice,
      'isPaidEvent': event.ticketPrice > 0,
      'currency': event.currency,
    });
  }
}

// 2. STATE PROVIDERS
final searchQueryProvider = StateProvider<String>((ref) => '');

// 3. STREAM PROVIDERS
// Featured Events
final featuredEventsProvider = StreamProvider<List<Event>>((ref) {
  return _db
      .collection('events')
      .where('isFeatured', isEqualTo: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => _mapFirestoreToEvent(doc)).toList());
});