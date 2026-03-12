import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class HandDetectionService {
  late HandLandmarkerPlugin _plugin;

  void init() {
    _plugin = HandLandmarkerPlugin.create(
      numHands: 2,
      minHandDetectionConfidence: 0.7,
      delegate: HandLandmarkerDelegate.gpu, // Use GPU for performance
    );
  }

  List<Hand> detect(CameraImage image, int sensorOrientation) {
    return _plugin.detect(image, sensorOrientation);
  }

  void dispose() {
    _plugin.dispose();
  }
}
