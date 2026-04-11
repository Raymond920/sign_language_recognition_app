import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';
import 'package:sign_language_recognition_app/services/hand_detection_service.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';

class LessonDetail {
  final Lesson info;
  final List<Sign> signs;

  LessonDetail({required this.info, required this.signs});

  int get completedCount => signs.where((s) => s.isCompleted).length;

  // Used by the lessons list
  double get totalProgress => signs.isEmpty ? 0.0 : completedCount / signs.length;
}

class LessonContentPage extends StatefulWidget {
  final int lessonId;  // Changed to accept lesson ID from database
  
  const LessonContentPage({
    super.key, 
    required this.lessonId
  });

  @override
  State<LessonContentPage> createState() => _LessonContentPageState();
}

class _LessonContentPageState extends State<LessonContentPage> {
  late int currentIndex;
  bool hasDetectedCorrectSign = false;  // Simulating the "Great Job" overlay

  // Database-loaded data (replaces mockLessonDetail)
  late Lesson lesson;
  late List<Sign> signs;
  final DBHelper dbHelper = DBHelper();
  bool _isLoading = true;

  // Camera and detection
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  List<Hand> _landmarks = [];
  String? _errorMessage;
  
  // Current prediction
  List<String> prediction = [];
  
  // Hand detection service
  final HandDetectionService _handDetectionService = HandDetectionService();
  
  // Shape stability tracking
  final List<Float32List> _shapeWindow = [];
  Float32List? _prevShape;
  int _stableFrameCount = 0;
  bool isStable = false;
  
  // Stability thresholds (tune per device)
  static const int _shapeWindowSize = 7;
  static const int _requiredStableFrames = 5;
  static const double _frameDeltaThreshold = 0.015;
  static const double _jitterThreshold = 0.010;
  
  // Correct sign hold tracking
  String? _lastCorrectSignDetected;
  DateTime? _correctSignHoldStart;
  static const Duration _correctSignHoldDuration = Duration(seconds: 2, milliseconds: 500);
  
