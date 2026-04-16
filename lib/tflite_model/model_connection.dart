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

// value with I,ME
// List<double> mean = [(0.0), (0.0), (0.0), (0.0), (-0.036226725970119666), (-0.03054184509354754), (0.0), (-0.07953062468243255), (-0.048162746959364566), (0.0), (-0.10995329037754342), (-0.06499489216659325), (0.0), (-0.12841098974406082), (-0.07913331709179497), (0.0), (-0.1269146487914309), (-0.024248536606902966), (0.0), (-0.16212847479519737), (-0.05288866464927425), (0.0), (-0.16649374563327898), (-0.0717590999912246), (0.0), (-0.16824736457210046), (-0.0824816261744684), (0.0), (-0.11913286490099326), (-0.02787224312438235), (0.0), (-0.15187933603532547), (-0.060332829183314285), (0.0), (-0.14781807484351717), (-0.07676114163185586), (0.0), (-0.14701928979378945), (-0.083236649914742), (0.0), (-0.102805581339246), (-0.03652765515068552), (0.0), (-0.12752538584874523), (-0.07255963601908909), (0.0), (-0.11389808499082317), (-0.08113592836912659), (0.0), (-0.10641839685695208), (-0.0793905207755458), (0.0), (-0.08182550387682434), (-0.04785042325829436), (0.0), (-0.10185647892613005), (-0.07431135551036147), (0.0), (-0.09853069426226839), (-0.07859914453387284), (0.0), (-0.09769244826486924), (-0.07729954870204743)];
// List<double> scale = [(1.0), (1.0), (1.0), (0.06285888680622805), (0.0752890329795421), (0.039941011909162695), (0.11276206933435368), (0.1421124256266607), (0.05612003770599626), (0.1472958117045695), (0.1916649407448621), (0.06583801075737523), (0.1733521108364655), (0.22761314067835925), (0.07568658468882457), (0.13689638746752347), (0.18274005494428136), (0.06659064206636504), (0.18420832180881294), (0.2503232192569496), (0.08514072869799706), (0.20020740234408563), (0.2759159532091045), (0.09321305142985346), (0.2144817042286547), (0.2990795828221743), (0.09719956707324329), (0.12714364052287488), (0.17256437661242274), (0.05901147982810283), (0.17703338543988492), (0.24359659975920722), (0.0790379683883802), (0.18521264424413397), (0.25943279402434916), (0.07987659589452081), (0.19658613911593076), (0.27978609620579253), (0.07868925829171199), (0.11945717801619099), (0.16092866450634916), (0.054377129985401285), (0.16172322330085218), (0.22045736738970048), (0.06967446508401597), (0.15303292259869136), (0.2108302636540864), (0.06331549347780033), (0.15108918624596443), (0.2106604642779692), (0.05781431421012836), (0.11704493297331232), (0.15263904000997447), (0.05490271011187762), (0.14931473770943052), (0.19836926025138552), (0.06381584908899655), (0.15005272626951383), (0.20153370813866658), (0.060840392319260105), (0.15381667515440303), (0.20874920120304033), (0.05859973020144763)];

List<double> mean = [(0.0), (0.0), (0.0), (0.0), (-0.03575715981900294), (-0.03231311409033052), (0.0), (-0.07907246183891302), (-0.05066958475570774), (0.0), (-0.11000182589617558), (-0.06804548497141988), (0.0), (-0.12871090489987488), (-0.08257335288948839), (0.0), (-0.13070989441812084), (-0.024965945766403083), (0.0), (-0.16747420566243426), (-0.05419339574848055), (0.0), (-0.17331463571247083), (-0.07383987960890134), (0.0), (-0.1767311381309896), (-0.08524502386450777), (0.0), (-0.12380373658962078), (-0.027745815419459894), (0.0), (-0.15803823027990127), (-0.060333212820541306), (0.0), (-0.15504181694483446), (-0.07724491499302684), (0.0), (-0.15576088541169483), (-0.0842320476892688), (0.0), (-0.10758780070899111), (-0.035677862401041344), (0.0), (-0.13263448630094607), (-0.0716126355157602), (0.0), (-0.11790065972438127), (-0.0796584518719446), (0.0), (-0.11026289730356392), (-0.07757163931454522), (0.0), (-0.08617060176739287), (-0.0465319811174327), (0.0), (-0.10536378535104768), (-0.07282189045303103), (0.0), (-0.10012519924559897), (-0.07637231079887571), (0.0), (-0.098006196226319), (-0.07437391414776134)];
List<double> scale = [(1.0), (1.0), (1.0), (0.06410602744212598), (0.07583381528535618), (0.04052121379177886), (0.11479177283098176), (0.1434080770108248), (0.056703320025405214), (0.14989245383081493), (0.19378324856003165), (0.06619170248815416), (0.17709981142240522), (0.23076742481070717), (0.07592527793963647), (0.14047416233122786), (0.18811702294965585), (0.06646888858813477), (0.18916214224964942), (0.2575908769832061), (0.08459058539667311), (0.2066388674340181), (0.28524983425709177), (0.09248647422025236), (0.2225666516187042), (0.31065628847217747), (0.0964789886609985), (0.1315600344274696), (0.17930374032837987), (0.05817822329642454), (0.18193605934757537), (0.25134154806207193), (0.07783347694284742), (0.19132351226059624), (0.2693665717094749), (0.07888827084301017), (0.20426084502492392), (0.29205236946566515), (0.07799310536801084), (0.12410337375775568), (0.16753147882331995), (0.05368470249147825), (0.16623427354566717), (0.22615401577329647), (0.06959045574638728), (0.15585965307258015), (0.21396295708716137), (0.063511005347228), (0.15304117948769444), (0.2125883961977695), (0.0580421702149375), (0.12098116372241632), (0.15760635089433375), (0.05505492299612749), (0.15319125145381413), (0.20176229667750623), (0.06470477476668957), (0.15233703481385116), (0.2019271859739453), (0.061788769684162546), (0.15439460465207067), (0.2066515029096684), (0.05932757694736309)];

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

  // 1. Reshape to exactly [1, 21, 3, 1] using the built-in method
  // This ensures the byte buffer is exactly what the TFLite CNN expects
  // final input = inputBuffer.reshape([1, 21, 3, 1]);

  // 2. Prepare output buffer
  // TODO: Add the number after training with new gestures such that 26 letters + 11 numbers + 6 words
  var output = List<double>.filled(43, 0).reshape([1, 43]);

  // 3. Run Model
  _interpreter.run(input, output);

  // 4. Find the index with the highest probability
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

  print("@DEBUG predict(): maxIndex=$maxIndex, maxProb=$maxProb, _labels.length=${_labels.length}");

  // 5. Get the Letter from your labels list
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