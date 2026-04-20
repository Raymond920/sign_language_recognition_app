import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:sign_language_recognition_app/models/question_model.dart';
import 'package:sign_language_recognition_app/models/quiz_model.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/services/hand_recognition_service.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/study_tracker_service.dart';
import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';
import 'package:sign_language_recognition_app/pages/result_page.dart';

class QuizContentPage extends StatefulWidget {
  final int quizId;
  const QuizContentPage({
    super.key,
    required this.quizId
  });

  @override
  State<QuizContentPage> createState() => _QuizContentPageState();
}

class _QuizContentPageState extends State<QuizContentPage> {
  late Quiz quiz;
  late List<QuizQuestion> questions;
  int currentQuestionIndex = 0;

  final DBHelper dbHelper = DBHelper();
  bool _isLoading = true;
  String? _errorMessage;

  String? selectedAnswer;
  bool _canProceedToNext = false;  // Can proceed if answered via options or detected correct sign
  int _correctScore = 0;
  int _wrongScore = 0;

  // Hand recognition for sign detection
  final HandRecognitionService _recognitionService = HandRecognitionService();
  List<String> prediction = [];
  List<Hand> _landmarks = [];
  bool isStable = false;
  DateTime? _signDetectionStart;
  String? _detectedSign;
  String? _confirmedDetectedSign;  // Only set after 2.5 seconds hold
  static const Duration _signHoldDuration = Duration(seconds: 2, milliseconds: 500);
  bool _showLandmark = SettingsService.cachedShowLandmarks;

  late ScrollController _scrollController;
  bool _isDisposed = false;  // Track if resources have been disposed
  
