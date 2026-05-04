# Practical Unit Testing Guide - MSL Recognition App

## Overview

This guide provides unit tests for **functions and classes actually used in your Flutter application**, avoiding mocks and testing real implementations.

---

## Part 1: Model Classes (Currently Not Tested)

### 1.1 Sign Model Testing

**File**: `lib/models/sign_model.dart`

**Create**: `test/models/sign_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';

void main() {
  group('Sign Model Tests', () {
    group('Constructor and Properties', () {
      test('should create Sign with all properties', () {
        // Arrange
        const int id = 1;
        const String name = 'Hello';
        const String targetLabel = 'HELLO';
        const String imagePath = 'assets/signs/hello.png';
        const String tutorialText = 'Step 1: Open palm|Step 2: Wave hand';
        const String category = 'Greeting';
        const String videoId = 'vid_123';

        // Act
        final sign = Sign(
          id: id,
          name: name,
          targetLabel: targetLabel,
          imagePath: imagePath,
          tutorialText: tutorialText,
          category: category,
          videoId: videoId,
        );

        // Assert
        expect(sign.id, equals(id));
        expect(sign.name, equals(name));
        expect(sign.targetLabel, equals(targetLabel));
        expect(sign.imagePath, equals(imagePath));
        expect(sign.tutorialText, equals(tutorialText));
        expect(sign.category, equals(category));
        expect(sign.videoId, equals(videoId));
        expect(sign.isCompleted, isFalse); // Default is false
      });

      test('should parse instructions from tutorial text', () {
        // Arrange
        const String tutorialText = 'Open hand|Raise to shoulder|Wave fingers';
        final sign = Sign(
          id: 1,
          name: 'Test',
          targetLabel: 'TEST',
          imagePath: 'path.png',
          tutorialText: tutorialText,
          category: 'Test',
          videoId: 'vid',
        );

        // Act
        final instructions = sign.instructions;

        // Assert
        expect(instructions.length, equals(3));
        expect(instructions[0], equals('Open hand'));
        expect(instructions[1], equals('Raise to shoulder'));
        expect(instructions[2], equals('Wave fingers'));
      });

      test('should handle single instruction', () {
        // Arrange
        const String tutorialText = 'Point finger';
        final sign = Sign(
          id: 1,
          name: 'Point',
          targetLabel: 'POINT',
          imagePath: 'path.png',
          tutorialText: tutorialText,
          category: 'Action',
          videoId: 'vid',
        );

        // Act
        final instructions = sign.instructions;

        // Assert
        expect(instructions.length, equals(1));
        expect(instructions[0], equals('Point finger'));
      });

      test('should handle empty instructions gracefully', () {
        // Arrange
        const String tutorialText = '';
        final sign = Sign(
          id: 1,
          name: 'Empty',
          targetLabel: 'EMPTY',
          imagePath: 'path.png',
          tutorialText: tutorialText,
          category: 'Test',
          videoId: 'vid',
        );

        // Act
        final instructions = sign.instructions;

        // Assert
        expect(instructions.length, equals(1));
        expect(instructions[0], isEmpty);
      });
    });

    group('Factory Constructor - fromMap', () {
      test('should create Sign from map with completed status true', () {
        // Arrange
        final map = {
          'sign_id': 5,
          'sign_name': 'Thank You',
          'target_label': 'THANKYOU',
          'image_path': 'assets/signs/thankyou.png',
          'tutorial_text': 'Hand over heart|Bow slightly',
          'category': 'Polite',
          'video_id': 'vid_thankyou',
        };

        // Act
        final sign = Sign.fromMap(map, true);

        // Assert
        expect(sign.id, equals(5));
        expect(sign.name, equals('Thank You'));
        expect(sign.targetLabel, equals('THANKYOU'));
        expect(sign.isCompleted, isTrue);
      });

      test('should create Sign from map with completed status false', () {
        // Arrange
        final map = {
          'sign_id': 10,
          'sign_name': 'Sorry',
          'target_label': 'SORRY',
          'image_path': 'assets/signs/sorry.png',
          'tutorial_text': 'Hand on chest|Gentle circular motion',
          'category': 'Apology',
          'video_id': 'vid_sorry',
        };

        // Act
        final sign = Sign.fromMap(map, false);

        // Assert
        expect(sign.id, equals(10));
        expect(sign.isCompleted, isFalse);
      });

      test('should handle various map structures', () {
        // Arrange
        final map = {
          'sign_id': 1,
          'sign_name': 'A',
          'target_label': 'A',
          'image_path': 'a.png',
          'tutorial_text': 'Make letter A shape',
          'category': 'Letter',
          'video_id': 'vid_a',
        };

        // Act
        final sign = Sign.fromMap(map, false);

        // Assert - should handle all keys correctly
        expect(sign.id, equals(1));
        expect(sign.name, equals('A'));
      });
    });

    group('copyWith', () {
      test('should copy with isCompleted changed to true', () {
        // Arrange
        final sign = Sign(
          id: 1,
          name: 'Test',
          targetLabel: 'TEST',
          imagePath: 'path.png',
          tutorialText: 'Step',
          category: 'Test',
          videoId: 'vid',
          isCompleted: false,
        );

        // Act
        final copied = sign.copyWith(isCompleted: true);

        // Assert
        expect(copied.isCompleted, isTrue);
        expect(copied.id, equals(sign.id)); // Other properties unchanged
        expect(copied.name, equals(sign.name));
        expect(copied.targetLabel, equals(sign.targetLabel));
      });

      test('should preserve original when copyWith not provided', () {
        // Arrange
        final sign = Sign(
          id: 2,
          name: 'Original',
          targetLabel: 'ORIGINAL',
          imagePath: 'path.png',
          tutorialText: 'Step',
          category: 'Test',
          videoId: 'vid',
          isCompleted: true,
        );

        // Act
        final copied = sign.copyWith();

        // Assert
        expect(copied.isCompleted, isTrue);
        expect(copied.name, equals('Original'));
      });

      test('should create independent copy', () {
        // Arrange
        final original = Sign(
          id: 3,
          name: 'Original',
          targetLabel: 'ORIG',
          imagePath: 'path.png',
          tutorialText: 'Step',
          category: 'Test',
          videoId: 'vid',
          isCompleted: false,
        );

        // Act
        final copy1 = original.copyWith(isCompleted: true);
        final copy2 = original.copyWith(isCompleted: false);

        // Assert
        expect(copy1.isCompleted, isTrue);
        expect(copy2.isCompleted, isFalse);
        expect(original.isCompleted, isFalse); // Original unchanged
      });
    });
  });
}
```

