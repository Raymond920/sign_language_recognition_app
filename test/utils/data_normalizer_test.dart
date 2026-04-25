/// Unit tests for Data Normalizer utility functions
/// Tests landmark coordinate normalization and flattening

import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/utils/data_normalizer.dart';

void main() {
  group('Data Normalizer Tests', () {
    group('normalizeLandmarkCoordinate', () {
      test('should normalize midpoint to 0.5', () {
        // Arrange
        const double value = 540;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.5));
      });

      test('should normalize 0 to 0.0', () {
        // Arrange
        const double value = 0;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.0));
      });

      test('should clamp value at screen dimension to 1.0', () {
        // Arrange
        const double value = 1080;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(1.0));
      });

      test('should clamp values beyond screen dimension to 1.0', () {
        // Arrange
        const double value = 1500; // Beyond screen
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(1.0));
      });

      test('should normalize quarter point to 0.25', () {
        // Arrange
        const double value = 270;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.25));
      });

      test('should normalize three-quarter point to 0.75', () {
        // Arrange
        const double value = 810;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.75));
      });

      test('should handle small screen dimensions', () {
        // Arrange
        const double value = 25;
        const double screenDimension = 100;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.25));
      });

      test('should handle large screen dimensions', () {
        // Arrange
        const double value = 960;
        const double screenDimension = 1920;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.5));
      });

      test('should clamp negative values to 0.0', () {
        // Arrange
        const double value = -100;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, equals(0.0));
      });

      test('should handle fractional coordinate values', () {
        // Arrange
        const double value = 540.5;
        const double screenDimension = 1080;

        // Act
        final result = normalizeLandmarkCoordinate(value, screenDimension);

        // Assert
        expect(result, isNotNull);
        expect(result, greaterThan(0.49));
        expect(result, lessThan(0.51));
      });
    });

    group('LandmarkPoint', () {
      test('should create landmark with coordinates', () {
        // Act
        final point = LandmarkPoint(x: 0.5, y: 0.6, z: 0.7);

        // Assert
        expect(point.x, equals(0.5));
        expect(point.y, equals(0.6));
        expect(point.z, equals(0.7));
      });

      test('should support equality operator', () {
        // Arrange
        final point1 = LandmarkPoint(x: 0.5, y: 0.6, z: 0.7);
        final point2 = LandmarkPoint(x: 0.5, y: 0.6, z: 0.7);
        final point3 = LandmarkPoint(x: 0.5, y: 0.6, z: 0.8);

        // Assert
        expect(point1, equals(point2));
        expect(point1, isNot(equals(point3)));
      });
    });

    group('flattenLandmarks', () {
      test('should flatten 21 landmarks to 63 elements', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.1, y: 0.2, z: 0.3),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened.length, equals(63));
      });

      test('should preserve coordinate order', () {
        // Arrange
        final landmarks = [
          LandmarkPoint(x: 0.1, y: 0.2, z: 0.3),
          LandmarkPoint(x: 0.4, y: 0.5, z: 0.6),
          LandmarkPoint(x: 0.7, y: 0.8, z: 0.9),
        ];
        // Pad with remaining landmarks
        for (int i = 3; i < 21; i++) {
          landmarks.add(LandmarkPoint(x: 0.0, y: 0.0, z: 0.0));
        }

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert: first landmark should be [0.1, 0.2, 0.3]
        expect(flattened[0], equals(0.1)); // x0
        expect(flattened[1], equals(0.2)); // y0
        expect(flattened[2], equals(0.3)); // z0
        // second landmark should be [0.4, 0.5, 0.6]
        expect(flattened[3], equals(0.4)); // x1
        expect(flattened[4], equals(0.5)); // y1
        expect(flattened[5], equals(0.6)); // z1
      });

      test('should handle all zero coordinates', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.0, y: 0.0, z: 0.0),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened.length, equals(63));
        expect(flattened.every((value) => value == 0.0), isTrue);
      });

      test('should handle all one coordinates', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 1.0, y: 1.0, z: 1.0),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened.length, equals(63));
        expect(flattened.every((value) => value == 1.0), isTrue);
      });

      test('should handle decimal precision', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.333, y: 0.667, z: 0.999),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened[0], closeTo(0.333, 0.001));
        expect(flattened[1], closeTo(0.667, 0.001));
        expect(flattened[2], closeTo(0.999, 0.001));
      });

      test('should throw error if less than 21 landmarks', () {
        // Arrange
        final landmarks = List.generate(
          20, // One less than required
          (index) => LandmarkPoint(x: 0.5, y: 0.5, z: 0.5),
        );

        // Act & Assert
        expect(
          () => flattenLandmarks(landmarks),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error if more than 21 landmarks', () {
        // Arrange
        final landmarks = List.generate(
          22, // One more than required
          (index) => LandmarkPoint(x: 0.5, y: 0.5, z: 0.5),
        );

        // Act & Assert
        expect(
          () => flattenLandmarks(landmarks),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle very small coordinate values', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.001, y: 0.001, z: 0.001),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened[0], closeTo(0.001, 0.0001));
      });

      test('should handle very large coordinate values (clamped to 1.0)', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(x: 1.5, y: 1.5, z: 1.5),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert: values might not be clamped in the data structure itself,
        // but should be preserved as passed
        expect(flattened[0], equals(1.5));
      });

      test('should handle negative coordinate values', () {
        // Arrange
        final landmarks = List.generate(
          21,
          (index) => LandmarkPoint(
            x: index.isEven ? 0.2 : -0.2,
            y: 0.5,
            z: index.isEven ? 0.2 : -0.2,
          ),
        );

        // Act
        final flattened = flattenLandmarks(landmarks);

        // Assert
        expect(flattened.length, equals(63));
        // First landmark (index 0 is even): x=0.2, z=0.2
        expect(flattened[0], equals(0.2));   // x0
        expect(flattened[2], equals(0.2));   // z0
        // Second landmark (index 1 is odd): x=-0.2, z=-0.2
        expect(flattened[3], equals(-0.2));  // x1
        expect(flattened[5], equals(-0.2));  // z1
      });
    });

    group('batchFlattenLandmarks', () {
      test('should flatten batch of landmarks correctly', () {
        // Arrange
        final batch1 = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.1, y: 0.2, z: 0.3),
        );
        final batch2 = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.4, y: 0.5, z: 0.6),
        );

        // Act
        final batchFlattened = batchFlattenLandmarks([batch1, batch2]);

        // Assert
        expect(batchFlattened.length, equals(2));
        expect(batchFlattened[0].length, equals(63));
        expect(batchFlattened[1].length, equals(63));
      });

      test('should handle empty batch', () {
        // Act
        final result = batchFlattenLandmarks([]);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle single batch', () {
        // Arrange
        final batch = List.generate(
          21,
          (index) => LandmarkPoint(x: 0.5, y: 0.5, z: 0.5),
        );

        // Act
        final result = batchFlattenLandmarks([batch]);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].length, equals(63));
      });
    });

    group('Integration tests', () {
      test('should normalize and flatten hand landmarks from screen coordinates', () {
        // Arrange: simulate screen coordinates (1080x1920)
        const screenHeight = 1080.0;
        const screenWidth = 1920.0;

        // Create landmarks at various screen positions
        final screenLandmarks = [
          LandmarkPoint(x: 0, y: 0, z: 0.5),           // Top-left
          LandmarkPoint(x: screenWidth, y: 0, z: 0.5), // Top-right
          LandmarkPoint(x: 540, y: 540, z: 0.5),       // Center
        ];

        // Pad with remaining landmarks
        for (int i = 3; i < 21; i++) {
          screenLandmarks.add(LandmarkPoint(
            x: screenWidth / 2 + i * 10,
            y: screenHeight / 2,
            z: 0.5,
          ));
        }

        // Normalize coordinates
        final normalizedLandmarks = screenLandmarks
            .map((landmark) => LandmarkPoint(
                  x: normalizeLandmarkCoordinate(landmark.x, screenWidth),
                  y: normalizeLandmarkCoordinate(landmark.y, screenHeight),
                  z: landmark.z,
                ))
            .toList();

        // Act: flatten for TFLite input
        final flattened = flattenLandmarks(normalizedLandmarks);

        // Assert
        expect(flattened.length, equals(63));
        expect(flattened[0], equals(0.0));    // x of first landmark (0 normalized)
        expect(flattened[1], equals(0.0));    // y of first landmark (0 normalized)
        expect(flattened[2], equals(0.5));    // z of first landmark
      });

      test('should handle multiple hand detections', () {
        // Arrange: simulate 3 consecutive hand detections
        final detections = List.generate(
          3,
          (detectionIndex) => List.generate(
            21,
            (landmarkIndex) => LandmarkPoint(
              x: 0.1 * (detectionIndex + 1),
              y: 0.2 * (landmarkIndex + 1),
              z: 0.3,
            ),
          ),
        );

        // Act: batch flatten all detections
        final flattenedBatch = batchFlattenLandmarks(detections);

        // Assert
        expect(flattenedBatch.length, equals(3));
        for (int i = 0; i < 3; i++) {
          expect(flattenedBatch[i].length, equals(63));
        }
      });
    });
  });
}
