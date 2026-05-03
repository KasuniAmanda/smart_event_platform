// ============================================================
// File: event_repository_impl.dart
// Assigned to: Member 3 (Database & Data Layer)
// ============================================================
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_service.dart'; // Firebase
import '../datasources/local_database.dart'; // SQLite

class EventRepositoryImpl implements EventRepository {
  final EventService remoteDataSource;
  final LocalDatabase localDataSource;

  EventRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<List<Event>> getAllEvents() {
    // This stream fetches real-time data from Firebase.
    return remoteDataSource.getEvents();
  }

  @override
  Future<void> saveEvent(Event event) async {
    // Ensuring the new ticketPrice and currency are sent to Firebase.
    await remoteDataSource.createEvent(event);
  }

  //UPDATED: Relational logic 
  @override
  Future<void> toggleFavorite(Event event, String userId) async {
    final isFavorite = await localDataSource.isFavorite(event.id, userId);

    if (isFavorite) {
      await localDataSource.removeFromFavorites(event.id, userId);
    } else {
      // Member 3 Viva Point: Caching includes new financial metadata (ticketPrice, currency).
      // This ensures the local 'cached_events' table stays synced with the new schema.
      await localDataSource.cacheEvent(event);
      
      // Link it in the 'favorites' table (Relational link)
      await localDataSource.addToFavorites(event.id, userId);
    }
  }

  @override
  Future<List<Event>> getBookmarkedEvents(String userId) async {
    // Member 3 Viva Point: Proving relational JOIN queries in SQLite.
    // The JOIN now also returns ticketPrice and currency for offline viewing.
    return await localDataSource.getFavoriteEvents(userId);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await remoteDataSource.deleteEvent(id);
    // Cleanup local cache using 'ON DELETE CASCADE' equivalent logic.
    await localDataSource.clearCacheForEvent(id);
  }
}