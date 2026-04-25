/// Unit tests for Confidence Checker utility functions
/// Tests confidence threshold validation and prediction filtering

import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_recognition_app/utils/confidence_checker.dart';

void main() {
  group('Confidence Checker Tests', () {
    group('isConfidenceValid', () {
      test('should return true when confidence equals threshold', () {
        // Arrange
        const double confidence = 0.70;
        const double threshold = 0.70;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isTrue);
      });

      test('should return true when confidence exceeds threshold', () {
        // Arrange
        const double confidence = 0.85;
        const double threshold = 0.70;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when confidence below threshold', () {
        // Arrange
        const double confidence = 0.40;
        const double threshold = 0.70;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isFalse);
      });

      test('should use default threshold of 0.70 when not specified', () {
        // Arrange
        const double confidenceValid = 0.75;
        const double confidenceInvalid = 0.65;

        // Act
        final resultValid = isConfidenceValid(confidenceValid);
        final resultInvalid = isConfidenceValid(confidenceInvalid);

        // Assert
        expect(resultValid, isTrue);
        expect(resultInvalid, isFalse);
      });

      test('should handle perfect confidence of 1.0', () {
        // Arrange
        const double confidence = 1.0;
        const double threshold = 0.70;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isTrue);
      });

      test('should handle zero confidence', () {
        // Arrange
        const double confidence = 0.0;
        const double threshold = 0.70;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isFalse);
      });

      test('should handle confidence very close to threshold', () {
        // Arrange
        const double threshold = 0.70;
        const double justAbove = 0.70001;
        const double justBelow = 0.69999;

        // Act
        final resultAbove = isConfidenceValid(justAbove, threshold: threshold);
        final resultBelow = isConfidenceValid(justBelow, threshold: threshold);

        // Assert
        expect(resultAbove, isTrue);
        expect(resultBelow, isFalse);
      });

      test('should handle custom threshold of 0.50', () {
        // Arrange
        const double confidence1 = 0.51;
        const double confidence2 = 0.49;
        const double threshold = 0.50;

        // Act & Assert
        expect(isConfidenceValid(confidence1, threshold: threshold), isTrue);
        expect(isConfidenceValid(confidence2, threshold: threshold), isFalse);
      });

      test('should handle high threshold of 0.95', () {
        // Arrange
        const double confidence1 = 0.96;
        const double confidence2 = 0.94;
        const double threshold = 0.95;

        // Act & Assert
        expect(isConfidenceValid(confidence1, threshold: threshold), isTrue);
        expect(isConfidenceValid(confidence2, threshold: threshold), isFalse);
      });

      test('should handle low threshold of 0.10', () {
        // Arrange
        const double confidence = 0.15;
        const double threshold = 0.10;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert
        expect(result, isTrue);
      });

      test('should throw error for confidence > 1.0', () {
        // Arrange
        const double confidence = 1.5;
        const double threshold = 0.70;

        // Act & Assert
        expect(
          () => isConfidenceValid(confidence, threshold: threshold),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for confidence < 0.0', () {
        // Arrange
        const double confidence = -0.5;
        const double threshold = 0.70;

        // Act & Assert
        expect(
          () => isConfidenceValid(confidence, threshold: threshold),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for threshold > 1.0', () {
        // Arrange
        const double confidence = 0.85;
        const double threshold = 1.5;

        // Act & Assert
        expect(
          () => isConfidenceValid(confidence, threshold: threshold),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for threshold < 0.0', () {
        // Arrange
        const double confidence = 0.85;
        const double threshold = -0.1;

        // Act & Assert
        expect(
          () => isConfidenceValid(confidence, threshold: threshold),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle edge case: confidence 0.0, threshold 0.0', () {
        // Arrange
        const double confidence = 0.0;
        const double threshold = 0.0;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert: 0.0 >= 0.0 is true
        expect(result, isTrue);
      });

      test('should handle edge case: confidence 1.0, threshold 1.0', () {
        // Arrange
        const double confidence = 1.0;
        const double threshold = 1.0;

        // Act
        final result = isConfidenceValid(confidence, threshold: threshold);

        // Assert: 1.0 >= 1.0 is true
        expect(result, isTrue);
      });

      test('should validate typical TFLite model outputs', () {
        // Arrange: typical model confidence values
        final testCases = [
          (0.95, 0.70, true),   // Very confident prediction
          (0.78, 0.70, true),   // Comfortably above threshold
          (0.70, 0.70, true),   // Exactly at threshold
          (0.65, 0.70, false),  // Slightly below threshold
          (0.45, 0.70, false),  // Well below threshold
          (0.99, 0.90, true),   // High confidence, high threshold
        ];

        // Act & Assert
        for (final (confidence, threshold, expected) in testCases) {
          expect(
            isConfidenceValid(confidence, threshold: threshold),
            equals(expected),
            reason: 'Failed for confidence=$confidence, threshold=$threshold',
          );
        }
      });
    });

    group('PredictionConfidence', () {
      test('should create prediction with label and confidence', () {
        // Act
        final prediction = PredictionConfidence(
          label: 'A',
          confidence: 0.85,
        );

        // Assert
        expect(prediction.label, equals('A'));
        expect(prediction.confidence, equals(0.85));
      });

      test('should throw error for invalid confidence > 1.0', () {
        // Act & Assert
        expect(
          () => PredictionConfidence(label: 'A', confidence: 1.5),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for invalid confidence < 0.0', () {
        // Act & Assert
        expect(
          () => PredictionConfidence(label: 'A', confidence: -0.1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should allow confidence 0.0', () {
        // Act
        final prediction = PredictionConfidence(
          label: 'A',
          confidence: 0.0,
        );

        // Assert
        expect(prediction.confidence, equals(0.0));
      });

      test('should allow confidence 1.0', () {
        // Act
        final prediction = PredictionConfidence(
          label: 'A',
          confidence: 1.0,
        );

        // Assert
        expect(prediction.confidence, equals(1.0));
      });

      test('meetsThreshold should use default threshold', () {
        // Arrange
        final prediction1 = PredictionConfidence(label: 'A', confidence: 0.75);
        final prediction2 = PredictionConfidence(label: 'B', confidence: 0.65);

        // Assert
        expect(prediction1.meetsThreshold(), isTrue);
        expect(prediction2.meetsThreshold(), isFalse);
      });

      test('meetsThreshold should accept custom threshold', () {
        // Arrange
        final prediction = PredictionConfidence(label: 'A', confidence: 0.72);

        // Assert
        expect(prediction.meetsThreshold(threshold: 0.70), isTrue);
        expect(prediction.meetsThreshold(threshold: 0.75), isFalse);
      });

      test('should generate string representation', () {
        // Arrange
        final prediction = PredictionConfidence(label: 'A', confidence: 0.85);

        // Act
        final str = prediction.toString();

        // Assert
        expect(str, contains('A'));
        expect(str, contains('0.85'));
      });

      test('should work with all 26 letters', () {
        // Act & Assert
        for (int i = 0; i < 26; i++) {
          final letter = String.fromCharCode(65 + i); // A-Z
          final prediction = PredictionConfidence(
            label: letter,
            confidence: 0.85,
          );
          expect(prediction.label, equals(letter));
        }
      });
    });

    group('filterConfidentPredictions', () {
      test('should filter predictions above default threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.85),
          PredictionConfidence(label: 'B', confidence: 0.40),
          PredictionConfidence(label: 'C', confidence: 0.92),
          PredictionConfidence(label: 'D', confidence: 0.65),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions);

        // Assert
        expect(filtered.length, equals(2));
        expect(filtered[0].label, equals('A'));
        expect(filtered[1].label, equals('C'));
      });

      test('should filter predictions with custom threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.85),
          PredictionConfidence(label: 'B', confidence: 0.75),
          PredictionConfidence(label: 'C', confidence: 0.65),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions, threshold: 0.80);

        // Assert
        expect(filtered.length, equals(1));
        expect(filtered[0].label, equals('A'));
      });

      test('should return empty list if no predictions meet threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.50),
          PredictionConfidence(label: 'B', confidence: 0.45),
          PredictionConfidence(label: 'C', confidence: 0.40),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions, threshold: 0.70);

        // Assert
        expect(filtered, isEmpty);
      });

      test('should return all predictions if all meet threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.95),
          PredictionConfidence(label: 'B', confidence: 0.90),
          PredictionConfidence(label: 'C', confidence: 0.85),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions, threshold: 0.70);

        // Assert
        expect(filtered.length, equals(3));
      });

      test('should preserve order of predictions', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'Z', confidence: 0.85),
          PredictionConfidence(label: 'A', confidence: 0.75),
          PredictionConfidence(label: 'M', confidence: 0.80),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions);

        // Assert
        expect(filtered[0].label, equals('Z'));
        expect(filtered[1].label, equals('A'));
        expect(filtered[2].label, equals('M'));
      });

      test('should handle empty predictions list', () {
        // Act
        final filtered = filterConfidentPredictions([]);

        // Assert
        expect(filtered, isEmpty);
      });

      test('should work with 0.0 threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.01),
          PredictionConfidence(label: 'B', confidence: 0.0),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions, threshold: 0.0);

        // Assert
        expect(filtered.length, equals(2));
      });

      test('should work with 1.0 threshold', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 1.0),
          PredictionConfidence(label: 'B', confidence: 0.99),
        ];

        // Act
        final filtered = filterConfidentPredictions(predictions, threshold: 1.0);

        // Assert
        expect(filtered.length, equals(1));
        expect(filtered[0].label, equals('A'));
      });
    });

    group('getHighestConfidencePrediction', () {
      test('should return prediction with highest confidence', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.75),
          PredictionConfidence(label: 'B', confidence: 0.92),
          PredictionConfidence(label: 'C', confidence: 0.80),
        ];

        // Act
        final highest = getHighestConfidencePrediction(predictions);

        // Assert
        expect(highest?.label, equals('B'));
        expect(highest?.confidence, equals(0.92));
      });

      test('should return null for empty list', () {
        // Act
        final highest = getHighestConfidencePrediction([]);

        // Assert
        expect(highest, isNull);
      });

      test('should return single prediction if only one exists', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.85),
        ];

        // Act
        final highest = getHighestConfidencePrediction(predictions);

        // Assert
        expect(highest?.label, equals('A'));
        expect(highest?.confidence, equals(0.85));
      });

      test('should handle tied confidences (returns first found)', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.85),
          PredictionConfidence(label: 'B', confidence: 0.85),
        ];

        // Act
        final highest = getHighestConfidencePrediction(predictions);

        // Assert: should return first one found with max confidence
        expect(highest?.confidence, equals(0.85));
      });

      test('should work with very close confidence values', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.850000),
          PredictionConfidence(label: 'B', confidence: 0.850001),
          PredictionConfidence(label: 'C', confidence: 0.849999),
        ];

        // Act
        final highest = getHighestConfidencePrediction(predictions);

        // Assert: should find B with 0.850001
        expect(highest?.label, equals('B'));
      });
    });

    group('calculateAverageConfidence', () {
      test('should calculate average confidence correctly', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.80),
          PredictionConfidence(label: 'B', confidence: 0.90),
          PredictionConfidence(label: 'C', confidence: 1.00),
        ];

        // Act
        final average = calculateAverageConfidence(predictions);

        // Assert: (0.80 + 0.90 + 1.00) / 3 = 0.90
        expect(average, closeTo(0.90, 0.0001));
      });

      test('should return 0.0 for empty list', () {
        // Act
        final average = calculateAverageConfidence([]);

        // Assert
        expect(average, equals(0.0));
      });

      test('should work with single prediction', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.75),
        ];

        // Act
        final average = calculateAverageConfidence(predictions);

        // Assert
        expect(average, equals(0.75));
      });

      test('should work with all same confidences', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.70),
          PredictionConfidence(label: 'B', confidence: 0.70),
          PredictionConfidence(label: 'C', confidence: 0.70),
        ];

        // Act
        final average = calculateAverageConfidence(predictions);

        // Assert
        expect(average, closeTo(0.70, 0.0001));
      });

      test('should handle decimal precision', () {
        // Arrange
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.333333),
          PredictionConfidence(label: 'B', confidence: 0.333333),
          PredictionConfidence(label: 'C', confidence: 0.333334),
        ];

        // Act
        final average = calculateAverageConfidence(predictions);

        // Assert
        expect(average, closeTo(0.333333, 0.000001));
      });
    });

    group('getConfidenceLevel', () {
      test('should return low for confidence < 0.5', () {
        // Assert
        expect(getConfidenceLevel(0.0), equals(ConfidenceLevel.low));
        expect(getConfidenceLevel(0.25), equals(ConfidenceLevel.low));
        expect(getConfidenceLevel(0.49), equals(ConfidenceLevel.low));
      });

      test('should return medium for 0.5 <= confidence <= 0.8', () {
        // Assert
        expect(getConfidenceLevel(0.50), equals(ConfidenceLevel.medium));
        expect(getConfidenceLevel(0.65), equals(ConfidenceLevel.medium));
        expect(getConfidenceLevel(0.80), equals(ConfidenceLevel.medium));
      });

      test('should return high for confidence > 0.8', () {
        // Assert
        expect(getConfidenceLevel(0.81), equals(ConfidenceLevel.high));
        expect(getConfidenceLevel(0.90), equals(ConfidenceLevel.high));
        expect(getConfidenceLevel(1.0), equals(ConfidenceLevel.high));
      });

      test('should handle edge cases at boundaries', () {
        // Assert
        expect(getConfidenceLevel(0.5), equals(ConfidenceLevel.medium));
        expect(getConfidenceLevel(0.8), equals(ConfidenceLevel.medium));
        expect(getConfidenceLevel(0.800001), equals(ConfidenceLevel.high));
      });

      test('should categorize typical model outputs', () {
        // Arrange
        final testCases = [
          (0.2, ConfidenceLevel.low),    // Poor prediction
          (0.65, ConfidenceLevel.medium), // Moderate prediction
          (0.95, ConfidenceLevel.high),   // Strong prediction
        ];

        // Assert
        for (final (confidence, expectedLevel) in testCases) {
          expect(
            getConfidenceLevel(confidence),
            equals(expectedLevel),
            reason: 'Failed for confidence=$confidence',
          );
        }
      });
    });

    group('Integration tests', () {
      test('should validate complete prediction workflow', () {
        // Arrange: simulate model predictions from TFLite
        final rawPredictions = [
          PredictionConfidence(label: 'A', confidence: 0.92),
          PredictionConfidence(label: 'B', confidence: 0.05),
          PredictionConfidence(label: 'C', confidence: 0.02),
          PredictionConfidence(label: 'D', confidence: 0.01),
        ];

        // Act: filter confident predictions
        final filtered = filterConfidentPredictions(rawPredictions, threshold: 0.70);
        final best = getHighestConfidencePrediction(filtered);
        final avgConfidence = calculateAverageConfidence(filtered);

        // Assert
        expect(filtered.length, equals(1));
        expect(best?.label, equals('A'));
        expect(best?.confidence, equals(0.92));
        expect(avgConfidence, equals(0.92));
      });

      test('should handle multi-letter predictions', () {
        // Arrange: predictions for 26 letters with increasing confidence
        final allLetters = List.generate(
          26,
          (i) => PredictionConfidence(
            label: String.fromCharCode(65 + i),
            confidence: 0.5 + (i * 0.01), // 0.50 to 0.75
          ),
        );

        // Act: filter with lower threshold (0.70) so some pass
        final highConfidence = filterConfidentPredictions(allLetters, threshold: 0.70);
        final bestPrediction = getHighestConfidencePrediction(allLetters);

        // Assert
        expect(highConfidence.length, greaterThan(0));
        expect(bestPrediction?.label, equals('Z')); // Last letter (highest confidence: 0.75)
      });

      test('should validate custom thresholds for sign recognition', () {
        // Arrange: different confidence thresholds for different scenarios
        final predictions = [
          PredictionConfidence(label: 'A', confidence: 0.92),
          PredictionConfidence(label: 'B', confidence: 0.72),
          PredictionConfidence(label: 'C', confidence: 0.52),
        ];

        // Act: filter with different thresholds
        final strict = filterConfidentPredictions(predictions, threshold: 0.90);
        final moderate = filterConfidentPredictions(predictions, threshold: 0.70);
        final lenient = filterConfidentPredictions(predictions, threshold: 0.50);

        // Assert
        expect(strict.length, equals(1));  // Only 'A'
        expect(moderate.length, equals(2)); // 'A' and 'B'
        expect(lenient.length, equals(3));  // All three
      });
    });
  });
}
