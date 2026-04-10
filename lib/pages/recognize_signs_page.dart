import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:show_fps/show_fps.dart';

import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/hand_detection_service.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/tts_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class RecognizePage extends StatefulWidget {
  const RecognizePage({
    super.key,
  });

  @override
  State<RecognizePage> createState() => _RecognizePageState();
}

class _RecognizePageState extends State<RecognizePage> {
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isSwitchingCamera = false;
  CameraDescription? frontCamera;
  CameraDescription? backCamera;
  bool _isFrontCamera = true;

  // hand detection service
  final HandDetectionService _handDetectionService = HandDetectionService();
  bool _isDetecting = false;
  List<Hand> _landmarks = [];

  String? _errorMessage;
  Set<int> _selectedMode = {0};
  bool _enableTextToSpeech = SettingsService.cachedTtsEnabled;


  String? _lastRecognizedWord;  // null = no sign being held
  String? _lastSpokenWord = "";

  List<String> prediction = [];
  final List<String> _predictionBuffer = [];
  final Duration _spellingVoteWindow = const Duration(seconds: 2, milliseconds: 500);
  DateTime? _spellingWindowStart;
  final Map<String, int> _spellingVoteCounts = {};
  String? _lastHoldHintLetter;
  DateTime? _lastHoldHintAt;

  // Hand landmark line drawing
  bool _showLandmark = SettingsService.cachedShowLandmarks;

  // Spelling mode controller
  TextEditingController _spellingController = TextEditingController();

  // FPS tracking
  int _frameCount = 0;
  DateTime? _lastFpsTime;
  double _currentFps = 0.0;

  // Shape stability tracking
  final List<Float32List> _shapeWindow = [];
  Float32List? _prevShape;
  int _stableFrameCount = 0;
  String? _stabilityStatus = "Initializing...";
  bool isStable = false;

  // Stability thresholds (tune per device)
  static const int _shapeWindowSize = 7;
  static const int _requiredStableFrames = 5;
  static const double _frameDeltaThreshold = 0.015;  // frame-to-frame change
  static const double _jitterThreshold = 0.010;       // window variance

