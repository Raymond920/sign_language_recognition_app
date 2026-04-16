import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sign_language_recognition_app/models/question_model.dart';
import 'package:sign_language_recognition_app/models/quiz_model.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lesson_model.dart';
import '../models/sign_model.dart';

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

  // 2. USER PROFILE: Single-user is now managed via SharedPreferences
  // This method is kept for reference but should be called from ProfileService instead

  // 3. LESSONS LIST: Get all lessons with calculated progress
  Future<List<Lesson>> getAllLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        l.*,
        (SELECT COUNT(*) FROM LESSON_SIGN ls WHERE ls.lesson_id = l.lesson_id) as sign_count,
        (
          SELECT COUNT(*) FROM SIGN_PROGRESS sp
          JOIN LESSON_SIGN ls ON sp.sign_id = ls.sign_id
          WHERE ls.lesson_id = l.lesson_id AND sp.is_completed = 1
        ) * 1.0 / 
        (SELECT COUNT(*) FROM LESSON_SIGN ls WHERE ls.lesson_id = l.lesson_id) as progress_percentage,
        COALESCE((SELECT is_completed FROM LESSON_PROGRESS WHERE lesson_id = l.lesson_id), 0) as is_completed,
        COALESCE((SELECT points_claimed FROM LESSON_PROGRESS WHERE lesson_id = l.lesson_id), 0) as points_claimed
      FROM LESSON l
    ''');

    return List.generate(maps.length, (i) => Lesson.fromMap(maps[i]));
  }

  // 4. LESSON CONTENT: Get all signs for a lesson + completion status
  Future<List<Sign>> getSignsForLesson(int lessonId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, 
      COALESCE((SELECT is_completed FROM SIGN_PROGRESS sp 
       WHERE sp.sign_id = s.sign_id), 0) as done
      FROM SIGN s
      JOIN LESSON_SIGN ls ON s.sign_id = ls.sign_id
      WHERE ls.lesson_id = ?
      ORDER BY ls.step_order ASC
    ''', [lessonId]);

    return maps.map((m) => Sign.fromMap(m, m['done'] == 1)).toList();
  }

  Future<List<Sign>> getAllSigns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*,
      COALESCE((SELECT is_completed FROM SIGN_PROGRESS sp WHERE sp.sign_id = s.sign_id), 0) as done
      FROM SIGN s
    ''');

    return maps.map((m) => Sign.fromMap(m, m['done'] == 1)).toList();
  }

  // 5. UPDATE PROGRESS: When a user finishes a sign correctly
  Future<void> updateSignProgress(int signId) async {
    final db = await database;
    await db.insert(
      'SIGN_PROGRESS',
      {
        'sign_id': signId,
        'is_completed': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 5b. UPDATE LESSON PROGRESS: Mark lesson as completed
  Future<void> updateLessonProgress(int lessonId) async {
    final db = await database;
    await db.insert(
      'LESSON_PROGRESS',
      {
        'lesson_id': lessonId,
        'is_completed': 1,
        'points_claimed': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 5c. CLAIM LESSON POINTS: Mark points as claimed for a lesson
  Future<void> claimLessonPoints(int lessonId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE LESSON_PROGRESS
      SET points_claimed = 1
      WHERE lesson_id = ?
    ''', [lessonId]);
  }

  // Get list of quizzes
  Future<List<Quiz>> getAllQuizzes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT q.*, 
        (SELECT COUNT(*) FROM QUESTION WHERE quiz_id = q.quiz_id) as q_count,
        COALESCE((SELECT best_score FROM QUIZ_PROGRESS WHERE quiz_id = q.quiz_id), 0) as best_score,
        COALESCE((SELECT points_claimed FROM QUIZ_PROGRESS WHERE quiz_id = q.quiz_id), 0) as points_claimed
      FROM QUIZ q
    ''');
    return maps.map((m) => Quiz.fromMap(m)).toList();
  }

  // Get questions for a specific quiz
  Future<List<QuizQuestion>> getQuestionsForQuiz(int quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT qu.*, s.image_path 
      FROM QUESTION qu
      JOIN SIGN s ON qu.sign_id = s.sign_id
      WHERE qu.quiz_id = ?
    ''', [quizId]);
    return maps.map((m) => QuizQuestion.fromMap(m)).toList();
  }

  // Save Score
  Future<void> updateQuizScore(int quizId, int newScore) async {
    final db = await database;
    await db.insert(
      'QUIZ_PROGRESS',
      {
        'quiz_id': quizId,
        'best_score': newScore,
        'points_claimed': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // CLAIM QUIZ POINTS: Mark points as claimed for a quiz
  Future<void> claimQuizPoints(int quizId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE QUIZ_PROGRESS
      SET points_claimed = 1
      WHERE quiz_id = ?
    ''', [quizId]);
  }
}