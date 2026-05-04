// Tests for LandmarkPainter - auto-generated via Copilot

import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';

void main() {
  group('LandmarkPainter', () {
    test('shouldRepaint() always returns true', () {
      // Arrange
      final painter = LandmarkPainter(
        hands: const <Hand>[],
        previewSize: const Size(640, 480),
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 0,
      );

      // Act
      final result = painter.shouldRepaint(_DummyPainter());

      // Assert
      expect(result, isTrue);
    });

    test('paint() does not throw when no hands are present', () {
      // Arrange
      final painter = LandmarkPainter(
        hands: const <Hand>[],
        previewSize: const Size(640, 480),
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 270,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Act & Assert
      expect(
        () => painter.paint(canvas, const Size(640, 480)),
        returnsNormally,
      );
    });

    test('HandLandmarkConnections exposes 21 valid connection pairs', () {
      // Arrange
      final connections = HandLandmarkConnections.connections;

      // Act
      final flattened = connections.expand((pair) => pair).toList();

      // Assert
      expect(connections.length, 21);
      expect(flattened.every((index) => index >= 0 && index <= 20), isTrue);
    });
  });
}

class _DummyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}