  @override
  void initState() {
    super.initState();
    // Delay heavy startup work so route transition can finish smoothly first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await Future.wait([
      initializeModelResources(),
      _initializeCamera(),
    ]);
  }

  @override
  void dispose() {
    cameraController?.stopImageStream();
    cameraController?.dispose();
    _handDetectionService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          frontCamera!, 
          ResolutionPreset.medium,
          enableAudio: false,
        );

        _handDetectionService.init();

        await cameraController!.initialize();

        // Start the image stream
        await cameraController!.startImageStream(processCameraImage);
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras available';
          });
        }
      }
    } catch (e) {
      // Handle error - maybe show a snackbar or dialog
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    // Prevent multiple simultaneous switches
    if (SettingsService.cachedHaptic) {
      HapticFeedback.selectionClick();
    }

    if (_isSwitchingCamera) return;
    
    print("@DEBUG: Switch camera button onpressed");

    setState(() {
      _landmarks = []; // Clear landmarks immediately
      _isSwitchingCamera = true;
      _isCameraInitialized = false;
    });

    try {
      if(cameraController != null) {
        await cameraController!.stopImageStream();
        await cameraController!.dispose();
      }

      _isFrontCamera = !_isFrontCamera;

      final newCamera = _isFrontCamera ? frontCamera : backCamera;

      cameraController = CameraController(
        newCamera!, 
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      
      // Restart the image stream for hand landmark detection
      await cameraController!.startImageStream(processCameraImage);

      if(!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isSwitchingCamera = false;
      });
    } catch (e) {
      print("Error switching camera: $e");
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
          _errorMessage = 'Failed to switch camera';
        });
      }
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    // print("@DEBUG sensorOri=${cameraController!.description.sensorOrientation} lens=${cameraController!.description.lensDirection}");
    if (_isDetecting || !_isCameraInitialized) return;

    _isDetecting = true;
    
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
    
    try {
      final hands = _handDetectionService.detect(
        image,
        cameraController!.description.sensorOrientation,
      );

      if (hands.isNotEmpty) {
        final hand = hands[0];

        // Mirror exact webcam test pipeline: wrist subtract only, then StandardScaler
        final landmarks = hand.landmarks;
        
        // Debug: Print detected landmarks
        // print("=== DETECTED LANDMARKS ===");
        // for (int i = 0; i < landmarks.length; i++) {
        //   print("Landmark $i: x=${landmarks[i].x.toStringAsFixed(4)}, y=${landmarks[i].y.toStringAsFixed(4)}, z=${landmarks[i].z.toStringAsFixed(4)}");
        // }
        // print("========================");
        
        double wristX = landmarks[0].x;
        double wristY = landmarks[0].y;
        double wristZ = landmarks[0].z;

        var inputBuffer = Float32List(63);
        final int sensorOri = cameraController!.description.sensorOrientation;

        // Build raw wrist-relative shape vector for stability check
        final Float32List shapeVector = Float32List(63);

        for (int i = 0; i < 21; i++) {
          double xRel = landmarks[i].x - wristX;
          double yRel = landmarks[i].y - wristY;
          double zRel = landmarks[i].z - wristZ;

          double x, y;
          if (sensorOri == 270) {
            // Front camera: painter applies rotate(270°)+scale(-1,1)+rotate(180°)
            // → screen = (sensor_y, sensor_x), so x=yRel, y=xRel
            x = yRel;  y = -xRel;
          } else {
            // Back camera: painter applies rotate(90°)
            // → screen = (-sensor_y, sensor_x), so x=-yRel, y=xRel
            x = -yRel; y = xRel;
          }

          // Store raw wrist-relative for stability check
          shapeVector[i * 3 + 0] = x;
          shapeVector[i * 3 + 1] = y;
          shapeVector[i * 3 + 2] = zRel;

          // Standardize for model input
          inputBuffer[i * 3 + 0] = (x    - mean[i * 3 + 0]) / scale[i * 3 + 0];
          inputBuffer[i * 3 + 1] = (y    - mean[i * 3 + 1]) / scale[i * 3 + 1];
          inputBuffer[i * 3 + 2] = (zRel - mean[i * 3 + 2]) / scale[i * 3 + 2];
        }

        // Check shape stability before running prediction
        if (!_isShapeStable(shapeVector)) {
          prediction = [];  // Clear old prediction when unstable
          if (mounted) setState(() => _landmarks = hands);
          _isDetecting = false;
          return;
        }

        // Debug: Print processed landmarks
        // print("=== PROCESSED LANDMARKS (Normalized & Standardized) ===");
        // for (int i = 0; i < 21; i++) {
        //   print("Landmark $i: x=${inputBuffer[i * 3 + 0].toStringAsFixed(6)}, y=${inputBuffer[i * 3 + 1].toStringAsFixed(6)}, z=${inputBuffer[i * 3 + 2].toStringAsFixed(6)}");
        // }
        // print("=======================================================");

        final input = inputBuffer.reshape([1, 21, 3, 1]);
        final raw = predict(input);

        // Debug: Print raw model output
        // print("=== RAW MODEL OUTPUT ===");
        // print("Predictions: $raw");
        // print("========================");

        // Majority vote over last 7 frames to suppress flickering
        if (raw.isNotEmpty && raw[0] != "Detecting...") {
          final stable = raw[0];
          // TODO: Temporary disable majority vote, to prevent signing '5' but input previous sign issue
          // _predictionBuffer.add(raw[0]);
          // if (_predictionBuffer.length > 7) _predictionBuffer.removeAt(0);
          // final counts = <String, int>{};
          // for (final p in _predictionBuffer) counts[p] = (counts[p] ?? 0) + 1;
          // final stable = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
          prediction = [stable, if (raw.length > 1) raw[1]];

          if (isStable && _lastSpokenWord != stable){
            if (_enableTextToSpeech){
              if (_selectedMode.first != 1){
                if (SettingsService.cachedHaptic) {
                  HapticFeedback.mediumImpact();
                }
                TtsService.speakText(stable);
              } else if (_selectedMode.first == 1 && stable.length <= 2) {
                TtsService.speakText(stable);
              }
            }
            _lastSpokenWord = stable;
          }

          if (_selectedMode.first == 1) {
            if (isStable) {
              // New sign detected
              if (_lastRecognizedWord != stable) {
                _lastRecognizedWord = stable;
                _spellingWindowStart = DateTime.now();
              }
              
              // Check if held long enough
              if (_spellingWindowStart != null) {
                final elapsedMs = DateTime.now().difference(_spellingWindowStart!).inMilliseconds;
                if (elapsedMs >= _spellingVoteWindow.inMilliseconds) {
                  // Time reached - verify sign hasn't changed before adding
                  if (_lastRecognizedWord == stable && stable.length <= 2) {
                    addLetter(stable);
                    if (SettingsService.cachedHaptic) {
                      HapticFeedback.vibrate();
                    }
                    // to reset the overlay hint, so that user will know the timer reset while trying to input same sign.
                    isStable = false;
                    
                    _lastRecognizedWord = null;
                    _spellingWindowStart = null;
                  } else {
                    // Sign changed during hold - reset without adding
                    _lastRecognizedWord = null;
                    _spellingWindowStart = null;
                  }
                }
              }
            } else {
              _lastRecognizedWord = null;
              _spellingWindowStart = null;
            }
          } else {
            _spellingWindowStart = null;
            _spellingVoteCounts.clear();
            _lastHoldHintLetter = null;
          }
        } else {
          _predictionBuffer.clear();
          prediction = raw;
          _lastHoldHintLetter = null;
        }
      }

      if (mounted) setState(() => _landmarks = hands);
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void addLetter(String letter){
    _spellingController.text += letter;
  }

  /// Check if hand shape is stable enough for prediction.
  /// Returns true if shape variation is below tolerance for enough frames.
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
      _stabilityStatus = "Collecting samples... ${_shapeWindow.length}/$_shapeWindowSize";
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
      _stabilityStatus = "Moving (Δ=${frameDelta.toStringAsFixed(4)}, J=${windowJitter.toStringAsFixed(4)})";
    }

    final stability = _stableFrameCount >= _requiredStableFrames;
    isStable = stability;

    // TODO: Add detecting text
    return stability;
  }

  // void _showHoldHint(String letter) {
  //   final now = DateTime.now();
  //   final isSameLetter = _lastHoldHintLetter == letter;
  //   final withinCooldown = _lastHoldHintAt != null &&
  //       now.difference(_lastHoldHintAt!).inMilliseconds < 1000;

  //   if (isSameLetter && withinCooldown) return;

  //   _lastHoldHintLetter = letter;
  //   _lastHoldHintAt = now;

  //   if (!mounted) return;
  //   final messenger = ScaffoldMessenger.of(context);
  //   messenger.hideCurrentSnackBar();
  //   messenger.showSnackBar(
  //     SnackBar(
  //       content: Text('Detecting: $letter, please hold'),
  //       duration: Duration(milliseconds: 900),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Recognize Signs"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          
          // Camera section
          children: <Widget> [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Color(0xFF111827),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // LIVE CAMERA PREVIEW
                        if (_isCameraInitialized && cameraController != null && cameraController!.value.isInitialized)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: cameraController!.value.previewSize!.height,
                                height: cameraController!.value.previewSize!.width,
                                child: CameraPreview(cameraController!),
                              ),
                            ),
                          )
                        else if (_errorMessage != null)
                          Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
                        else 
                          Center(child: CircularProgressIndicator()),

                        // Hand landmark overlay
                        if (_isCameraInitialized && cameraController != null && cameraController!.value.isInitialized && _showLandmark)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: LandmarkPainter(
                                hands: _landmarks,
                                previewSize: cameraController!.value.previewSize!,
                                lensDirection: cameraController!.description.lensDirection,
                                sensorOrientation: cameraController!.description.sensorOrientation,
                              ),
                            ),
                          ),

                        // FPS Counter
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(0, 0, 0, 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FPS: ${_currentFps.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        if (prediction.isNotEmpty && !(prediction[0].length > 2) && _selectedMode.first == 1 && isStable)
                          // Hint overlay
                          Positioned(
                            top: 50,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Detecting: ${prediction[0]}, Keep holding',
                                // 'Detecting: ${_currentFps.toStringAsFixed(1)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Switch camera direction button
                        Positioned(
                          bottom: 20,
                          // right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(0,0,0,0.2),
                              shape: BoxShape.circle
                            ),
                            child: IconButton(
                              onPressed: _switchCamera,
                              icon: Icon(
                                Icons.flip_camera_ios, 
                              color: Color.fromRGBO(255,255,255,0.7),
                                size: 32,
                              )
                            ),
                          ),
                        ),

                        // Landmark drawing toggle button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(0,0,0,0.2),
                              shape: BoxShape.circle
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (SettingsService.cachedHaptic) {
                                  HapticFeedback.selectionClick();
                                }
                                _showLandmark = !_showLandmark;
                                var snackBar = SnackBar(
                                  content: Text("Landmark Drawing Disabled."),
                                  duration: Duration(seconds: 1),
                                );

                                if(_showLandmark){
                                  snackBar = SnackBar(
                                    content: Text("Landmark Drawing Enabled."),
                                    duration: Duration(seconds: 1),
                                  );
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              },
                              icon: Icon(
                                Icons.timeline, 
                              color: Color.fromRGBO(255,255,255,0.7),
                                size: 32,
                              )
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),

            if(_selectedMode.first == 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    // padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      children: [
                        if (prediction.isNotEmpty)
                          if (prediction[0].length <= 7)
                            Text(prediction[0], style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold))
                          else
                            Text(prediction[0], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                        else
                          Text("Detecting...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Spacer(),
                        
                        if (prediction.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                                child: Text("Correct", style: TextStyle(color: Colors.green)),
                              ),
                              SizedBox(width: 10),
                              Text("${prediction[1]}% Accurate", style: TextStyle(color: Colors.grey))
                            ],
                          )
                      ],
                    ),
                  ),
                ),
              )
            else
            // Spelling section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _spellingController,
                                readOnly: true,
                                showCursor: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Spell something...',
                                  hintStyle: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 0.4)
                                  )
                                ),
                                style: TextStyle(
                                  fontSize: 14
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (SettingsService.cachedHaptic) {
                                  HapticFeedback.selectionClick();
                                }
                                TtsService.speakText(_spellingController.text);
                              },
                              icon: Icon(
                                Icons.volume_up,
                                size: 20,
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (SettingsService.cachedHaptic) {
                                    HapticFeedback.selectionClick();
                                  }
                                  _spellingController.text += " ";
                                }, 
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.space_bar, color: Colors.black),
                                      SizedBox(width: 4),
                                      Text(
                                        "Space",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (SettingsService.cachedHaptic) {
                                    HapticFeedback.selectionClick();
                                  }
                                  final text = _spellingController.text;
                                  final cursorPos = _spellingController.selection.baseOffset;

                                  if (cursorPos > 0) {
                                    final newText =
                                        text.substring(0, cursorPos - 1) + text.substring(cursorPos);

                                    _spellingController.text = newText;

                                    // Move cursor back correctly
                                    _spellingController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: cursorPos - 1),
                                    );
                                  }
                                }, 
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.backspace_outlined, color: Colors.black),
                                      SizedBox(width: 4),
                                      Text(
                                        "Delete",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (SettingsService.cachedHaptic) {
                                    HapticFeedback.selectionClick();
                                  }
                                  _spellingController.clear();
                                }, 
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.replay, color: Colors.black),
                                      SizedBox(width: 4),
                                      Text(
                                        "Clear",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

            // toggle button section
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity, // ✅ expand to full width
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Live Recognition'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Spelling Mode'),
                    ),
                  ],
                  selected: _selectedMode,
                  onSelectionChanged: (Set<int> newSelection) {
                    if (SettingsService.cachedHaptic) {
                      HapticFeedback.selectionClick();
                    }

                    setState(() {
                      _selectedMode = newSelection;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color.fromRGBO(99, 102, 241, 1);
                      }
                      return const Color.fromRGBO(236, 236, 240, 1);
                    }),
                    foregroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.black;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),



            // text-to-speech section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Text(
                    "Text-to-Speech",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  Container(
                    height: 40,
                    width: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26), 
                      borderRadius: BorderRadius.circular(8), 
                    ),
                    child: Material(
                      color: Colors.transparent, 
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8), 
                        onTap: () {
                          if (SettingsService.cachedHaptic) {
                            HapticFeedback.selectionClick();
                          }
                          setState(() {
                            _enableTextToSpeech = !_enableTextToSpeech;
                            print(_enableTextToSpeech ? "TTS enabled" : "TTS disabled");
                          });
                          SettingsService.setTts(_enableTextToSpeech);
                        },
                        child: Icon(
                          _enableTextToSpeech ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                          size: 20, 
                          color: _enableTextToSpeech ? Color.fromRGBO(99, 102, 241, 1) : Colors.black54,
                        ),
                      ),
                    ),
                  ), 
                ],
              ),
            )
            
          ],
        ),
      ),
    );
  }

}