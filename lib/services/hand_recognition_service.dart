import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'package:sign_language_recognition_app/models/prediction_result.dart';
import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';
import 'hand_detection_service.dart';

/// Service that handles all hand recognition: camera, detection, stability, and prediction
/// Emits PredictionResult via Stream for reactive UI updates
class HandRecognitionService {
  // Camera management
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  CameraDescription? _backCamera;
  bool _isFrontCamera = true;
  bool _isCameraInitialized = false;
  bool _isSwitchingCamera = false;
  bool _controllerDisposed = false;  // Track if current controller is disposed
  bool _imageStreamActive = false;  // Track if image stream is currently streaming

  // Detection state
  final HandDetectionService _handDetectionService = HandDetectionService();
  bool _isDetecting = false;

  // Stream controller for prediction results
  final StreamController<PredictionResult> _predictionController =
      StreamController<PredictionResult>.broadcast();
  Stream<PredictionResult> get predictions => _predictionController.stream;

  // Shape stability tracking
  final List<Float32List> _shapeWindow = [];
  Float32List? _prevShape;
  int _stableFrameCount = 0;
  String _stabilityStatus = "Initializing...";

  // Stability thresholds (tune per device)
  static const int _shapeWindowSize = 7;
  static const int _requiredStableFrames = 5;
  static const double _frameDeltaThreshold = 0.015;
  static const double _jitterThreshold = 0.010;

  // FPS tracking
  int _frameCount = 0;
  DateTime? _lastFpsTime;
  double _currentFps = 0.0;

  Future<void> initialize() async {
    try {
      print('📷 [HAND_RECOGNITION] initialize() called');
      final startTime = DateTime.now();
      
      print('📷 [HAND_RECOGNITION] Fetching available cameras...');
      final camerasStart = DateTime.now();
      final cameras = await availableCameras();
      final camerasFetchDuration = DateTime.now().difference(camerasStart);
      print('📷 [HAND_RECOGNITION] Got cameras in ${camerasFetchDuration.inMilliseconds}ms. Found ${cameras.length} cameras');

      print('📷 [HAND_RECOGNITION] Finding front and back cameras...');
      _frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      _backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      print('📷 [HAND_RECOGNITION] Found front and back cameras');

      print('📷 [HAND_RECOGNITION] Initializing hand detection service...');
      final handDetStart = DateTime.now();
      _handDetectionService.init();
      final handDetDuration = DateTime.now().difference(handDetStart);
      print('📷 [HAND_RECOGNITION] Hand detection service initialized in ${handDetDuration.inMilliseconds}ms');
      
      final totalDuration = DateTime.now().difference(startTime);
      print('📷 [HAND_RECOGNITION] ✅ Initialization completed in ${totalDuration.inMilliseconds}ms');
    } catch (e) {
      print('❌ [HAND_RECOGNITION] Error: $e');
      _predictionController.addError('Failed to initialize cameras: $e');
    }
  }

