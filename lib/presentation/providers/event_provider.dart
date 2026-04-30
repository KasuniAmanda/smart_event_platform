import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/event.dart';

// ----------------------------------------------------------------             
// 1. SERVICE PROVIDER (Handles Writing to Firestore)
// ----------------------------------------------------------------             

final eventServiceProvider = Provider((ref) => EventService());

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Logic to add a new event to the Singapore Data Center
  Future<void> createEvent(Event event) async {
    await _db.collection('events').add({
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
      'location': event.location,
      'totalSeats': event.totalSeats,
      'availableSeats': event.availableSeats,
      'organizerId': event.organizerId,
      'isFeatured': event.isFeatured, // ✅ NEW: Save featured status
    });
  }
}

// ----------------------------------------------------------------             
// 2. STATE PROVIDERS (Handles Search & UI State)
// ----------------------------------------------------------------             

// Keeps track of the search bar text
final searchQueryProvider = StateProvider<String>((ref) => '');

// ----------------------------------------------------------------             
// 3. STREAM PROVIDERS (Handles Reading from Firestore)
// ----------------------------------------------------------------             

// 🌟 FEATURED API: Listens only to highlighted events for the top carousel
final featuredEventsProvider = StreamProvider<List<Event>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('isFeatured', isEqualTo: true) // ✅ Query optimization
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => _mapFirestoreToEvent(doc)).toList();
  });
});

// BASE STREAM: Listens to every event in real-time for the main feed
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .orderBy('date', descending: false) // Show upcoming events first
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => _mapFirestoreToEvent(doc)).toList();
  });
});

// ----------------------------------------------------------------             
// 4. FILTERED PROVIDER (The "Smart" Search Logic)
// ----------------------------------------------------------------             

final filteredEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(eventsStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return eventsAsync.whenData((events) {
    if (query.isEmpty) return events;
    
    return events.where((event) {
      final titleMatch = event.title.toLowerCase().contains(query);
      final locationMatch = event.location.toLowerCase().contains(query);
      return titleMatch || locationMatch;
    }).toList();
  });
});

// ----------------------------------------------------------------             
// 5. HELPER MAPPING (Ensures clean code and consistency)
// ----------------------------------------------------------------             

Event _mapFirestoreToEvent(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Event(
    id: doc.id,
    title: data['title'] ?? 'Untitled Event',
    description: data['description'] ?? '',
    date: (data['date'] as Timestamp).toDate(),
    location: data['location'] ?? 'TBD',
    totalSeats: data['totalSeats'] ?? 0,
    availableSeats: data['availableSeats'] ?? 0,
    organizerId: data['organizerId'] ?? '',
    isFeatured: data['isFeatured'] ?? false, // ✅ Map the featured field
  );
}