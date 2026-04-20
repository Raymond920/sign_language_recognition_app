import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudyTrackerService {
  static const String _sessionsKey = 'study_sessions';
  static const String _lessonCompletionsKey = 'lesson_completions';
  
  /// Record a study session (call when user completes a lesson/sign)
  static Future<void> recordStudySession(int durationSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_sessionsKey) ?? [];
    
    sessions.add(jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'duration': durationSeconds,
    }));
    
    await prefs.setStringList(_sessionsKey, sessions);
  }

  /// Record that a lesson was completed.
  /// The same lesson is counted once per day for achievement checks.
  static Future<void> recordLessonCompletion(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final completions = prefs.getStringList(_lessonCompletionsKey) ?? [];
    final todayString = DateTime.now().toIso8601String().split('T')[0];

    final alreadyRecordedToday = completions.any((entry) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        final completedAt = DateTime.parse(data['completed_at'] as String);
        final completedDay = completedAt.toIso8601String().split('T')[0];
        return (data['lesson_id'] as int? ?? -1) == lessonId &&
            completedDay == todayString;
      } catch (e) {
        return false;
      }
    });

    if (alreadyRecordedToday) {
      return;
    }

    completions.add(jsonEncode({
      'lesson_id': lessonId,
      'completed_at': DateTime.now().toIso8601String(),
    }));

    await prefs.setStringList(_lessonCompletionsKey, completions);
  }
  
  /// Get total study time in hours
  static Future<double> getTotalStudyTimeInHours() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_sessionsKey) ?? [];
    
    int totalSeconds = 0;
    for (var session in sessions) {
      try {
        final data = jsonDecode(session);
        totalSeconds += (data['duration'] as int? ?? 0);
      } catch (e) {
        print('❌ Error parsing session: $e');
      }
    }
    
    return totalSeconds / 3600; // Convert seconds to hours
  }
  
  /// Calculate current day streak (consecutive days of study)
  static Future<int> calculateDayStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = prefs.getStringList(_sessionsKey) ?? [];
    
    if (sessions.isEmpty) return 0;
    
    // Extract unique days (YYYY-MM-DD format)
    Set<String> uniqueDays = {};
    for (var session in sessions) {
      try {
        final data = jsonDecode(session);
        final dateStr = data['date'] as String;
        final date = DateTime.parse(dateStr);
        final dayString = date.toIso8601String().split('T')[0];
        uniqueDays.add(dayString);
      } catch (e) {
        print('❌ Error parsing date: $e');
      }
    }
    
    if (uniqueDays.isEmpty) return 0;
    
    // Sort days in descending order
    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));
    
    // Count consecutive days from today backwards
    int streak = 0;
    DateTime today = DateTime.now();
    String todayString = today.toIso8601String().split('T')[0];
    
    for (var day in sortedDays) {
      final expectedDay = today.subtract(Duration(days: streak));
      final expectedDayString = expectedDay.toIso8601String().split('T')[0];
      
      if (day == expectedDayString) {
        streak++;
      } else {
        break; // Streak is broken
      }
    }
    
    return streak;
  }

  /// Count how many unique lessons were completed today.
  static Future<int> getLessonsCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final completions = prefs.getStringList(_lessonCompletionsKey) ?? [];
    final todayString = DateTime.now().toIso8601String().split('T')[0];

    final todaysLessonIds = <int>{};

    for (var entry in completions) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        final completedAt = DateTime.parse(data['completed_at'] as String);
        final completedDay = completedAt.toIso8601String().split('T')[0];

        if (completedDay == todayString) {
          final lessonId = data['lesson_id'] as int?;
          if (lessonId != null) {
            todaysLessonIds.add(lessonId);
          }
        }
      } catch (e) {
        print('❌ Error parsing lesson completion: $e');
      }
    }

    return todaysLessonIds.length;
  }
  
  /// Clear all study sessions (for testing/debugging)
  static Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_lessonCompletionsKey);
    print('✅ Study sessions cleared');
  }
}
