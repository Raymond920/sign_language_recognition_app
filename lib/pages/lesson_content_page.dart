import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:sign_language_recognition_app/models/lesson_model.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:sign_language_recognition_app/services/achivement_service.dart';
import 'package:sign_language_recognition_app/services/hand_recognition_service.dart';
import 'package:sign_language_recognition_app/services/service_manager.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/profile_service.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';

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
  bool hasDetectedCorrectSign = false;

  // Database-loaded data
  late Lesson lesson;
  late List<Sign> signs;
  final DBHelper dbHelper = DBHelper();
  bool _isLoading = true;

  // Use preloaded singleton service instead of creating new instance (avoids 2150ms init lag)
  late final HandRecognitionService _recognitionService;

  // Current prediction & landmarks from service stream
  List<String> prediction = [];
  List<Hand> _landmarks = [];
  bool isStable = false;
  String? _errorMessage;

  // Correct sign hold tracking
  DateTime? _correctSignHoldStart;
  static const Duration _correctSignHoldDuration =
      Duration(seconds: 2, milliseconds: 500);

  // Hand landmark drawing
  bool _showLandmark = SettingsService.cachedShowLandmarks;
  
  // Study session tracking
  late DateTime _lessonStartTime;
  
  // Scroll controller for auto-scroll
  late ScrollController _scrollController;
  bool _isPageReady = false;  // ✅ 0.5s stabilization delay for camera controller

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Get preloaded singleton service (no init lag!)
    _recognitionService = ServiceManager.getHandRecognitionService();
    
    print('📖 [LESSON] initState called - using preloaded singleton service');
    
    // ✅ Wait 0.5s for camera controller to stabilize (prevents race condition)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isPageReady = true;
        print('📖 [LESSON] ✅ Page ready after 0.5s stabilization delay');
      });
    });
    
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
          isCompleted: false,
          pointsClaimed: false,
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
        
        // Track lesson start time
        _lessonStartTime = DateTime.now();
        
        // Initialize service and hand recognition stream
        _initRecognitionService();
      }
    } catch (e) {
      print('❌ Error loading lesson data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initRecognitionService() async {
    try {
      print('📖 [LESSON] _initRecognitionService() called');
      final initStart = DateTime.now();
      
      // Model already initialized, hand recognition service already initialized via singleton
      print('📖 [LESSON] Hand recognition service: Using preloaded singleton (skipped re-init)');
      
      if (mounted) {
        print('📖 [LESSON] Starting camera...');
        final cameraStart = DateTime.now();
        await _recognitionService.startCamera();
        final cameraDuration = DateTime.now().difference(cameraStart);
        print('📖 [LESSON] Camera started in ${cameraDuration.inMilliseconds}ms');
        
        // Subscribe to prediction stream
        if (mounted) {
          _subscribeToRecognitionStream();
        }
        
        final totalDuration = DateTime.now().difference(initStart);
        print('📖 [LESSON] ✅ TOTAL INITIALIZATION TIME: ${totalDuration.inMilliseconds}ms');
      }
    } catch (e) {
      print('❌ Error initializing recognition service: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  void _subscribeToRecognitionStream() {
    _recognitionService.predictions.listen(
      (result) {
        if (!mounted) return;

        setState(() {
          prediction = result.prediction;
          _landmarks = result.landmarks;
          isStable = result.isStable;
        });

        // Check if current sign is correctly detected
        if (isStable && prediction.isNotEmpty && signs.isNotEmpty) {
          final currentSign = signs[currentIndex];
          final detectedLabel = prediction[0];

          if (detectedLabel == currentSign.targetLabel) {
            _correctSignHoldStart ??= DateTime.now();

            if (DateTime.now().difference(_correctSignHoldStart!) >=
                _correctSignHoldDuration) {
              onSignDetectedCorrectly();
            }
          } else {
            _correctSignHoldStart = null;
          }
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
        if (mounted) {
          setState(() => _errorMessage = 'Recognition error: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    // Only stop camera, don't dispose singleton service (may be reused)
    _recognitionService.stopCameraOnly();
    _scrollController.dispose();
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
    // Show feedback indicator regardless of completion status
    setState(() {
      hasDetectedCorrectSign = true;
    });
    
    // Auto-scroll to bottom to show the next button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });

    if (!signs[currentIndex].isCompleted) {
      // Mark as completed locally
      setState(() {
        signs[currentIndex].isCompleted = true;
      });
      
      // Save progress to database
      try {
        final currentSign = signs[currentIndex];
        await dbHelper.updateSignProgress(currentSign.id);
        print('✅ Progress saved: Sign ${currentSign.name} (ID: ${currentSign.id}) marked as completed');
        
        // Check if lesson is now fully completed
        int completedCount = signs.where((s) => s.isCompleted).length;
        int totalCount = signs.length;
        
        if (completedCount == totalCount && totalCount > 0) {
          print('🎉 LESSON FULLY COMPLETED! ($completedCount/$totalCount signs done)');
          // Mark lesson as completed in database
          await dbHelper.updateLessonProgress(widget.lessonId);
          // Claim lesson points (50 points)
          await ProfileService.claimLessonPoints(widget.lessonId);
          print('✨ Claimed 50 points for completing lesson!');

          // Track lesson completion for achievement checks
          await StudyTrackerService.recordLessonCompletion(widget.lessonId);

          // Check achievements
          await AchievementService().checkAllAchievements();
          
          // Record study session
          try {
            final durationSeconds = DateTime.now().difference(_lessonStartTime).inSeconds;
            await StudyTrackerService.recordStudySession(durationSeconds);
            print('⏱️ Study session recorded: ${(durationSeconds / 60).toStringAsFixed(2)} minutes');
          } catch (e) {
            print('⚠️ Error recording study session: $e');
          }
        }
      } catch (e) {
        print('❌ Error saving progress: $e');
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 8,
        child: SingleChildScrollView(
          controller: _scrollController,
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
                    backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.indigo[100],
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
               style: TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: Theme.of(context).colorScheme.onSurface,
               )),
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
          Text(
            "How to sign:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Using our split logic for bullet points
          ...sign.instructions.map((text) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              "• $text",
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.blueGrey,
              ),
            ),
          )),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      color: isDark ? colorScheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0)),
    );
  }
  
  Widget _buildPracticeCard(Sign currentSign) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Practice Time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
                if (_recognitionService.isCameraInitialized && _recognitionService.cameraController != null && _recognitionService.cameraController!.value.isInitialized && _isPageReady)  // ✅ Wait for 0.5s stabilization
                  SizedBox.expand(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _recognitionService.cameraController!.value.previewSize!.height,
                          height: _recognitionService.cameraController!.value.previewSize!.width,
                          child: CameraPreview(_recognitionService.cameraController!),
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
                if (_recognitionService.isCameraInitialized && _recognitionService.cameraController != null && _recognitionService.cameraController!.value.isInitialized && _showLandmark)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LandmarkPainter(
                        hands: _landmarks,
                        previewSize: _recognitionService.cameraController!.value.previewSize!,
                        lensDirection: _recognitionService.cameraController!.description.lensDirection,
                        sensorOrientation: _recognitionService.cameraController!.description.sensorOrientation,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0x3315803D)
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF15803D)
                      : Colors.green[200]!,
                ),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF86EFAC)
                          : Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Your sign matches perfectly",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF86EFAC)
                          : Colors.green[800],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? colorScheme.surface : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: currentIndex > 0
                ? () {
                    setState(() {
                      currentIndex--;
                      hasDetectedCorrectSign = false;
                      prediction = [];
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
                  prediction = [];
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