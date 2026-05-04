// Tests for ProfileService - auto-generated via Copilot

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';

void main() {
  group('ProfileService', () {
    final tempDirs = <Directory>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProfileService.resetProfile();
      await ProfileService.clearProfileImage();
      await ProfileService.initialize();
    });

    tearDown(() async {
      for (final dir in tempDirs) {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
      tempDirs.clear();
      await ProfileService.resetProfile();
      await ProfileService.clearProfileImage();
    });

    test('setProfileImagePath() persists path via SharedPreferences', () async {
      // Arrange
      final dir = await Directory.systemTemp.createTemp('profile_service_test_');
      tempDirs.add(dir);
      final imageFile = File('${dir.path}${Platform.pathSeparator}avatar.png');
      await imageFile.writeAsString('fake-image-bytes');

      // Act
      await ProfileService.setProfileImagePath(imageFile.path);
      final prefs = await SharedPreferences.getInstance();

      // Assert
      expect(prefs.getString('profileImagePath'), imageFile.path);
      expect(ProfileService.cachedProfileImagePath, imageFile.path);
    });

    test('getValidProfileImagePath() returns null when no path is set', () async {
      // Arrange
      await ProfileService.clearProfileImage();

      // Act
      final result = await ProfileService.getValidProfileImagePath();

      // Assert
      expect(result, isNull);
    });

    test('getValidProfileImagePath() returns null when file does not exist on disk',
        () async {
      // Arrange
      final missingPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}missing_profile_${DateTime.now().microsecondsSinceEpoch}.png';
      SharedPreferences.setMockInitialValues({'profileImagePath': missingPath});
      await ProfileService.initialize();

      // Act
      final result = await ProfileService.getValidProfileImagePath();
      final prefs = await SharedPreferences.getInstance();

      // Assert
      expect(result, isNull);
      expect(ProfileService.cachedProfileImagePath, isNull);
      expect(prefs.getString('profileImagePath'), isNull);
    });

    test('getValidProfileImagePath() returns path when file exists', () async {
      // Arrange
      final dir = await Directory.systemTemp.createTemp('profile_service_test_');
      tempDirs.add(dir);
      final imageFile = File('${dir.path}${Platform.pathSeparator}avatar_exists.png');
      await imageFile.writeAsString('fake-image-bytes');
      await ProfileService.setProfileImagePath(imageFile.path);

      // Act
      final result = await ProfileService.getValidProfileImagePath();

      // Assert
      expect(result, imageFile.path);
    });

    test('Username is saved and retrieved correctly', () async {
      // Arrange
      const username = 'Test Learner';

      // Act
      await ProfileService.setUsername(username);
      final prefs = await SharedPreferences.getInstance();

      // Assert
      expect(ProfileService.getUsername(), username);
      expect(prefs.getString('username'), username);
    });

    test('Points are updated and retrieved correctly', () async {
      // Arrange
      const firstAdd = 120;
      const secondAdd = 30;

      // Act
      await ProfileService.addPoints(firstAdd);
      await ProfileService.addPoints(secondAdd);
      final prefs = await SharedPreferences.getInstance();

      // Assert
      expect(ProfileService.getTotalPoints(), firstAdd + secondAdd);
      expect(prefs.getInt('totalPoints'), firstAdd + secondAdd);
    });
  });
}