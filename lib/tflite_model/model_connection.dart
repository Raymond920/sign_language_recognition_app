import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/services.dart' show rootBundle;
import 'package:hand_landmarker/hand_landmarker.dart';

/// Extension to reshape Float32List into nested list structure for TFLite input
extension Float32ListReshape on Float32List {
  List<dynamic> reshape(List<int> shape) {
    if (shape.length == 4 && shape[0] == 1 && shape[1] == 21 && shape[2] == 3 && shape[3] == 1) {
      // Reshape [63] to [1, 21, 3, 1]
      List<dynamic> result = [];
      List<dynamic> batch = [];
      for (int i = 0; i < 21; i++) {
        List<dynamic> point = [];
        for (int j = 0; j < 3; j++) {
          List<double> coord = [this[i * 3 + j]];
          point.add(coord);
        }
        batch.add(point);
      }
      result.add(batch);
      return result;
    }
    // Fallback: return as-is
    return toList();
  }
}

/// Extension to reshape List into nested list structure for TFLite output
extension ListReshape on List<double> {
  List<dynamic> reshape(List<int> shape) {
    if (shape.length == 2 && shape[0] == 1 && shape[1] == 43) {
      // Reshape [43] to [1, 43]
      return [this];
    }
    // Fallback: return as-is
    return [this];
  }
}

// tflite model
late tfl.Interpreter _interpreter;
List<String> _labels = [];
bool _isModelLoaded = false;
bool _areLabelsLoaded = false;
Future<void>? _initFuture;

List<double> mean = [(0.0), (0.0), (0.0), (0.0), (-0.03575715981900294), (-0.03231311409033052), (0.0), (-0.07907246183891302), (-0.05066958475570774), (0.0), (-0.11000182589617558), (-0.06804548497141988), (0.0), (-0.12871090489987488), (-0.08257335288948839), (0.0), (-0.13070989441812084), (-0.024965945766403083), (0.0), (-0.16747420566243426), (-0.05419339574848055), (0.0), (-0.17331463571247083), (-0.07383987960890134), (0.0), (-0.1767311381309896), (-0.08524502386450777), (0.0), (-0.12380373658962078), (-0.027745815419459894), (0.0), (-0.15803823027990127), (-0.060333212820541306), (0.0), (-0.15504181694483446), (-0.07724491499302684), (0.0), (-0.15576088541169483), (-0.0842320476892688), (0.0), (-0.10758780070899111), (-0.035677862401041344), (0.0), (-0.13263448630094607), (-0.0716126355157602), (0.0), (-0.11790065972438127), (-0.0796584518719446), (0.0), (-0.11026289730356392), (-0.07757163931454522), (0.0), (-0.08617060176739287), (-0.0465319811174327), (0.0), (-0.10536378535104768), (-0.07282189045303103), (0.0), (-0.10012519924559897), (-0.07637231079887571), (0.0), (-0.098006196226319), (-0.07437391414776134)];
List<double> scale = [(1.0), (1.0), (1.0), (0.06410602744212598), (0.07583381528535618), (0.04052121379177886), (0.11479177283098176), (0.1434080770108248), (0.056703320025405214), (0.14989245383081493), (0.19378324856003165), (0.06619170248815416), (0.17709981142240522), (0.23076742481070717), (0.07592527793963647), (0.14047416233122786), (0.18811702294965585), (0.06646888858813477), (0.18916214224964942), (0.2575908769832061), (0.08459058539667311), (0.2066388674340181), (0.28524983425709177), (0.09248647422025236), (0.2225666516187042), (0.31065628847217747), (0.0964789886609985), (0.1315600344274696), (0.17930374032837987), (0.05817822329642454), (0.18193605934757537), (0.25134154806207193), (0.07783347694284742), (0.19132351226059624), (0.2693665717094749), (0.07888827084301017), (0.20426084502492392), (0.29205236946566515), (0.07799310536801084), (0.12410337375775568), (0.16753147882331995), (0.05368470249147825), (0.16623427354566717), (0.22615401577329647), (0.06959045574638728), (0.15585965307258015), (0.21396295708716137), (0.063511005347228), (0.15304117948769444), (0.2125883961977695), (0.0580421702149375), (0.12098116372241632), (0.15760635089433375), (0.05505492299612749), (0.15319125145381413), (0.20176229667750623), (0.06470477476668957), (0.15233703481385116), (0.2019271859739453), (0.061788769684162546), (0.15439460465207067), (0.2066515029096684), (0.05932757694736309)];

