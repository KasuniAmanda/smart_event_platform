import '../datasources/local_database.dart';

class SeatRepository {
  final LocalDatabase _dbHelper = LocalDatabase.instance;

  // Member 3: Initialize seats for an event (Relation logic)
  Future<void> initializeSeats(String eventId, int count) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    for (int i = 1; i <= count; i++) {
      batch.insert('local_tickets', {
        'ticketId': '${eventId}_$i',
        'eventId': eventId,
        'seatNumber': i,
      });
    }
    await batch.commit();
  }
}