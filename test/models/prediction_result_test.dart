// Tests for PredictionResult - auto-generated via Copilot

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:sign_language_recognition_app/models/prediction_result.dart';

void main() {
  group('PredictionResult', () {
    test('stores constructor values correctly', () {
      // Arrange
      const prediction = ['A', '98%'];
      const landmarks = <Hand>[];

      // Act
      final result = PredictionResult(
        prediction: prediction,
        landmarks: landmarks,
        isStable: true,
        stabilityStatus: 'Stable: 5/5',
        fps: 29.5,
        latencyMs: 0,
      );

      // Assert
      expect(result.prediction, prediction);
      expect(result.landmarks, landmarks);
      expect(result.isStable, isTrue);
      expect(result.stabilityStatus, 'Stable: 5/5');
      expect(result.fps, 29.5);
    });

    test('supports empty prediction and landmark payloads', () {
      // Arrange
      const prediction = <String>[];
      const landmarks = <Hand>[];

      // Act
      final result = PredictionResult(
        prediction: prediction,
        landmarks: landmarks,
        isStable: false,
        stabilityStatus: 'Collecting samples... 1/7',
        fps: 0.0,
        latencyMs: 0,
      );

      // Assert
      expect(result.prediction, isEmpty);
      expect(result.landmarks, isEmpty);
      expect(result.isStable, isFalse);
      expect(result.fps, 0.0);
    });
  });
}