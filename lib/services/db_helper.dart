import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lesson_model.dart';
import '../models/sign_model.dart';
import '../models/user_model.dart';

class DBHelper {
  // Singleton pattern: ensures only one instance of DBHelper exists
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // 1. INITIALIZATION: Copies the DB from assets to the device
  Future<Database> _initDB() async {
    var dbPath = await getDatabasesPath();
    var path = join(dbPath, "msl_database.db");

    // Check if it exists. If not, copy it.
    bool exists = await databaseExists(path);

    if (!exists) {
      print("Creating copy of database from assets...");
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join("assets/db", "msl_database.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("Error copying database: $e");
      }
    }
    return await openDatabase(path);
  }

  // 2. USER PROFILE: Get the single local user
  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('USER', where: 'user_id = 1');
    return UserProfile.fromMap(maps.first);
  }

  // 3. LESSONS LIST: Get all lessons with calculated progress
  Future<List<Lesson>> getAllLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        l.*,
        (SELECT COUNT(*) FROM LESSON_SIGN ls WHERE ls.lesson_id = l.lesson_id) as sign_count,
        (
          SELECT COUNT(*) FROM USER_PROGRESS up 
          WHERE up.lesson_id = l.lesson_id AND up.is_completed = 1 AND up.user_id = 1
        ) * 1.0 / 
        (SELECT COUNT(*) FROM LESSON_SIGN ls WHERE ls.lesson_id = l.lesson_id) as progress_percentage
      FROM LESSON l
    ''');

    return List.generate(maps.length, (i) => Lesson.fromMap(maps[i]));
  }

  // 4. LESSON CONTENT: Get all signs for a lesson + completion status
  Future<List<Sign>> getSignsForLesson(int lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, 
      (SELECT is_completed FROM USER_PROGRESS up 
       WHERE up.sign_id = s.sign_id AND up.lesson_id = ? AND up.user_id = 1) as done
      FROM SIGN s
      JOIN LESSON_SIGN ls ON s.sign_id = ls.sign_id
      WHERE ls.lesson_id = ?
      ORDER BY ls.step_order ASC
    ''', [lessonId, lessonId]);

    return maps.map((m) => Sign.fromMap(m, m['done'] == 1)).toList();
  }

  Future<List<Sign>> getAllSigns() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('SIGN');

    return maps.map((m) => Sign.fromMap(m, false)).toList();
  }

  // 5. UPDATE PROGRESS: When a user finishes a sign correctly
  Future<void> updateSignProgress(int lessonId, int signId) async {
    final db = await database;
    await db.insert(
      'USER_PROGRESS',
      {
        'user_id': 1,
        'lesson_id': lessonId,
        'sign_id': signId,
        'is_completed': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}