  /// Start camera stream and hand detection
  Future<void> startCamera() async {
    try {
      print('📷 [HAND_RECOGNITION] startCamera() called');
      final startTime = DateTime.now();
      
      if (_cameraController != null) {
        print('📷 [HAND_RECOGNITION] Disposing old camera controller...');
        print('📷 [HAND_RECOGNITION] Current _controllerDisposed: $_controllerDisposed');
        final disposeStart = DateTime.now();
        _controllerDisposed = true;  // Mark as disposed to prevent race conditions
        print('📷 [HAND_RECOGNITION] ✅ Set _controllerDisposed = true');
        await _cameraController!.dispose();
        final disposeDuration = DateTime.now().difference(disposeStart);
        print('📷 [HAND_RECOGNITION] Old camera disposed in ${disposeDuration.inMilliseconds}ms');
        _cameraController = null;  // Clear the reference
        print('📷 [HAND_RECOGNITION] ✅ Set _cameraController = null');
      }

      _controllerDisposed = false;  // Reset flag for new controller
      print('📷 [HAND_RECOGNITION] ✅ Set _controllerDisposed = false (ready for new controller)');
      print('📷 [HAND_RECOGNITION] Creating camera controller (${_isFrontCamera ? 'front' : 'back'} camera)...');
      _cameraController = CameraController(
        _isFrontCamera ? _frontCamera! : _backCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _imageStreamActive = false;  // ✅ Reset stream state for new controller
      print('📷 [HAND_RECOGNITION] ✅ New _cameraController created');

      print('📷 [HAND_RECOGNITION] Initializing camera controller...');
      final initStart = DateTime.now();
      await _cameraController!.initialize();
      final initDuration = DateTime.now().difference(initStart);
      print('📷 [HAND_RECOGNITION] Camera controller initialized in ${initDuration.inMilliseconds}ms');
      _isCameraInitialized = true;
      print('📷 [HAND_RECOGNITION] ✅ Set _isCameraInitialized = true');

      print('📷 [HAND_RECOGNITION] Starting image stream...');
      final streamStart = DateTime.now();
      await _cameraController!.startImageStream(_processCameraImage);
      _imageStreamActive = true;  // ✅ Mark stream as active
      final streamDuration = DateTime.now().difference(streamStart);
      print('📷 [HAND_RECOGNITION] Image stream started in ${streamDuration.inMilliseconds}ms');
      
      final totalDuration = DateTime.now().difference(startTime);
      print('📷 [HAND_RECOGNITION] ✅ startCamera() completed in ${totalDuration.inMilliseconds}ms');
    } catch (e) {
      print('❌ [HAND_RECOGNITION] Error in startCamera: $e');
      _predictionController.addError('Failed to start camera: $e');
    }
  }

  // NFR001: Latency tracking for ML Kit + TFLite inference
  final List<double> _latencyHistory = [];
  static const int _latencyHistorySize = 30;

  /// Stop camera stream
  Future<void> stopCamera() async {
    try {
      print('📷 [HAND_RECOGNITION] stopCamera() called');
      print('📷 [HAND_RECOGNITION] Current state: _controllerDisposed=$_controllerDisposed, _imageStreamActive=$_imageStreamActive, _cameraController=${_cameraController != null ? 'exists' : 'null'}');
      
      _controllerDisposed = true;  // Mark as disposed to prevent race conditions
      print('📷 [HAND_RECOGNITION] ✅ Set _controllerDisposed = true');
      
      if (_cameraController != null && _imageStreamActive) {
        print('📷 [HAND_RECOGNITION] Stopping image stream...');
        await _cameraController?.stopImageStream();
        _imageStreamActive = false;  // ✅ Mark stream as stopped
        print('📷 [HAND_RECOGNITION] ✅ Image stream stopped');
      } else if (_cameraController == null) {
        print('⚠️ [HAND_RECOGNITION] _cameraController is already null (cannot stop stream)');
      } else if (!_imageStreamActive) {
        print('⚠️ [HAND_RECOGNITION] Image stream already stopped (skipping redundant stop)');
      }
      
      _isCameraInitialized = false;
      print('📷 [HAND_RECOGNITION] ✅ Set _isCameraInitialized = false');
      print('📷 [HAND_RECOGNITION] ✅ stopCamera() completed');
    } catch (e) {
      print('❌ [HAND_RECOGNITION] Error in stopCamera: $e');
      _predictionController.addError('Failed to stop camera: $e');
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_isSwitchingCamera) return;

    _isSwitchingCamera = true;

    try {
      await stopCamera();
      _isFrontCamera = !_isFrontCamera;
      await startCamera();
    } catch (e) {
      _predictionController.addError('Failed to switch camera: $e');
    } finally {
      _isSwitchingCamera = false;
    }
  }

  /// Process camera frame: detect hand, check stability, predict
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isCameraInitialized || _controllerDisposed) return;

    _isDetecting = true;

