import '../entities/event.dart';

// The Interface (Contract)
abstract class EventRepository {
  Stream<List<Event>> getAllEvents();
  Future<void> saveEvent(Event event);
  Future<void> deleteEvent(String id);
}