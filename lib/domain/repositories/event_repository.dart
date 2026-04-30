import '../entities/event.dart';

// The Interface (Contract)
abstract class EventRepository {
  Stream<List<Event>> getAllEvents();
  Future<void> saveEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<void> toggleFavorite(Event event, String userId);
  Future<List<Event>> getBookmarkedEvents(String userId);
}