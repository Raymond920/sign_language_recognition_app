import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProfileService {
  // Define Keys to avoid typos
  static const String _keyProfileImagePath = 'profileImagePath';
  static const String _keyUsername = 'username';
  static const String _keyTotalPoints = 'totalPoints';

  // In-memory cache for instant reads in UI
  static String? _cachedProfileImagePath;
  static String _cachedUsername = 'MSL Learner';
  static int _cachedTotalPoints = 0;
  
  // ValueNotifier to notify when profile image changes
  static final ValueNotifier<String?> profileImageNotifier = ValueNotifier<String?>(null);
  // ValueNotifier to notify when username changes
  static final ValueNotifier<String> usernameNotifier = ValueNotifier<String>('MSL Learner');
  // ValueNotifier to notify when total points change
  static final ValueNotifier<int> totalPointsNotifier = ValueNotifier<int>(0);
  // ValueNotifier to notify when any quiz is completed with score >= 60%
  static final ValueNotifier<int> quizCompletionNotifier = ValueNotifier<int>(0);

  static String? get cachedProfileImagePath => _cachedProfileImagePath;
  static String get cachedUsername => _cachedUsername;
  static int get cachedTotalPoints => _cachedTotalPoints;

  // Get cached profile image as File (with validation)
  static File? get cachedProfileImage {
    if (_cachedProfileImagePath != null && _cachedProfileImagePath!.isNotEmpty) {
      final file = File(_cachedProfileImagePath!);
      // Only return if file actually exists
      if (file.existsSync()) {
        return file;
      } else {
        // File was deleted, clear the cache
        clearProfileImageSync();
        return null;
      }
    } else {
      return null;
    }
  }

  // Get cached profile image path (with file validation)
  static Future<String?> getValidProfileImagePath() async {
    if (_cachedProfileImagePath != null && _cachedProfileImagePath!.isNotEmpty) {
      final file = File(_cachedProfileImagePath!);
      if (await file.exists()) {
        return _cachedProfileImagePath;
      } else {
        // File was deleted, clear the cache
        await clearProfileImage();
        return null;
      }
    }
    return null;
  }

  // Save profile image path (with file validation)
  static Future<void> setProfileImagePath(String path) async {
    // Validate that file exists before saving
    final file = File(path);
    final fileExists = await file.exists();
    
    if (!fileExists) {
      throw Exception('File does not exist at path: $path');
    }
    
    _cachedProfileImagePath = path;
    // Notify all listeners of the change
    profileImageNotifier.value = path;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImagePath, path);
  }

  // Initialize cache from SharedPreferences (call on app startup)
  // This validates that the stored path still points to an existing file
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize profile image
    final storedPath = prefs.getString(_keyProfileImagePath);
    
    if (storedPath != null && storedPath.isNotEmpty) {
      final file = File(storedPath);
      final fileExists = await file.exists();
      
      if (fileExists) {
        _cachedProfileImagePath = storedPath;
        profileImageNotifier.value = storedPath;
      } else {
        // Stored path is invalid, clear it
        await prefs.remove(_keyProfileImagePath);
        _cachedProfileImagePath = null;
        profileImageNotifier.value = null;
      }
    } else {
      profileImageNotifier.value = null;
    }
    
    // Initialize username
    final storedUsername = prefs.getString(_keyUsername) ?? 'MSL Learner';
    _cachedUsername = storedUsername;
    usernameNotifier.value = storedUsername;
    
    // Initialize total points
    final storedPoints = prefs.getInt(_keyTotalPoints) ?? 0;
    _cachedTotalPoints = storedPoints;
    totalPointsNotifier.value = storedPoints;
    
    print('✓ [ProfileService] Profile initialized - Username: $_cachedUsername, Points: $_cachedTotalPoints');
  }

  // Mark a quiz as completed (triggers refresh in listening pages)
  // Call this after ANY quiz score is saved, regardless of points awarded
  static void markQuizCompleted(int quizId) {
    quizCompletionNotifier.value++;
  }

  // Clear profile image (async version)
  static Future<void> clearProfileImage() async {
    _cachedProfileImagePath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileImagePath);
  }

  // Clear profile image (sync version for use in getters)
  static void clearProfileImageSync() {
    _cachedProfileImagePath = null;
  }

  // Refresh cache from SharedPreferences (call when returning to home screen)
  static Future<void> refreshProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPath = prefs.getString(_keyProfileImagePath);
    
    if (storedPath != null && storedPath.isNotEmpty) {
      final file = File(storedPath);
      final fileExists = await file.exists();
   
      if (fileExists) {
        _cachedProfileImagePath = storedPath;
        // Notify all listeners of the refresh
        profileImageNotifier.value = storedPath;
      } else {
        await prefs.remove(_keyProfileImagePath);
        _cachedProfileImagePath = null;
        profileImageNotifier.value = null;
      }
    } else {
      _cachedProfileImagePath = null;
      profileImageNotifier.value = null;
    }
  }

  // USER PROFILE METHODS //

  /// Set username and save to SharedPreferences
  static Future<void> setUsername(String username) async {
    _cachedUsername = username;
    usernameNotifier.value = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    print('✓ [ProfileService] Username saved: $username');
  }

  /// Get username from cache
  static String getUsername() => _cachedUsername;

  /// Add points to total and save to SharedPreferences
  static Future<void> addPoints(int points) async {
    _cachedTotalPoints += points;
    totalPointsNotifier.value = _cachedTotalPoints;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalPoints, _cachedTotalPoints);
    print('✓ [ProfileService] Added $points points. Total: $_cachedTotalPoints');
  }

  /// Get total points from cache
  static int getTotalPoints() => _cachedTotalPoints;

  /// Reset progress-related profile data only.
  /// Keeps identity data such as username and profile image untouched.
  static Future<void> resetProgressOnly() async {
    _cachedTotalPoints = 0;
    totalPointsNotifier.value = _cachedTotalPoints;
    quizCompletionNotifier.value = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalPoints);
    print('✓ [ProfileService] Progress-only profile data reset');
  }

  /// Claim quiz points (100 points if score is 100%)
  /// Returns true if points were claimed, false if already claimed
  static Future<bool> claimQuizPoints(int quizId, int bestScore) async {
    if (bestScore == 100) {
      print('🎯 [ProfileService] Attempting to claim 100 points for quiz $quizId');
      await addPoints(100);
      return true;
    }
    print('⚠️ [ProfileService] Quiz $quizId score is $bestScore%, need 100% to claim points');
    return false;
  }

  /// Claim lesson points (50 points when lesson is 100% complete)
  /// Returns true if points were claimed, false if not eligible
  static Future<bool> claimLessonPoints(int lessonId) async {
    print('🎓 [ProfileService] Attempting to claim 50 points for lesson $lessonId');
    await addPoints(50);
    return true;
  }

  /// Reset profile for testing
  static Future<void> resetProfile() async {
    _cachedUsername = 'MSL Learner';
    _cachedTotalPoints = 0;
    usernameNotifier.value = _cachedUsername;
    totalPointsNotifier.value = _cachedTotalPoints;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyTotalPoints);
    print('✓ [ProfileService] Profile reset');
  }   

  // Delete the actual image file and clear cache
  static Future<void> deleteProfileImage() async {
    if (_cachedProfileImagePath != null && _cachedProfileImagePath!.isNotEmpty) {
      try {
        final file = File(_cachedProfileImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting profile image file: $e');
      }
    }
    await clearProfileImage();
  }
}
