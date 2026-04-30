import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/event.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table for Events (Caching) - Removed 'category'
    await db.execute('''
      CREATE TABLE cached_events (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        date TEXT,
        location TEXT
      )
    ''');

    // Table for Favorites (Relational Link)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT,
        user_id TEXT,
        FOREIGN KEY (event_id) REFERENCES cached_events (id) ON DELETE CASCADE
      )
    ''');
  }

  // Member 3: Cache the event details
  Future<void> cacheEvent(Event event) async {
    final db = await instance.database;
    await db.insert(
      'cached_events',
      {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'location': event.location,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addToFavorites(String eventId, String userId) async {
    final db = await instance.database;
    await db.insert(
      'favorites',
      {
        'event_id': eventId,
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT cached_events.* FROM cached_events
      INNER JOIN favorites ON cached_events.id = favorites.event_id
      WHERE favorites.user_id = ?
    ''', [userId]);
  }

  Future<bool> isFavorite(String eventId, String userId) async {
    final db = await instance.database;
    final res = await db.query('favorites', where: 'event_id = ? AND user_id = ?', whereArgs: [eventId, userId]);
    return res.isNotEmpty;
  }

  Future<void> removeFromFavorites(String eventId, String userId) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'event_id = ? AND user_id = ?', whereArgs: [eventId, userId]);
  }

  Future<List<Event>> getFavoriteEvents(String userId) async {
    final res = await getFavorites(userId);
    return res.map((e) => Event(
      id: e['id'] as String,
      title: e['title'] as String,
      description: e['description'] as String,
      date: DateTime.parse(e['date'] as String),
      location: e['location'] as String,
      totalSeats: 0,
      availableSeats: 0,
      organizerId: '',
    )).toList();
  }

  Future<void> clearCacheForEvent(String eventId) async {
    final db = await instance.database;
    await db.delete('cached_events', where: 'id = ?', whereArgs: [eventId]);
  }
}