    try {
      // Capture controller reference ATOMICALLY to prevent race conditions
      // This prevents TOCTOU (Time-of-check-time-of-use) where controller
      // could be disposed between the null check and actual usage
      final controller = _cameraController;
      if (controller == null || _controllerDisposed) {
        print('⚠️ [HAND_RECOGNITION] Controller became null/disposed during frame processing (frame dropped safely)');
        _isDetecting = false;
        return;
      }

      // FPS calculation
      _frameCount++;
      DateTime now = DateTime.now();
      if (_lastFpsTime != null) {
        Duration elapsed = now.difference(_lastFpsTime!);
        if (elapsed.inMilliseconds >= 1000) {
          _currentFps = (_frameCount / elapsed.inMilliseconds) * 1000;
          _frameCount = 0;
          _lastFpsTime = now;
        }
      } else {
        _lastFpsTime = now;
      }

      // NFR001: Start measuring latency (ML Kit + TFLite inference)
      final mlStart = DateTime.now();
      final hands = _handDetectionService.detect(
        image,
        controller.description.sensorOrientation,  // ✅ Safe - using captured reference
      );

      List<String> prediction = [];
      bool isStable = false;

      if (hands.isNotEmpty) {
        final hand = hands[0];
        final landmarks = hand.landmarks;

        double wristX = landmarks[0].x;
        double wristY = landmarks[0].y;
        double wristZ = landmarks[0].z;

        var inputBuffer = Float32List(63);
        
        // Re-check controller before accessing (extra safety)
        if (_controllerDisposed || _cameraController == null) {
          print('⚠️ [HAND_RECOGNITION] Controller disposed during landmark processing (frame dropped)');
          _isDetecting = false;
          return;
        }
        
        final int sensorOri = controller.description.sensorOrientation;  // ✅ Using captured reference

        // Build raw wrist-relative shape vector for stability check
        final Float32List shapeVector = Float32List(63);

        for (int i = 0; i < 21; i++) {
          double xRel = landmarks[i].x - wristX;
          double yRel = landmarks[i].y - wristY;
          double zRel = landmarks[i].z - wristZ;

          double x, y;
          if (sensorOri == 270) {
            x = yRel;
            y = -xRel;
          } else {
            x = -yRel;
            y = xRel;
          }

          // Store raw wrist-relative for stability check
          shapeVector[i * 3 + 0] = x;
          shapeVector[i * 3 + 1] = y;
          shapeVector[i * 3 + 2] = zRel;

          // Standardize for model input
          inputBuffer[i * 3 + 0] =
              (x - mean[i * 3 + 0]) / scale[i * 3 + 0];
          inputBuffer[i * 3 + 1] =
              (y - mean[i * 3 + 1]) / scale[i * 3 + 1];
          inputBuffer[i * 3 + 2] =
              (zRel - mean[i * 3 + 2]) / scale[i * 3 + 2];
        }

        // Check shape stability before running prediction
        isStable = _isShapeStable(shapeVector);

        if (isStable) {
          final input = inputBuffer.reshape([1, 21, 3, 1]);
          final raw = predict(input);

          if (raw.isNotEmpty && raw[0] != "Detecting...") {
            prediction = [
              raw[0],
              if (raw.length > 1) raw[1]
            ];
          }
        }
      }

      // NFR001: Calculate latency (ML Kit landmark detection + TFLite inference)
      final mlLatencyMs = DateTime.now().difference(mlStart).inMilliseconds.toDouble();
      
      // Track latency history for averaging
      _latencyHistory.add(mlLatencyMs);
      if (_latencyHistory.length > _latencyHistorySize) {
        _latencyHistory.removeAt(0);
      }
      
      // Log per-frame and average latency
      print('📊 [NFR001] Frame latency: ${mlLatencyMs.toStringAsFixed(2)}ms');
      if (_latencyHistory.length == _latencyHistorySize) {
        final avgLatency = _latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length;
        print('📊 [NFR001] Average latency (last $_latencyHistorySize frames): ${avgLatency.toStringAsFixed(2)}ms');
      }

      // Final check before emitting to stream
      if (!_controllerDisposed && _cameraController != null) {
        _predictionController.add(
          PredictionResult(
            prediction: prediction,
            landmarks: hands,
            isStable: isStable,
            stabilityStatus: _stabilityStatus,
            fps: _currentFps,
            latencyMs: mlLatencyMs,
          ),
        );
      } else {
        print('⚠️ [HAND_RECOGNITION] Frame dropped - controller no longer available for stream emission');
      }
    } catch (e) {
      _predictionController.addError('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Check if hand shape is stable enough for prediction
  bool _isShapeStable(Float32List currentShape) {
    // 1) Compute frame-to-frame delta
    double frameDelta = 0.0;
    if (_prevShape != null) {
      for (int i = 0; i < currentShape.length; i++) {
        final d = currentShape[i] - _prevShape![i];
        frameDelta += d * d;
      }
      frameDelta = math.sqrt(frameDelta / currentShape.length);
    }

    _prevShape = currentShape;

    // 2) Add to rolling window
    _shapeWindow.add(currentShape);
    if (_shapeWindow.length > _shapeWindowSize) {
      _shapeWindow.removeAt(0);
    }

    // Need full window before checking stability
    if (_shapeWindow.length < _shapeWindowSize) {
      _stableFrameCount = 0;
      _stabilityStatus =
          "Collecting samples... ${_shapeWindow.length}/$_shapeWindowSize";
      return false;
    }

    // 3) Compute jitter (per-dimension std dev, then average)
    double jitterSum = 0.0;
    for (int dim = 0; dim < currentShape.length; dim++) {
      // Mean
      double mean = 0.0;
      for (final v in _shapeWindow) {
        mean += v[dim];
      }
      mean /= _shapeWindow.length;

      // Std dev
      double varSum = 0.0;
      for (final v in _shapeWindow) {
        final d = v[dim] - mean;
        varSum += d * d;
      }
      final std = math.sqrt(varSum / _shapeWindow.length);
      jitterSum += std;
    }
    final windowJitter = jitterSum / currentShape.length;

    // 4) Check both conditions
    final frameStable = (frameDelta < _frameDeltaThreshold);
    final windowStable = (windowJitter < _jitterThreshold);

    if (frameStable && windowStable) {
      _stableFrameCount++;
      _stabilityStatus = "Stable: $_stableFrameCount/$_requiredStableFrames";
    } else {
      _stableFrameCount = 0;
      _stabilityStatus =
          "Moving (Δ=${frameDelta.toStringAsFixed(4)}, J=${windowJitter.toStringAsFixed(4)})";
    }

    final stability = _stableFrameCount >= _requiredStableFrames;
    return stability;
  }

  /// Get current camera controller
  CameraController? get cameraController => _cameraController;

  /// Check if camera is initialized
  bool get isCameraInitialized => _isCameraInitialized;

  /// Check if switching camera
  bool get isSwitchingCamera => _isSwitchingCamera;

  /// Get front camera description
  CameraDescription? get frontCamera => _frontCamera;

  /// Get back camera description
  CameraDescription? get backCamera => _backCamera;

  /// Check if using front camera
  bool get isFrontCamera => _isFrontCamera;

  /// Cleanup resources
  Future<void> dispose() async {
    print('📷 [HAND_RECOGNITION] dispose() called (FULL CLEANUP)');
    print('📷 [HAND_RECOGNITION] Current state: _controllerDisposed=$_controllerDisposed, _cameraController=${_cameraController != null ? 'exists' : 'null'}');
    try {
      await stopCamera();
      print('📷 [HAND_RECOGNITION] ✅ stopCamera() completed');
      
      if (_cameraController != null) {
        print('📷 [HAND_RECOGNITION] Disposing camera controller...');
        await _cameraController?.dispose();
        print('📷 [HAND_RECOGNITION] ✅ Camera controller disposed');
      } else {
        print('⚠️ [HAND_RECOGNITION] _cameraController already null');
      }
      
      _handDetectionService.dispose();
      print('📷 [HAND_RECOGNITION] ✅ Hand detection service disposed');
      
      await _predictionController.close();
      print('📷 [HAND_RECOGNITION] ✅ Prediction controller closed');
    } catch (e) {
      print('❌ [HAND_RECOGNITION] Error in dispose(): $e');
    }
  }

  /// Cleanup camera only (for use when service is reused via singleton)
  /// This stops the camera but doesn't dispose the service (which may be reused)
  Future<void> stopCameraOnly() async {
    print('📷 [HAND_RECOGNITION] stopCameraOnly() called (singleton cleanup)');
    print('📷 [HAND_RECOGNITION] Current state: _controllerDisposed=$_controllerDisposed, _cameraController=${_cameraController != null ? 'exists' : 'null'}');
    try {
      await stopCamera();
      // Don't dispose the controller here - let startCamera() handle it on next use
      // This prevents "used after being disposed" errors when reusing the singleton
      print('📷 [HAND_RECOGNITION] ✅ Camera stopped (controller preserved for reuse)');
    } catch (e) {
      print('❌ [HAND_RECOGNITION] Error stopping camera: $e');
    }
  }
}
