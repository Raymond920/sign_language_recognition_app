import 'package:hand_landmarker/hand_landmarker.dart';

/// Represents a single prediction result from hand recognition
class PredictionResult {
  final List<String> prediction; // [sign, confidence%, ...]
  final List<Hand> landmarks; // Hand landmark data for drawing
  final bool isStable; // Whether hand is currently stable
  final String stabilityStatus; // Human-readable stability info
  final double fps; // Frames per second

  PredictionResult({
    required this.prediction,
    required this.landmarks,
    required this.isStable,
    required this.stabilityStatus,
    required this.fps,
  });
}