// List<double> mean = [(0.0), (0.0), (0.0), (0.0), (-0.03568586167585645), (-0.03246848242499156), (0.0), (-0.07894571163304505), (-0.05088302081470145), (0.0), (-0.10987034714690692), (-0.0682805685909131), (0.0), (-0.128600666384864), (-0.0828334495500633), (0.0), (-0.13057942944272932), (-0.02515450757174571), (0.0), (-0.16732457161036304), (-0.05442538063600843), (0.0), (-0.17318339272381605), (-0.0741226628661568), (0.0), (-0.17659568565668132), (-0.08556890664328687), (0.0), (-0.12370412916735354), (-0.027866473294221886), (0.0), (-0.15791987396027488), (-0.06047680166350582), (0.0), (-0.15496981497826587), (-0.0774357549900445), (0.0), (-0.15570661331711874), (-0.08447375252976408), (0.0), (-0.10751249785956683), (-0.03573764826266312), (0.0), (-0.13255507626252924), (-0.0717070878623906), (0.0), (-0.11785880910117223), (-0.07981597789896437), (0.0), (-0.11022520345246231), (-0.07777761173246235), (0.0), (-0.086117211869241), (-0.04654105801437689), (0.0), (-0.10532910651322273), (-0.07286934646838311), (0.0), (-0.10014287231309857), (-0.07646055980677932), (0.0), (-0.09804873769699184), (-0.07449414351563646)];
// List<double> scale = [(1.0), (1.0), (1.0), (0.06403447342192428), (0.07571725948364844), (0.040516042812352236), (0.11465639818958943), (0.14316509533277194), (0.056725595301352745), (0.14970105756306898), (0.19348155243655885), (0.0662639438736271), (0.17687624356215798), (0.2304402392256036), (0.07606408555379965), (0.14044283490292014), (0.18786623236609667), (0.06643555724133332), (0.18915338746060403), (0.257292914687648), (0.08453988251516942), (0.20669749899640424), (0.2849716508045318), (0.09243484767100996), (0.22267100572723209), (0.3103871696004475), (0.0964324498447526), (0.1315455624625152), (0.17909393220043104), (0.05815073417204184), (0.18190252326337397), (0.25106487451727233), (0.07777993932879239), (0.1914866519081012), (0.2691637923964047), (0.07885586991644018), (0.20459373263996952), (0.29190842478496354), (0.07798769939421935), (0.12410439924745963), (0.16736888376807776), (0.053647721794188925), (0.16617657739570044), (0.22596822996400226), (0.06954353457241447), (0.15581592518754595), (0.21383605127993865), (0.06353192935440753), (0.1530143900463763), (0.21248589536620868), (0.05811802583853205), (0.12098400507879836), (0.15747068067337688), (0.054995496710053514), (0.15316899547107624), (0.20163801568111803), (0.06464657386553319), (0.15226995945388636), (0.201825867164781), (0.06177011410058834), (0.1542739755583523), (0.20653844963369186), (0.05934497527696569)];


Future<void> initializeModelResources() {
  _initFuture ??= _initializeModelResourcesInternal();
  return _initFuture!;
}

Future<void> _initializeModelResourcesInternal() async {
  await loadModel();
  await loadLabels();
}

Future<void> loadModel() async {
  if (_isModelLoaded) return;
  try {
    _interpreter = await tfl.Interpreter.fromAsset('assets/model/msl_model_CNN.tflite');
    _isModelLoaded = true;
    print("Model loaded successfully");
  } catch (e) {
    print("Failed to load model: $e");
    rethrow;
  }
}

Future<void> loadLabels() async {
  if (_areLabelsLoaded) return;
  final String content = await rootBundle.loadString('assets/model/labels.txt');
  
  // Split by newline and remove any empty lines/extra spaces
  _labels = content
      .split('\n')
      .map((label) => label.trim())
      .where((label) => label.isNotEmpty)
      .toList();
  _areLabelsLoaded = true;
      
  print("Loaded ${_labels.length} labels: $_labels");
  
  // Verify we have the correct number of labels
  if (_labels.length != 43) {
    print("⚠️ WARNING: Expected 43 labels but got ${_labels.length}! Check your labels.txt file.");
  }
}

List<double> normalizeLandmarks(List<Landmark> landmarks) {
  // Wrist landmark (index 0)
  double wristX = landmarks[0].x;
  double wristY = landmarks[0].y;
  double wristZ = landmarks[0].z;

  List<double> normalized = [];

  for (var lm in landmarks) {
    double x = lm.x - wristX;
    double y = lm.y - wristY;
    double z = lm.z - wristZ;

    normalized.add(x);
    normalized.add(y);
    normalized.add(z);
  }

  return normalized; // 63 values
}

List<String> predict(input) {
  if (!_isModelLoaded || !_areLabelsLoaded) {
    return ["Detecting..."];
  }

  // Prepare output buffer
  var output = List<double>.filled(43, 0).reshape([1, 43]);

  // Run Model
  _interpreter.run(input, output);

  // Find the index with the highest probability
  List<double> probabilities = output[0];
  double maxProb = -1.0;
  int maxIndex = -1;
  String predictedLetter = "";
  double confidence = 0;

  for (int i = 0; i < probabilities.length; i++) {
    if (probabilities[i] > maxProb) {
      maxProb = probabilities[i];
      maxIndex = i;
    }
  }

  // Get the Letter from labels list
  if (maxIndex != -1 && maxIndex < _labels.length) {
    predictedLetter = _labels[maxIndex];
    confidence = maxProb * 100;
    
    print("PREDICTED SIGN: $predictedLetter (${confidence.toStringAsFixed(2)}%)");
  } else {
    print("@DEBUG: Failed bounds check! maxIndex=$maxIndex >= _labels.length=${_labels.length}");
  }

  if (confidence < 70) {
    return ["Detecting..."];
  }
  else {
    return [predictedLetter, confidence.toStringAsFixed(2)];
  }
}