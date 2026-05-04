// Tests for StudyTrackerService - auto-generated via Copilot

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';

void main() {
	group('StudyTrackerService', () {
		setUp(() async {
			SharedPreferences.setMockInitialValues({});
			await StudyTrackerService.clearSessions();
		});

		test('recordStudySession() saves duration correctly to SharedPreferences',
				() async {
			// Arrange
			const durationSeconds = 900;

			// Act
			await StudyTrackerService.recordStudySession(durationSeconds);
			final prefs = await SharedPreferences.getInstance();
			final sessions = prefs.getStringList('study_sessions') ?? <String>[];
			final firstSession = jsonDecode(sessions.first) as Map<String, dynamic>;

			// Assert
			expect(sessions.length, 1);
			expect(firstSession['duration'], durationSeconds);
			expect(firstSession['date'], isA<String>());
		});

		test('getTotalStudyTimeInHours() returns correct hours from accumulated sessions',
				() async {
			// Arrange
			final now = DateTime.now().toIso8601String();
			SharedPreferences.setMockInitialValues({
				'study_sessions': <String>[
					jsonEncode({'date': now, 'duration': 1800}),
					jsonEncode({'date': now, 'duration': 5400}),
				],
			});

			// Act
			final hours = await StudyTrackerService.getTotalStudyTimeInHours();

			// Assert
			expect(hours, closeTo(2.0, 0.0001));
		});

		test('calculateDayStreak() returns 1 for activity only today', () async {
			// Arrange
			final now = DateTime.now().toIso8601String();
			SharedPreferences.setMockInitialValues({
				'study_sessions': <String>[
					jsonEncode({'date': now, 'duration': 600}),
				],
			});

			// Act
			final streak = await StudyTrackerService.calculateDayStreak();

			// Assert
			expect(streak, 1);
		});

		test('calculateDayStreak() correctly counts consecutive days', () async {
			// Arrange
			final today = DateTime.now();
			final day0 = today.toIso8601String();
			final day1 = today.subtract(const Duration(days: 1)).toIso8601String();
			final day2 = today.subtract(const Duration(days: 2)).toIso8601String();

			SharedPreferences.setMockInitialValues({
				'study_sessions': <String>[
					jsonEncode({'date': day0, 'duration': 300}),
					jsonEncode({'date': day1, 'duration': 300}),
					jsonEncode({'date': day2, 'duration': 300}),
					jsonEncode({'date': day1, 'duration': 120}),
				],
			});

			// Act
			final streak = await StudyTrackerService.calculateDayStreak();

			// Assert
			expect(streak, 3);
		});

		test('calculateDayStreak() resets to 0 when streak is broken', () async {
			// Arrange
			final yesterday =
					DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
			final twoDaysAgo =
					DateTime.now().subtract(const Duration(days: 2)).toIso8601String();

			SharedPreferences.setMockInitialValues({
				'study_sessions': <String>[
					jsonEncode({'date': yesterday, 'duration': 400}),
					jsonEncode({'date': twoDaysAgo, 'duration': 400}),
				],
			});

			// Act
			final streak = await StudyTrackerService.calculateDayStreak();

			// Assert
			expect(streak, 0);
		});

		test('getLessonsCompletedToday() returns correct count for today only',
				() async {
			// Arrange
			final today = DateTime.now().toIso8601String();
			final yesterday =
					DateTime.now().subtract(const Duration(days: 1)).toIso8601String();

			SharedPreferences.setMockInitialValues({
				'lesson_completions': <String>[
					jsonEncode({'lesson_id': 1, 'completed_at': today}),
					jsonEncode({'lesson_id': 2, 'completed_at': today}),
					jsonEncode({'lesson_id': 2, 'completed_at': today}),
					jsonEncode({'lesson_id': 99, 'completed_at': yesterday}),
				],
			});

			// Act
			final count = await StudyTrackerService.getLessonsCompletedToday();

			// Assert
			expect(count, 2);
		});

		test('recordLessonCompletion() increments today\'s lesson count', () async {
			// Arrange
			final beforeCount = await StudyTrackerService.getLessonsCompletedToday();

			// Act
			await StudyTrackerService.recordLessonCompletion(7);
			final afterCount = await StudyTrackerService.getLessonsCompletedToday();

			// Assert
			expect(beforeCount, 0);
			expect(afterCount, 1);
		});
	});
}
