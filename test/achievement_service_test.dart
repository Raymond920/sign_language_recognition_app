// Tests for AchievementService - auto-generated via Copilot

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_recognition_app/services/achivement_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementService', () {
    late AchievementService achievementService;
    late DBHelper dbHelper;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Seed ffi DB location with the real production SQLite asset.
      final dbDir = await getDatabasesPath();
      final targetDbPath = p.join(dbDir, 'msl_database.db');
      final assetDb = File(p.join('assets', 'db', 'msl_database.db'));

      await Directory(dbDir).create(recursive: true);
      if (await File(targetDbPath).exists()) {
        await File(targetDbPath).delete();
      }
      await assetDb.copy(targetDbPath);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      achievementService = AchievementService();
      dbHelper = DBHelper();

      // Ensure DB exists and user progress state is clean for each test.
      await dbHelper.database;
      await dbHelper.resetLearningProgress();
      await StudyTrackerService.clearSessions();

      achievementService.achievementUnlockedNotifier.value = null;
    });

    test('getAchievementStatusMap() returns a map with expected achievement keys',
        () async {
      // Arrange
      const expectedKeys = <String>{
        'first_lesson',
        'alphabet_master',
        'number_master',
        'number_ninja',
        'alphabet_ninja',
        'quick_learner',
        'perfect_score',
        'streak_master',
      };

      // Act
      final statusMap = await achievementService.getAchievementStatusMap();

      // Assert
      expect(statusMap.keys.toSet(), expectedKeys);
    });

    test('isAchievementEarned() returns false initially for all achievements',
        () async {
      // Arrange
      final achievementIds = AchievementService.allAchievements.map((a) => a.id);

      // Act
      final earnedStatuses = <bool>[];
      for (final id in achievementIds) {
        earnedStatuses.add(await achievementService.isAchievementEarned(id));
      }

      // Assert
      expect(earnedStatuses.every((value) => value == false), isTrue);
    });

    test('checkAllAchievements() does not throw on first run with no data', () async {
      // Arrange
      // No lesson/quiz/study progress is inserted.

      // Act
      final action = achievementService.checkAllAchievements();

      // Assert
      await expectLater(action, completes);
    });

    test('checkAllAchievements() unlocks streak achievement when streak >= threshold',
        () async {
      // Arrange
      final today = DateTime.now();
      final sessions = List<String>.generate(
        7,
        (index) => jsonEncode({
          'date': today.subtract(Duration(days: index)).toIso8601String(),
          'duration': 600,
        }),
      );
      SharedPreferences.setMockInitialValues({'study_sessions': sessions});

      // Act
      await achievementService.checkAllAchievements();
      final earned = await achievementService.isAchievementEarned('streak_master');

      // Assert
      expect(earned, isTrue);
    });

    test('checkAllAchievements() unlocks lesson completion achievement when count met',
        () async {
      // Arrange
      final lessons = await dbHelper.getAllLessons();
      expect(lessons, isNotEmpty);
      await dbHelper.updateLessonProgress(lessons.first.id);

      // Act
      await achievementService.checkAllAchievements();
      final earned = await achievementService.isAchievementEarned('first_lesson');

      // Assert
      expect(earned, isTrue);
    });

    test('checkAllAchievements() does not re-unlock already earned achievements',
        () async {
      // Arrange
      final lessons = await dbHelper.getAllLessons();
      expect(lessons, isNotEmpty);
      await dbHelper.updateLessonProgress(lessons.first.id);

      // Act
      await achievementService.checkAllAchievements();
      final firstPassEarned =
          await achievementService.isAchievementEarned('first_lesson');

      final stopwatch = Stopwatch()..start();
      await achievementService.checkAllAchievements();
      stopwatch.stop();

      final secondPassEarned =
          await achievementService.isAchievementEarned('first_lesson');

      // Assert
      expect(firstPassEarned, isTrue);
      expect(secondPassEarned, isTrue);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('getAchievementStatusMap() reflects updated status after checkAllAchievements()',
        () async {
      // Arrange
      final lessons = await dbHelper.getAllLessons();
      expect(lessons, isNotEmpty);
      await dbHelper.updateLessonProgress(lessons.first.id);

      // Act
      await achievementService.checkAllAchievements();
      final statusMap = await achievementService.getAchievementStatusMap();

      // Assert
      expect(statusMap['first_lesson'], isTrue);
      expect(statusMap['streak_master'], isFalse);
    });
  });
}