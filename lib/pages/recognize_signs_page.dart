import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'package:sign_language_recognition_app/services/hand_recognition_service.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'package:sign_language_recognition_app/services/tts_service.dart';
import 'package:sign_language_recognition_app/tflite_model/model_connection.dart';

class RecognizePage extends StatefulWidget {
  const RecognizePage({
    super.key,
  });

  @override
  State<RecognizePage> createState() => _RecognizePageState();
}

class _RecognizePageState extends State<RecognizePage> {
  // Hand recognition service (handles camera, detection, stability)
  final HandRecognitionService _recognitionService = HandRecognitionService();

  // Current prediction & landmarks from service stream
  List<String> prediction = [];
  List<Hand> _landmarks = [];
  bool isStable = false;
  String? _errorMessage;

  // UI mode and state
  Set<int> _selectedMode = {0};
  bool _enableTextToSpeech = SettingsService.cachedTtsEnabled;

  String? _lastRecognizedWord;  // null = no sign being held
  String? _lastSpokenWord = "";

  // Spelling mode state
  final Duration _spellingVoteWindow = const Duration(seconds: 2, milliseconds: 500);
  DateTime? _spellingWindowStart;
  final Map<String, int> _spellingVoteCounts = {};

  // Hand landmark drawing
  bool _showLandmark = SettingsService.cachedShowLandmarks;

  // Spelling mode controller
  TextEditingController _spellingController = TextEditingController();

  // FPS tracking (from stream)
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
    try {
      await Future.wait([
        initializeModelResources(),
        _recognitionService.initialize(),
      ]);

      if (mounted) {
        await _recognitionService.startCamera();
        _subscribeToRecognitionStream();
      }
    } catch (e) {
      print('❌ Error initializing recognize page: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize: $e');
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

        // Handle sign dwelling for single sign mode
        if (isStable && prediction.isNotEmpty && prediction[0] != "Detecting...") {
          final detectedSign = prediction[0];

          // Handle TTS - speak detected sign if enabled and mode-appropriate
          if (_enableTextToSpeech && _lastSpokenWord != detectedSign) {
            if (_selectedMode.contains(0)) {
              // Live Recognition mode - always speak
              if (SettingsService.cachedHaptic) {
                HapticFeedback.mediumImpact();
              }
              TtsService.speakText(detectedSign);
            } else if (_selectedMode.contains(1) && detectedSign.length <= 2) {
              // Spelling mode - only speak single letters
              TtsService.speakText(detectedSign);
            }
            _lastSpokenWord = detectedSign;
          }

          if (_lastRecognizedWord == null) {
            // New sign detected
            _lastRecognizedWord = detectedSign;
          } else if (_lastRecognizedWord == detectedSign) {
            // Same sign stayed stable - potentially add to spelling mode if enabled
            if (_selectedMode.contains(1)) {  // Spelling mode
              _handleSpellingMode(detectedSign);
            }
          } else {
            // Different sign detected
            _lastRecognizedWord = detectedSign;
            if (_selectedMode.contains(1)) {
              _spellingWindowStart = DateTime.now();
            }
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

  void _handleSpellingMode(String detectedSign) {
    _spellingWindowStart ??= DateTime.now();

    if (DateTime.now().difference(_spellingWindowStart!).inMilliseconds < _spellingVoteWindow.inMilliseconds) {
      // Within voting window - collect votes
      _spellingVoteCounts[detectedSign] = (_spellingVoteCounts[detectedSign] ?? 0) + 1;
    } else {
      // Voting window closed - pick winner and reset
      if (_spellingVoteCounts.isNotEmpty) {
        final winner = _spellingVoteCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        addLetter(winner);
        _spellingVoteCounts.clear();
      }
      _spellingWindowStart = null;
    }
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    _spellingController.dispose();
    super.dispose();
  }


  Future<void> _switchCamera() async {
    if (SettingsService.cachedHaptic) {
      HapticFeedback.selectionClick();
    }

    print("@DEBUG: Switch camera button onpressed");

    setState(() {
      _landmarks = []; // Clear landmarks immediately
    });

    try {
      await _recognitionService.switchCamera();
      if (mounted) {
        setState(() {
          // Camera switched successfully, stream will continue
        });
      }
    } catch (e) {
      print("Error switching camera: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to switch camera';
        });
      }
    }
  }

  void addLetter(String letter) {
    _spellingController.text += letter;
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
                        if (_recognitionService.isCameraInitialized && _recognitionService.cameraController != null && _recognitionService.cameraController!.value.isInitialized)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _recognitionService.cameraController!.value.previewSize!.height,
                                height: _recognitionService.cameraController!.value.previewSize!.width,
                                child: CameraPreview(_recognitionService.cameraController!),
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
                          Center(child: CircularProgressIndicator()),

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

                        // FPS Counter
                        // Positioned(
                        //   top: 10,
                        //   right: 10,
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //     decoration: BoxDecoration(
                        //       color: Color.fromRGBO(0, 0, 0, 0.6),
                        //       borderRadius: BorderRadius.circular(4),
                        //     ),
                        //     child: Text(
                        //       'FPS: ${_currentFps.toStringAsFixed(1)}',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 12,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                        // ),

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
                      color: isDark ? colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.05 : 0.12),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (prediction.isNotEmpty)
                          if (prediction[0].length <= 7)
                            Text(
                              prediction[0],
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: isDark ? colorScheme.onSurface : Colors.black,
                              ),
                            )
                          else
                            Text(
                              prediction[0],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? colorScheme.onSurface : Colors.black,
                              ),
                            )
                        else
                          Text(
                            "Detecting...",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? colorScheme.onSurface : Colors.black,
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        if (prediction.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x3315803D) : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Correct",
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF86EFAC) : Colors.green,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "${prediction[1]}% Accurate",
                                style: TextStyle(
                                  color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                                ),
                              )
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
                      color: isDark ? colorScheme.surface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.05 : 0.12),
                          blurRadius: 4,
                        ),
                      ],
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
                                  filled: true,
                                  fillColor: isDark ? colorScheme.surface : Colors.white,
                                  border: InputBorder.none,
                                  hintText: 'Spell something...',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? colorScheme.onSurfaceVariant
                                        : const Color.fromRGBO(0, 0, 0, 0.4)
                                  )
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? colorScheme.onSurface : Colors.black,
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
                                  backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                                  iconColor: isDark ? colorScheme.onSurface : Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.space_bar,
                                        color: isDark ? colorScheme.onSurface : Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Space",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface : Colors.black,
                                        ),
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
                                  backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                                  iconColor: isDark ? colorScheme.onSurface : Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.backspace_outlined,
                                        color: isDark ? colorScheme.onSurface : Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Delete",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface : Colors.black,
                                        ),
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
                                  backgroundColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                                  iconColor: isDark ? colorScheme.onSurface : Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.replay,
                                        color: isDark ? colorScheme.onSurface : Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Clear",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface : Colors.black,
                                        ),
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
                      return isDark
                          ? colorScheme.surfaceContainerHighest
                          : const Color.fromRGBO(236, 236, 240, 1);
                    }),
                    foregroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return isDark ? colorScheme.onSurface : Colors.black;
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
                      color: isDark ? colorScheme.onSurface : Colors.black,
                    ),
                  ),
                  Spacer(),
                  Container(
                    height: 40,
                    width: 45,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? colorScheme.outlineVariant : Colors.black26,
                      ), 
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
                          color: _enableTextToSpeech
                              ? const Color.fromRGBO(99, 102, 241, 1)
                              : (isDark ? colorScheme.onSurfaceVariant : Colors.black54),
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