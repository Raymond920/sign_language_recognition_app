/// Confidence Checker utility for validating model prediction confidence scores
/// Ensures predictions meet the required confidence threshold for reliable classification

/// Checks if a confidence score meets or exceeds the specified threshold
///
/// Parameters:
/// - [confidence]: The model's confidence score (typically 0.0 to 1.0)
/// - [threshold]: The minimum required confidence (default 0.70)
///
/// Returns: true if confidence >= threshold, false otherwise
///
/// Example:
/// ```
/// isConfidenceValid(0.85, 0.70);  // Returns true
/// isConfidenceValid(0.40, 0.70);  // Returns false
/// isConfidenceValid(0.70, 0.70);  // Returns true (exact match)
/// ```
bool isConfidenceValid(double confidence, {double threshold = 0.70}) {
  // Validate inputs
  if (confidence < 0.0 || confidence > 1.0) {
    throw ArgumentError(
      'Confidence must be between 0.0 and 1.0, got $confidence',
    );
  }

  if (threshold < 0.0 || threshold > 1.0) {
    throw ArgumentError(
      'Threshold must be between 0.0 and 1.0, got $threshold',
    );
  }

  return confidence >= threshold;
}

/// Represents a prediction result with its confidence score
class PredictionConfidence {
  final String label;
  final double confidence;

  PredictionConfidence({
    required this.label,
    required this.confidence,
  }) {
    if (confidence < 0.0 || confidence > 1.0) {
      throw ArgumentError('Confidence must be between 0.0 and 1.0');
    }
  }

  /// Checks if this prediction meets the confidence threshold
  bool meetsThreshold({double threshold = 0.70}) {
    return isConfidenceValid(confidence, threshold: threshold);
  }

  @override
  String toString() => 'PredictionConfidence(label: $label, confidence: ${confidence.toStringAsFixed(2)})';
}

/// Filters predictions that meet the minimum confidence threshold
///
/// Parameters:
/// - [predictions]: List of predictions with confidence scores
/// - [threshold]: Minimum confidence threshold (default 0.70)
///
/// Returns: Filtered list containing only predictions meeting the threshold
///
/// Example:
/// ```
/// var predictions = [
///   PredictionConfidence(label: 'A', confidence: 0.85),
///   PredictionConfidence(label: 'B', confidence: 0.40),
///   PredictionConfidence(label: 'C', confidence: 0.92),
/// ];
/// var filtered = filterConfidentPredictions(predictions, threshold: 0.70);
/// // Returns predictions for 'A' and 'C' only
/// ```
List<PredictionConfidence> filterConfidentPredictions(
  List<PredictionConfidence> predictions, {
  double threshold = 0.70,
}) {
  return predictions
      .where((prediction) => prediction.meetsThreshold(threshold: threshold))
      .toList();
}

/// Gets the prediction with the highest confidence from a list
///
/// Parameters:
/// - [predictions]: List of predictions
///
/// Returns: The prediction with highest confidence, or null if list is empty
PredictionConfidence? getHighestConfidencePrediction(
  List<PredictionConfidence> predictions,
) {
  if (predictions.isEmpty) {
    return null;
  }

  return predictions.reduce((current, next) =>
      next.confidence > current.confidence ? next : current);
}

/// Calculates average confidence from multiple predictions
///
/// Parameters:
/// - [predictions]: List of predictions
///
/// Returns: Average confidence score, or 0.0 if list is empty
double calculateAverageConfidence(List<PredictionConfidence> predictions) {
  if (predictions.isEmpty) {
    return 0.0;
  }

  final sum = predictions.fold<double>(
    0.0,
    (sum, prediction) => sum + prediction.confidence,
  );

  return sum / predictions.length;
}

/// Classifies confidence level as Low, Medium, or High
enum ConfidenceLevel { low, medium, high }

/// Gets the confidence level category for a given score
///
/// Parameters:
/// - [confidence]: The confidence score
///
/// Returns: ConfidenceLevel.low (< 0.5), medium (0.5-0.8), or high (> 0.8)
ConfidenceLevel getConfidenceLevel(double confidence) {
  if (confidence < 0.5) {
    return ConfidenceLevel.low;
  } else if (confidence <= 0.8) {
    return ConfidenceLevel.medium;
  } else {
    return ConfidenceLevel.high;
  }
}