---

## Part 2: Settings Service (Already Used in App)

**File**: `lib/services/settings_service.dart`

**Create**: `test/services/settings_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

void main() {
  group('SettingsService Tests', () {
    setUp(() {
      // Set up shared preferences with in-memory storage
      SharedPreferences.setMockInitialValues({});
    });

    group('TTS Settings', () {
      test('should set and retrieve TTS enabled status', () async {
        // Act
        await SettingsService.setTts(true);

        // Assert
        expect(SettingsService.cachedTtsEnabled, isTrue);
      });

      test('should default TTS to false', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isTtsEnabled'], isFalse);
      });

      test('should toggle TTS multiple times', () async {
        // Act & Assert
        await SettingsService.setTts(true);
        expect(SettingsService.cachedTtsEnabled, isTrue);

        await SettingsService.setTts(false);
        expect(SettingsService.cachedTtsEnabled, isFalse);

        await SettingsService.setTts(true);
        expect(SettingsService.cachedTtsEnabled, isTrue);
      });
    });

    group('Voice Settings', () {
      test('should set and retrieve voice', () async {
        // Act
        await SettingsService.setVoice('Male Voice');

        // Assert
        expect(SettingsService.cachedVoice, equals('Male Voice'));
      });

      test('should default voice to Female Voice', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['selectedVoice'], equals('Female Voice'));
      });

      test('should handle voice changes', () async {
        // Act & Assert
        await SettingsService.setVoice('Voice 1');
        expect(SettingsService.cachedVoice, equals('Voice 1'));

        await SettingsService.setVoice('Voice 2');
        expect(SettingsService.cachedVoice, equals('Voice 2'));
      });
    });

    group('Speed Settings', () {
      test('should set and retrieve speech speed', () async {
        // Act
        await SettingsService.setSpeed(0.75);

        // Assert
        expect(SettingsService.cachedSpeed, closeTo(0.75, 0.001));
      });

      test('should default speed to 0.4', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['speechSpeed'], closeTo(0.4, 0.001));
      });

      test('should handle speed range 0.0 to 1.0', () async {
        // Act & Assert
        await SettingsService.setSpeed(0.0);
        expect(SettingsService.cachedSpeed, closeTo(0.0, 0.001));

        await SettingsService.setSpeed(1.0);
        expect(SettingsService.cachedSpeed, closeTo(1.0, 0.001));

        await SettingsService.setSpeed(0.5);
        expect(SettingsService.cachedSpeed, closeTo(0.5, 0.001));
      });
    });

    group('Dark Mode Settings', () {
      test('should set and retrieve dark mode', () async {
        // Act
        await SettingsService.setDarkMode(true);

        // Assert
        expect(SettingsService.cachedDarkMode, isTrue);
      });

      test('should default dark mode to false', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isDarkMode'], isFalse);
      });

      test('should notify value notifier on dark mode change', () async {
        // Arrange
        bool notified = false;
        SettingsService.darkModeNotifier.addListener(() {
          notified = true;
        });

        // Act
        await SettingsService.setDarkMode(true);

        // Assert
        expect(notified, isTrue);
        expect(SettingsService.darkModeNotifier.value, isTrue);
      });
    });

    group('Landmarks Display Settings', () {
      test('should set and retrieve show landmarks', () async {
        // Act
        await SettingsService.setShowLandmarks(false);

        // Assert
        expect(SettingsService.cachedShowLandmarks, isFalse);
      });

      test('should default show landmarks to true', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isShowLandmarks'], isTrue);
      });
    });

    group('Haptic Settings', () {
      test('should set and retrieve haptic feedback', () async {
        // Act
        await SettingsService.setHaptic(false);

        // Assert
        expect(SettingsService.cachedHaptic, isFalse);
      });

      test('should default haptic to true', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isHaptic'], isTrue);
      });
    });

    group('Autoplay Settings', () {
      test('should set and retrieve autoplay', () async {
        // Act
        await SettingsService.setAutoplay(false);

        // Assert
        expect(SettingsService.cachedAutoplay, isFalse);
      });

      test('should default autoplay to true', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isAutoplay'], isTrue);
      });
    });

    group('getAllSettings Integration', () {
      test('should retrieve all settings at once', () async {
        // Arrange
        await SettingsService.setTts(true);
        await SettingsService.setVoice('Male Voice');
        await SettingsService.setSpeed(0.6);
        await SettingsService.setDarkMode(true);
        await SettingsService.setShowLandmarks(false);
        await SettingsService.setHaptic(false);
        await SettingsService.setAutoplay(false);

        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings['isTtsEnabled'], isTrue);
        expect(settings['selectedVoice'], equals('Male Voice'));
        expect(settings['speechSpeed'], closeTo(0.6, 0.001));
        expect(settings['isDarkMode'], isTrue);
        expect(settings['isShowLandmarks'], isFalse);
        expect(settings['isHaptic'], isFalse);
        expect(settings['isAutoplay'], isFalse);
      });

      test('should load all default settings', () async {
        // Act
        final settings = await SettingsService.getAllSettings();

        // Assert
        expect(settings.keys.length, equals(7));
        expect(settings.containsKey('isTtsEnabled'), isTrue);
        expect(settings.containsKey('selectedVoice'), isTrue);
        expect(settings.containsKey('speechSpeed'), isTrue);
        expect(settings.containsKey('isDarkMode'), isTrue);
        expect(settings.containsKey('isShowLandmarks'), isTrue);
        expect(settings.containsKey('isHaptic'), isTrue);
        expect(settings.containsKey('isAutoplay'), isTrue);
      });
    });
  });
}
```

