// ============================================================
// File: db_helper.dart
// Assigned to: Member 3 (Database & Data Layer)
// ============================================================
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'smart_event.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ✅ RELATIONAL STRUCTURE: 2 Related Tables
  Future<void> _createDB(Database db, int version) async {
    // Table 1: Cached Events
    await db.execute('''
      CREATE TABLE cached_events (
        id TEXT PRIMARY KEY,
        title TEXT,
        date TEXT,
        location TEXT,
        organizerId TEXT
      )
    ''');

    // Table 2: Favorites (Related to Table 1 via eventId)
    await db.execute('''
      CREATE TABLE favorites (
        favId INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId TEXT,
        userId TEXT,
        FOREIGN KEY (eventId) REFERENCES cached_events (id) ON DELETE CASCADE
      )
    ''');
  }
}