  // Hand landmark drawing
  bool _showLandmark = SettingsService.cachedShowLandmarks;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadLessonData();
    });
  }

  Future<void> _loadLessonData() async {
    try {
      // Fetch lesson and signs from database
      final lessons = await dbHelper.getAllLessons();
      final targetLesson = lessons.firstWhere(
        (l) => l.id == widget.lessonId,
        orElse: () => lessons.isNotEmpty ? lessons.first : Lesson(
          id: 1,
          title: 'Lesson Not Found',
          description: 'Could not load lesson from database',
          signCount: 0,
          progress: 0.0,
        ),
      );
      
      final loadedSigns = await dbHelper.getSignsForLesson(widget.lessonId);
      
      // Calculate progress and current index
      final totalProgress = loadedSigns.isEmpty ? 0.0 : loadedSigns.where((s) => s.isCompleted).length / loadedSigns.length;
      final calculatedIndex = totalProgress >= 1.0 
          ? 0 
          : (targetLesson.progress * loadedSigns.length).round();
      
      if (mounted) {
        setState(() {
          lesson = targetLesson;
          signs = loadedSigns;
          currentIndex = calculatedIndex;
          _isLoading = false;
        });
        
        // Now initialize camera and models
        _initialize();
      }
    } catch (e) {
      print('❌ Error loading lesson data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _saveFinalProgress() async {
    // Save any remaining progress when exiting
    print('\n' + '='*70);
    print('💾 LESSON EXIT: Saving final progress...');
    
    int completedCount = signs.where((s) => s.isCompleted).length;
    int totalCount = signs.length;
    double finalProgress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    print('   Completed Signs: $completedCount / $totalCount');
    print('   Final Progress: ${(finalProgress * 100).toStringAsFixed(1)}%');
    
    if (completedCount == totalCount && totalCount > 0) {
      print('   🎉 LESSON COMPLETED!');
    } else if (completedCount > 0) {
      print('   📊 Lesson partially completed');
    }
    
    print('='*70 + '\n');
  }

  void onSignDetectedCorrectly() async {
    if (!signs[currentIndex].isCompleted) {
      // Mark as completed locally
      setState(() {
        signs[currentIndex].isCompleted = true;
      });
      
      // Save progress to database
      try {
        final currentSign = signs[currentIndex];
        await dbHelper.updateSignProgress(widget.lessonId, currentSign.id);
        print('✅ Progress saved: Sign ${currentSign.name} (ID: ${currentSign.id}) marked as completed');
        
        // Check if lesson is now fully completed
        int completedCount = signs.where((s) => s.isCompleted).length;
        int totalCount = signs.length;
        
        if (completedCount == totalCount && totalCount > 0) {
          print('🎉 LESSON FULLY COMPLETED! ($completedCount/$totalCount signs done)');
        }
      } catch (e) {
        print('❌ Error saving progress: $e');
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _handDetectionService.init();
      await cameraController!.initialize();
      
      await cameraController!.startImageStream(processCameraImage);
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (_isDetecting || !_isCameraInitialized) return;

    _isDetecting = true;

    try {
      final hands = _handDetectionService.detect(
        image,
        cameraController!.description.sensorOrientation,
      );

      if (hands.isNotEmpty) {
        final hand = hands[0];
        final landmarks = hand.landmarks;

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
          inputBuffer[i * 3 + 0] = (x - mean[i * 3 + 0]) / scale[i * 3 + 0];
          inputBuffer[i * 3 + 1] = (y - mean[i * 3 + 1]) / scale[i * 3 + 1];
          inputBuffer[i * 3 + 2] = (zRel - mean[i * 3 + 2]) / scale[i * 3 + 2];
        }

        // Check shape stability before running prediction
        if (!_isShapeStable(shapeVector)) {
          if (mounted) setState(() => _landmarks = hands);
          _isDetecting = false;
          return;
        }

        final input = inputBuffer.reshape([1, 21, 3, 1]);
        final raw = predict(input);

        // Store prediction and check if detected sign matches the target sign
        if (raw.isNotEmpty && raw[0] != "Detecting...") {
          final detectedSign = raw[0];
          final currentSign = signs[currentIndex];
          
          prediction = raw;

          if (isStable && detectedSign == currentSign.targetLabel) {
            // New correct sign detected
            if (_lastCorrectSignDetected != detectedSign) {
              _lastCorrectSignDetected = detectedSign;
              _correctSignHoldStart = DateTime.now();
            }
            
            // Check if held long enough
            if (_correctSignHoldStart != null) {
              final elapsedMs = DateTime.now().difference(_correctSignHoldStart!).inMilliseconds;
              if (elapsedMs >= _correctSignHoldDuration.inMilliseconds) {
                // Time reached - verify sign hasn't changed before showing feedback
                if (_lastCorrectSignDetected == detectedSign && !hasDetectedCorrectSign) {
                  if (mounted) {
                    setState(() {
                      hasDetectedCorrectSign = true;
                    });
                    onSignDetectedCorrectly();
                  }
                }
              }
            }
          } else if (isStable) {
            // Different sign detected - reset hold tracking
            _lastCorrectSignDetected = null;
            _correctSignHoldStart = null;
          }
        } else {
          prediction = raw;
          _lastCorrectSignDetected = null;
          _correctSignHoldStart = null;
        }
      }

      if (mounted) setState(() => _landmarks = hands);
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Check if hand shape is stable enough for prediction.
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
    } else {
      _stableFrameCount = 0;
    }

    final stability = _stableFrameCount >= _requiredStableFrames;
    isStable = stability;

    return stability;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching lesson data from database
    if (_isLoading || signs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final currentSign = signs[currentIndex];
    final totalSteps = signs.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () async {
            await _saveFinalProgress();
            if (mounted) {
              Navigator.pop(context);
            }
          }, 
          icon: const Icon(Icons.arrow_back),
        ),
        // Now loading from database via DBHelper
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title, style: const TextStyle(fontSize: 16),),
            Text(
              "Step ${currentIndex + 1} of $totalSteps",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              SizedBox(height: 12,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / totalSteps,
                  backgroundColor: Colors.indigo[100],
                  color: Colors.indigoAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  // Learning Card
                  _buildInstructionCard(currentSign),

                  const SizedBox(height: 20),

                  // Practice Card
                  _buildPracticeCard(currentSign),

                ],
              ),
              
              // Bottom Navigation Buttons
              _buildBottomNav(totalSteps),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard(Sign sign) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Learning: ${sign.name}", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 150, width: 150,
              // color: Colors.grey[200],
              // child: const Icon(Icons.image, size: 50, color: Colors.grey),
              child: Image.asset(
                sign.imagePath
              )
            ),
          ),
          const SizedBox(height: 20),
          const Text("How to sign:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Using our split logic for bullet points
          ...sign.instructions.map((text) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text("• $text", style: const TextStyle(color: Colors.blueGrey)),
          )),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    );
  }
  
  Widget _buildPracticeCard(Sign currentSign) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Practice Time", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          // Live Camera with hand detection
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera Preview
                if (_isCameraInitialized && cameraController != null && cameraController!.value.isInitialized)
                  SizedBox.expand(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: cameraController!.value.previewSize!.height,
                          height: cameraController!.value.previewSize!.width,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                // Target sign label
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Target: ${currentSign.targetLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

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

                // Stability indicator
                if (isStable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Detecting overlay - shows for both single signs and words
                if (prediction.isNotEmpty && prediction[0] != "Detecting..." && isStable)
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Detecting: ${prediction[0]}, Keep holding',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Feedback Badge (Mocking a successful detection)
          if (hasDetectedCorrectSign)
            Container(
              padding: const EdgeInsets.all(12),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Great job!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Your sign matches perfectly",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[800],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNav(int totalSteps) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: currentIndex > 0
                ? () {
                    setState(() {
                      currentIndex--;
                      hasDetectedCorrectSign = false;
                      _stableFrameCount = 0;
                      prediction = [];
                      _lastCorrectSignDetected = null;
                      _correctSignHoldStart = null;
                    });
                  }
                : null,
            child: const Text("Previous"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: (hasDetectedCorrectSign || signs[currentIndex].isCompleted) ? () async {
              if (currentIndex < totalSteps - 1) {
                setState(() {
                  currentIndex++;
                  hasDetectedCorrectSign = false;
                  _stableFrameCount = 0;
                  prediction = [];
                  _lastCorrectSignDetected = null;
                  _correctSignHoldStart = null;
                });
              } else {
                // Final step completed - save and exit
                await _saveFinalProgress();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            } : null,
            child: Text(currentIndex == totalSteps - 1 ? "Complete" : "Next Step"),
          ),
        ],
      ),
    );
  }
}