---

## Part 3: Spelling Manager (Should Be Used in App)

**File**: `lib/utils/spelling_manager.dart`

**Create**: `test/utils/spelling_manager_test.dart` (Update existing tests)

These tests are VALID and should be kept because `SpellingManager` is designed to be used (even if current app uses `TextEditingController` directly).

---

## Part 4: PredictionResult Model

**File**: `lib/models/prediction_result.dart`

**Create**: `test/models/prediction_result_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/models/prediction_result.dart';

void main() {
  group('PredictionResult Model Tests', () {
    test('should create PredictionResult with all properties', () {
      // Arrange
      final prediction = ['A', '0.95'];
      final landmarks = <Hand>[]; // Empty for test
      const bool isStable = true;
      const String stabilityStatus = 'Hand stable';
      const double fps = 30.0;

      // Act
      final result = PredictionResult(
        prediction: prediction,
        landmarks: landmarks,
        isStable: isStable,
        stabilityStatus: stabilityStatus,
        fps: fps,
      );

      // Assert
      expect(result.prediction, equals(prediction));
      expect(result.landmarks, equals(landmarks));
      expect(result.isStable, isTrue);
      expect(result.stabilityStatus, equals(stabilityStatus));
      expect(result.fps, closeTo(30.0, 0.1));
    });

    test('should handle empty prediction list', () {
      // Arrange
      final result = PredictionResult(
        prediction: [],
        landmarks: [],
        isStable: false,
        stabilityStatus: 'No hand detected',
        fps: 0.0,
      );

      // Assert
      expect(result.prediction, isEmpty);
      expect(result.isStable, isFalse);
    });

    test('should handle multiple predictions', () {
      // Arrange
      final prediction = ['A', '0.92', 'B', '0.05'];
      final result = PredictionResult(
        prediction: prediction,
        landmarks: [],
        isStable: true,
        stabilityStatus: 'Stable',
        fps: 28.5,
      );

      // Assert
      expect(result.prediction.length, equals(4));
      expect(result.prediction[0], equals('A'));
      expect(result.prediction[1], equals('0.92'));
    });

    test('should update FPS tracking', () {
      // Arrange & Act
      final results = [
        PredictionResult(prediction: [], landmarks: [], isStable: true, stabilityStatus: 'Stable', fps: 25.0),
        PredictionResult(prediction: [], landmarks: [], isStable: true, stabilityStatus: 'Stable', fps: 30.0),
        PredictionResult(prediction: [], landmarks: [], isStable: true, stabilityStatus: 'Stable', fps: 28.5),
      ];

      // Assert
      expect(results[0].fps, closeTo(25.0, 0.1));
      expect(results[1].fps, closeTo(30.0, 0.1));
      expect(results[2].fps, closeTo(28.5, 0.1));
    });
  });
}
```

