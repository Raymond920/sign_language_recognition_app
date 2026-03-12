import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'package:sign_language_recognition_app/model/model_connection.dart';
import 'package:sign_language_recognition_app/painter/landmark_painter.dart';
import 'package:sign_language_recognition_app/services/hand_detection_service.dart';
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
  bool _enableTextToSpeech = false;

  List<String> prediction = [];
  final List<String> _predictionBuffer = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadModel();
    await loadLabels();
    await _initializeCamera();
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
          ResolutionPreset.high,
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
    print("@DEBUG sensorOri=${cameraController!.description.sensorOrientation} lens=${cameraController!.description.lensDirection}");
    if (_isDetecting || !_isCameraInitialized) return;

    _isDetecting = true;
    try {
      final hands = _handDetectionService.detect(
        image,
        cameraController!.description.sensorOrientation,
      );

      if (hands.isNotEmpty) {
        final hand = hands[0];

        // Mirror exact webcam test pipeline: wrist subtract only, then StandardScaler
        final landmarks = hand.landmarks;
        double wristX = landmarks[0].x;
        double wristY = landmarks[0].y;
        double wristZ = landmarks[0].z;

        var inputBuffer = Float32List(63);
        final int sensorOri = cameraController!.description.sensorOrientation;

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

          inputBuffer[i * 3 + 0] = (x    - mean[i * 3 + 0]) / scale[i * 3 + 0];
          inputBuffer[i * 3 + 1] = (y    - mean[i * 3 + 1]) / scale[i * 3 + 1];
          inputBuffer[i * 3 + 2] = (zRel - mean[i * 3 + 2]) / scale[i * 3 + 2];
        }

        final input = inputBuffer.reshape([1, 21, 3, 1]);
        final raw = predict(input);

        // Majority vote over last 7 frames to suppress flickering
        if (raw.isNotEmpty && raw[0].length == 1) {
          _predictionBuffer.add(raw[0]);
          if (_predictionBuffer.length > 7) _predictionBuffer.removeAt(0);
          final counts = <String, int>{};
          for (final p in _predictionBuffer) counts[p] = (counts[p] ?? 0) + 1;
          final stable = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
          prediction = [stable, if (raw.length > 1) raw[1]];
        } else {
          _predictionBuffer.clear();
          prediction = raw;
        }
      }

      if (mounted) setState(() => _landmarks = hands);
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }


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
                        if (_isCameraInitialized && cameraController != null && cameraController!.value.isInitialized)
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
                          if (prediction[0].length == 1)
                            Text(prediction[0], style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold))
                          else 
                            Text(prediction[0], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                        else
                          Text("Start Sign", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                              // TODO: add state managemnt for accuracy getting from model
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
                        TextField(
                          readOnly: true,
                          showCursor: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Spelling: HELLO',
                            hintStyle: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 0.4)
                            )
                          ),
                          style: TextStyle(
                            fontSize: 14
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  print("@DEBUG: Space button onPressed.");
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
                                  print("@DEBUG: Delete button onPressed.");
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
                                  print("@DEBUG: Clear button onPressed.");
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
                          setState(() {
                            _enableTextToSpeech = !_enableTextToSpeech;
                            print(_enableTextToSpeech ? "TTS enabled" : "TTS disabled");
                          });
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