  // Study session tracking
  late DateTime _quizStartTime;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQuizData();
    });
  }

  Future<void> _loadQuizData() async {
    try {
      // Fetch quiz metadata and question set from database.
      final quizzes = await dbHelper.getAllQuizzes();
      final targetQuiz = quizzes.firstWhere(
        (q) => q.id == widget.quizId,
        orElse: () => quizzes.isNotEmpty
            ? quizzes.first
            : Quiz(
                id: widget.quizId,
                title: 'Quiz Not Found',
                description: 'Could not load quiz from database',
                questionCount: 0,
                bestScore: 0,
                pointsClaimed: false,
              ),
      );

      final loadedQuestions = await dbHelper.getQuestionsForQuiz(targetQuiz.id);

      if (mounted) {
        setState(() {
          quiz = targetQuiz;
          questions = loadedQuestions;
          currentQuestionIndex = 0;
          _isLoading = false;
          _errorMessage = null;
        });
        
        // Initialize hand recognition service
        _initRecognitionService();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading quiz data: $e';
        });
      }
    }
  }

  Future<void> _initRecognitionService() async {
    try {
      await Future.wait([
        initializeModelResources(),
        _recognitionService.initialize(),
      ]);

      if (mounted) {
        // Track quiz start time
        _quizStartTime = DateTime.now();
        await _recognitionService.startCamera();
        _subscribeToRecognitionStream();
      }
    } catch (e) {
      print('❌ Error initializing recognition service: $e');
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

        // Only process sign detection if user hasn't already answered (via options or sign)
        if (_canProceedToNext || selectedAnswer != null) return;

        // Wait for stable sign detection for 2.5 seconds
        if (isStable && prediction.isNotEmpty && prediction[0] != "Detecting...") {
          final currentPrediction = prediction[0];

          if (_detectedSign == null) {
            // New sign detected
            _detectedSign = currentPrediction;
            _signDetectionStart = DateTime.now();
          } else if (_detectedSign == currentPrediction) {
            // Same sign held stable
            if (_signDetectionStart != null &&
                DateTime.now().difference(_signDetectionStart!) >= _signHoldDuration) {
              // Hold duration reached - confirm the sign (correct or incorrect)
              if (_confirmedDetectedSign == null) {
                setState(() {
                  _confirmedDetectedSign = _detectedSign;
                  _canProceedToNext = true;  // Enable next button for ANY sign (correct or incorrect)
                });
              }
            }
          } else {
            // Different sign detected - reset
            _detectedSign = currentPrediction;
            _signDetectionStart = DateTime.now();
            _confirmedDetectedSign = null;
          }
        } else if (!isStable) {
          // Reset when not stable
          _detectedSign = null;
          _signDetectionStart = null;
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
      },
    );
  }

  Future<void> _nextQuestion() async {
    final question = questions[currentQuestionIndex];
    
    // Determine the user's answer (either from options or sign recognition)
    final userAnswer = selectedAnswer ?? _confirmedDetectedSign;
    
    // Check if the answer is correct and update scores
    if (userAnswer != null) {
      if (userAnswer == question.answer) {
        _correctScore++;
      } else {
        _wrongScore++;
      }
    }
    
    // Check if this is the last question BEFORE setState
    final isLastQuestion = currentQuestionIndex >= questions.length - 1;
    
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        selectedAnswer = null;
        _detectedSign = null;
        _confirmedDetectedSign = null;
        _signDetectionStart = null;
        _canProceedToNext = false;  // Reset for next question
      } else {
        // Quiz completed
        _isDisposed = true;  // Mark as disposed to prevent further controller use
        _recognitionService.dispose();  // Stop camera immediately
      }
    });
    
    // Handle quiz completion after setState
    if (isLastQuestion) {
      // Record study session
      try {
        final durationSeconds = DateTime.now().difference(_quizStartTime).inSeconds;
        await StudyTrackerService.recordStudySession(durationSeconds);
        print('⏱️ Study session recorded: ${(durationSeconds / 60).toStringAsFixed(2)} minutes');
      } catch (e) {
        print('⚠️ Error recording quiz study session: $e');
      }
      
      if (mounted) {
        // Navigate after current frame completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultPage(
                  quizId: widget.quizId,
                  quizTitle: quiz.title,
                  correctScore: _correctScore,
                  wrongScore: _wrongScore,
                ),
              ),
            );
          }
        });
      }
    } else if (!_isDisposed) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _showConfirmationDialog(String optionText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Answer'),
          content: Text('Are you sure you want to choose \'$optionText\'?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  @override
  void dispose() {
    try {
      if (!_isDisposed) {
        _isDisposed = true;
        _recognitionService.dispose();
      }
      if (_scrollController.hasClients) {
        _scrollController.dispose();
      }
    } catch (e) {
      print('Error during dispose: $e');
    }
    super.dispose();
  }

  Widget _buildQuestionCard(String title, String imagePath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, style: Theme.of(context).textTheme.titleMedium
          ),
          SizedBox(height: 10),
          Center(
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.asset(
                imagePath
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose the correct answer: ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,

          children: List.generate(question.options.length, (index) {
            final optionText = question.options[index];

            Color borderColor = Colors.grey.shade300;

            if (selectedAnswer != null || _canProceedToNext) {
              if (optionText == question.answer) {
                borderColor = Colors.green;
              } else if (optionText == selectedAnswer) {
                borderColor = Colors.red;
              }
            }

            return InkWell(
              onTap: selectedAnswer != null
              ? null
              : () async {
                final confirmed = await _showConfirmationDialog(optionText);
                if (confirmed) {
                  setState(() {
                    selectedAnswer = optionText;
                    _canProceedToNext = true;  // Can proceed after selecting answer
                  });
                }
              },

              borderRadius: BorderRadius.circular(12),

              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white
                ),
                child: Text(
                  optionText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }),
        )
      ],
    );
  }

  Widget _buildSignRecognition() {
    final question = questions[currentQuestionIndex];
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recognize the Sign",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff3D3D44),
            ),
          ),
          SizedBox(height: 15),
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF121826),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera preview with hand landmarks
                if (_recognitionService.isCameraInitialized &&
                    _recognitionService.cameraController != null &&
                    _recognitionService.cameraController!.value.isInitialized)
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
                else
                  const Center(child: CircularProgressIndicator()),
                
                // Hand landmarks overlay
                if (_recognitionService.isCameraInitialized &&
                    _recognitionService.cameraController != null &&
                    _recognitionService.cameraController!.value.isInitialized &&
                    _showLandmark)
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

                // Recognized sign overlay - only show after 2.5 second hold
                if (_confirmedDetectedSign != null)
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _confirmedDetectedSign == question.answer
                          ? Color.fromRGBO(144, 238, 144, 0.8)
                          : Color.fromRGBO(255, 153, 153, 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _confirmedDetectedSign == question.answer ? "✓ Correct!" : "✗ Incorrect",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _confirmedDetectedSign == question.answer
                                ? Color(0xFF2D5016)
                                : Color(0xFF8B0000),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Recognized: $_confirmedDetectedSign",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _confirmedDetectedSign == question.answer
                                ? Color(0xFF2D5016)
                                : Color(0xFF8B0000),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Top-left: Target label or "Answer Submitted"
                if (_canProceedToNext)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Answer Submitted",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                // Top-right: Stability indicator (only show if still detecting)
                if (!_canProceedToNext)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isStable ? Color(0xFF4CAF50) : Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isStable ? "✓ Ready" : "⧖ Detecting",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                // Bottom: Current detection or hold timer (only show if still detecting)
                if (!_canProceedToNext && _detectedSign != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _signDetectionStart != null
                            ? "Detecting: $_detectedSign, Hold ${(DateTime.now().difference(_signDetectionStart!).inMilliseconds / 1000).toStringAsFixed(1)}s / 2.5s"
                            : "Detecting: $_detectedSign",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Feedback message
          if (_confirmedDetectedSign != null)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _confirmedDetectedSign == question.answer
                        ? "✓ Correct! You can now proceed to the next question."
                        : "✗ Incorrect! You can now proceed to the next question.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _confirmedDetectedSign == question.answer
                          ? Color(0xFF2D5016)
                          : Color(0xFF8B0000),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Quiz...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadQuizData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(quiz.title)),
        body: const Center(child: Text('No questions available for this quiz.')),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () async {
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
            Text(quiz.title, style: const TextStyle(fontSize: 16),),
            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget> [
              SizedBox(height: 12,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / questions.length,
                  backgroundColor: Colors.indigo[100],
                  color: Colors.indigoAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 20),
              // question
              _buildQuestionCard(question.text, question.imagePath),

              SizedBox(height: 20),
              // answer selection
              _buildAnswerOptions(question),

              SizedBox(height: 20),
              // camera section - sign recognition
              _buildSignRecognition(),

              SizedBox(height: 20),
              // submit answer button
              ElevatedButton(
                onPressed: _canProceedToNext
                    ? () {
                        // TODO: Score and save result

                        _nextQuestion();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  currentQuestionIndex == questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next Question',
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt, color: Colors.green,),
                      Text(
                        " Correct: $_correctScore"
                      )
                    ],
                  ),
                  SizedBox(width: 30,),
                  Row(
                    children: [
                      Icon(Icons.highlight_off, color: Colors.red,),
                      Text(
                        " Wrong: $_wrongScore"
                      )
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
            ]
          )
        ),
      ),
    );
  }
}