---

## Part 5: Confidence Checking (Utility - Not Currently Used)

**File**: `lib/utils/confidence_checker.dart`

**Keep existing 47 tests** but note they're for optional utility functions. Update status to document this.

---

## Test Execution Guide

### 1. Run All Tests
```bash
flutter test
```

### 2. Run Specific Test File
```bash
flutter test test/models/sign_model_test.dart
flutter test test/services/settings_service_test.dart
```

### 3. Run with Coverage
```bash
flutter test --coverage
```

### 4. Generate Coverage Report
```bash
# Windows
genhtml coverage\lcov.info -o coverage\html
start coverage\html\index.html
```

---

## Recommended Test Priority

### ✅ HIGH PRIORITY (Functions Actually Used)
1. **SettingsService** - Used throughout the app for preferences
2. **Sign Model** - Core data model for lesson content
3. **PredictionResult** - Used in recognition stream
4. **LandmarkPainter** - UI rendering logic

### ⚠️ MEDIUM PRIORITY (Should Be Used)
1. **SpellingManager** - Designed for spelling mode (currently unused but valuable)

### 🟡 LOW PRIORITY (Optional Utilities)
1. **Confidence Checker** - Functions for prediction validation (currently not used, but useful)
2. **Data Normalizer** - Functions for data preprocessing (currently not used, logic inlined)

---

## Summary

| Module | Tests | Status | Recommendation |
|--------|-------|--------|-----------------|
| Sign Model | NEW | ✅ Create | High Priority |
| Settings Service | NEW | ✅ Create | High Priority |
| PredictionResult | NEW | ✅ Create | High Priority |
| Spelling Manager | 44 | ⚠️ Keep | Refactor app to use |
| Confidence Checker | 47 | 🟡 Keep | Optional utility |
| Data Normalizer | 26 | 🟡 Keep | Optional utility |
| **TOTAL** | **137+** | | |

---

## Next Steps

1. **Create** the new test files for models and services
2. **Run** `flutter test` to verify all tests pass
3. **Consider** integrating `SpellingManager` into the app for better code reuse
4. **Document** which tests are for production vs. optional utilities
