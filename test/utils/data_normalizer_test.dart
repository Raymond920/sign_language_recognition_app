// Tests for data_normalizer - auto-generated via Copilot

import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/utils/data_normalizer.dart';

void main() {
  group('Data Normalizer', () {
    test('normalizeLandmarkCoordinate() returns midpoint as 0.5', () {
      // Arrange
      const value = 540.0;
      const screenDimension = 1080.0;

      // Act
      final result = normalizeLandmarkCoordinate(value, screenDimension);

      // Assert
      expect(result, 0.5);
    });

    test('normalizeLandmarkCoordinate() clamps values to valid range', () {
      // Arrange
      const overValue = 1500.0;
      const negativeValue = -100.0;
      const screenDimension = 1080.0;

      // Act
      final overResult = normalizeLandmarkCoordinate(overValue, screenDimension);
      final negativeResult = normalizeLandmarkCoordinate(negativeValue, screenDimension);

      // Assert
      expect(overResult, 1.0);
      expect(negativeResult, 0.0);
    });

    test('normalizeLandmarkCoordinate() throws for invalid screen dimension', () {
      // Arrange
      const value = 200.0;

      // Act & Assert
      expect(
        () => normalizeLandmarkCoordinate(value, 0),
        throwsArgumentError,
      );
    });

    test('flattenLandmarks() returns 63 values for 21 landmarks', () {
      // Arrange
      final landmarks = List.generate(
        21,
        (index) => LandmarkPoint(
          x: index * 0.1,
          y: index * 0.2,
          z: index * 0.3,
        ),
      );

      // Act
      final flat = flattenLandmarks(landmarks);

      // Assert
      expect(flat.length, 63);
    });

    test('flattenLandmarks() preserves x y z ordering', () {
      // Arrange
      final landmarks = List.generate(
        21,
        (index) => LandmarkPoint(
          x: index.toDouble(),
          y: index.toDouble() + 0.1,
          z: index.toDouble() + 0.2,
        ),
      );

      // Act
      final flat = flattenLandmarks(landmarks);

      // Assert
      expect(flat[0], 0.0);
      expect(flat[1], 0.1);
      expect(flat[2], 0.2);
      expect(flat[3], 1.0);
      expect(flat[4], 1.1);
      expect(flat[5], 1.2);
    });

    test('flattenLandmarks() throws when landmark count is invalid', () {
      // Arrange
      final invalidLandmarks = List.generate(
        20,
        (index) => LandmarkPoint(x: index.toDouble(), y: index.toDouble(), z: 0),
      );

      // Act & Assert
      expect(
        () => flattenLandmarks(invalidLandmarks),
        throwsArgumentError,
      );
    });

    test('batchFlattenLandmarks() flattens multiple hand landmark sets', () {
      // Arrange
      final firstHand = List.generate(
        21,
        (index) => LandmarkPoint(x: index.toDouble(), y: index.toDouble() + 1, z: index.toDouble() + 2),
      );
      final secondHand = List.generate(
        21,
        (index) => LandmarkPoint(x: index.toDouble() + 10, y: index.toDouble() + 20, z: index.toDouble() + 30),
      );

      // Act
      final result = batchFlattenLandmarks([firstHand, secondHand]);

      // Assert
      expect(result.length, 2);
      expect(result.first.length, 63);
      expect(result.last.length, 63);
      expect(result.first[0], 0.0);
      expect(result.last[0], 10.0);
    });
  });
}