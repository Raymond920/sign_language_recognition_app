import 'package:flutter/foundation.dart';
import 'package:sign_language_recognition_app/models/achievement_model.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sign_language_recognition_app/shared/widgets/achievemnt_banner.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final DBHelper _dbHelper = DBHelper();

  // 🔥 GLOBAL NOTIFIER: Broadcasts achievement unlock to entire app
  final ValueNotifier<Achievement?> achievementUnlockedNotifier = ValueNotifier<Achievement?>(null);

  // Define ALL achievements in your app
  static final List<Achievement> allAchievements = [
    Achievement(
      id: 'first_lesson',
      type: AchievementType.firstLesson,
      emoji: '🎯',
      title: 'First Steps',
      description: 'Completed first lesson',
    ),
    Achievement(
      id: 'alphabet_master',
      type: AchievementType.alphabetMaster,
      emoji: '🔡',
      title: 'Alphabet Master',
      description: 'Completed all alphabet lesson',
    ),
    Achievement(
      id: 'number_master',
      type: AchievementType.numberMaster,
      emoji: '🧮',
      title: 'Number Master',
      description: 'Completed all numbers lesson',
    ),
    Achievement(
      id: 'number_ninja',
      type: AchievementType.numberNinja,
      emoji: '🔢',
      title: 'Number Ninja',
      description: 'Get 100% in numbers quiz',
    ),
    Achievement(
      id: 'alphabet_ninja',
      type: AchievementType.alphabetNinja,
      emoji: '🔤',
      title: 'Alphabet Ninja',
      description: 'Get 100% in alphabet quiz',
    ),
    Achievement(
      id: 'quick_learner',
      type: AchievementType.quickLearner,
      emoji: '⚡',
      title: 'Quick Learner',
      description: 'Complete 5 lessons in one day',
    ),
    Achievement(
      id: 'perfect_score',
      type: AchievementType.perfectScore,
      emoji: '💯',
      title: 'Perfect Score',
      description: 'Get 100% in any quiz',
    ),
    Achievement(
      id: 'streak_master',
      type: AchievementType.streakMaster,
      emoji: '🔥',
      title: 'Streak Master',
      description: '7 day learning streak',
    ),
  ];

  /// Returns a map of achievement id -> earned state.
  Future<Map<String, bool>> getAchievementStatusMap() async {
    final statusMap = <String, bool>{};

    for (final achievement in allAchievements) {
      statusMap[achievement.id] = await isAchievementEarned(achievement.id);
    }

    return statusMap;
  }

  /// ✅ GET EARNED STATUS (used in UI to show isEarned flag)
  Future<bool> isAchievementEarned(String achievementId) async {
    return await _dbHelper.isAchievementEarned(achievementId);
  }

  /// 🎯 CHECK ALL ACHIEVEMENTS
  /// Call this after key actions (lesson complete, quiz passed, etc.)
  Future<void> checkAllAchievements() async {
    print('\n🏆 Checking all achievements...\n');

    for (var achievement in allAchievements) {
      bool alreadyEarned = await isAchievementEarned(achievement.id);

      if (alreadyEarned) {
        print('   ✅ ${achievement.title} - Already earned');
        continue;
      }

      // Check if conditions are met
      bool conditionMet = await _checkAchievementCondition(achievement.id);

      if (conditionMet) {
        // 🎉 Achievement unlocked!
        await _saveAchievementEarned(achievement.id);
        print('   🎉 UNLOCKED: ${achievement.title}!');
        
        // 📢 BROADCAST to entire app via notifier
        achievementUnlockedNotifier.value = achievement;
        showAchievementNotification('${achievement.emoji} ${achievement.title} unlocked');
        
        // Clear notification after 4 seconds
        await Future.delayed(Duration(seconds: 4), () {
          achievementUnlockedNotifier.value = null;
        });
      } else {
        print('   ❌ ${achievement.title} - Not yet unlocked');
      }
    }
    print('\n');
  }

  /// 🔍 CHECK CONDITIONS FOR EACH ACHIEVEMENT TYPE
  Future<bool> _checkAchievementCondition(String achievementId) async {
    final allLessons = await _dbHelper.getAllLessons();
    final allQuizzes = await _dbHelper.getAllQuizzes();
    final dayStreak = await StudyTrackerService.calculateDayStreak();

    bool hasQuizWithTitleAndScore(String keyword, int minScore) {
      final normalizedKeyword = keyword.toLowerCase();
      return allQuizzes.any(
        (q) => q.title.toLowerCase().contains(normalizedKeyword) && q.bestScore >= minScore,
      );
    }

    bool allCategoryLessonsCompleted(List<String> keywords) {
      final categoryLessons = allLessons.where((lesson) {
        final normalizedTitle = lesson.title.toLowerCase();
        return keywords.any(normalizedTitle.contains);
      }).toList();

      if (categoryLessons.isEmpty) {
        return false;
      }

      return categoryLessons.every(
        (lesson) => lesson.isCompleted && lesson.progress >= 1.0,
      );
    }

    switch (achievementId) {
      case 'first_lesson':
        // ✅ Unlocked when: At least 1 lesson completed
        return allLessons.where((l) => l.isCompleted).length >= 1;

      case 'alphabet_master':
        // ✅ Unlocked when: all alphabet lessons are completed
        return allCategoryLessonsCompleted(['alphabet']);

      case 'number_master':
        // ✅ Unlocked when: all number lessons are completed
        return allCategoryLessonsCompleted(['number', 'numbers']);

      case 'number_ninja':
        // ✅ Unlocked when: A quiz with title containing "Numbers" has 100%
        return hasQuizWithTitleAndScore('numbers', 100);

      case 'alphabet_ninja':
        // ✅ Unlocked when: A quiz with title containing "Alphabet" has 100%
        return hasQuizWithTitleAndScore('alphabet', 100);

      case 'quick_learner':
        // ✅ Unlocked when: 5 lessons completed in one day
        // (would need study_tracker to track "completed today")
        final lessonsCompletedToday = await StudyTrackerService.getLessonsCompletedToday();
        return lessonsCompletedToday >= 5;

      case 'perfect_score':
        // ✅ Unlocked when: Any quiz with 100%
        return allQuizzes.any((q) => q.bestScore == 100);

      case 'streak_master':
        // ✅ Unlocked when: 7-day streak
        return dayStreak >= 7;

      default:
        return false;
    }
  }

  /// 💾 SAVE ACHIEVEMENT TO DATABASE
  Future<void> _saveAchievementEarned(String achievementId) async {
    await _dbHelper.saveAchievementEarned(achievementId);
  }
}