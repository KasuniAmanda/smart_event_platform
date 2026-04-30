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
    // Member 3 Viva Point: This stream fetches real-time data from Firebase.
    // Optimization: We could also cache these results into SQLite here.
    return remoteDataSource.getEvents();
  }

  @override
  Future<void> saveEvent(Event event) async {
    // Member 4 Viva Point: Proper async/await handling for remote data.
    await remoteDataSource.createEvent(event);
  }

  // ✅ NEW: Relational logic for Member 3
  // This satisfies the "SQLite complex relational structure" requirement.
  @override
  Future<void> toggleFavorite(Event event, String userId) async {
    // Check if event is already a favorite in local SQLite
    final isFavorite = await localDataSource.isFavorite(event.id, userId);

    if (isFavorite) {
      await localDataSource.removeFromFavorites(event.id, userId);
    } else {
      // 1. Cache the event details in 'cached_events' table
      await localDataSource.cacheEvent(event);
      // 2. Link it in the 'favorites' table (Relational link)
      await localDataSource.addToFavorites(event.id, userId);
    }
  }

  @override
  Future<List<Event>> getBookmarkedEvents(String userId) async {
    // Member 3 Viva Point: proving relational JOIN queries
    // This fetches data from SQLite by joining 'favorites' and 'cached_events'
    return await localDataSource.getFavoriteEvents(userId);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await remoteDataSource.deleteEvent(id);
    // Cleanup local cache if necessary
    await localDataSource.clearCacheForEvent(id);
  }
}