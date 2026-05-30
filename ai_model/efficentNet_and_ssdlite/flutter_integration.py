"""
StreetWatch — Flutter Integration Guide
========================================
This file documents how to use the exported TFLite model in your Flutter app.
Copy the Dart code into your project as needed.

Files needed in Flutter assets/:
  - streetwatch_int8.tflite
  - anchors.json

pubspec.yaml dependencies:
  tflite_flutter: ^0.10.4
  image: ^4.1.3
"""

# ══════════════════════════════════════════════════════
#  pubspec.yaml additions
# ══════════════════════════════════════════════════════
PUBSPEC_ADDITIONS = """
dependencies:
  tflite_flutter: ^0.10.4
  image: ^4.1.3

flutter:
  assets:
    - assets/streetwatch_int8.tflite
    - assets/anchors.json
"""

# ══════════════════════════════════════════════════════
#  Dart: StreetWatchDetector class
# ══════════════════════════════════════════════════════
DART_CODE = '''
// lib/ai/streetwatch_detector.dart
// -----------------------------------
// StreetWatch TFLite inference for Flutter
// Mirrors the Python TFLitePredictor exactly.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ─── Constants ───────────────────────────────────────────────────

const int   kImageSize       = 320;
const double kConfThreshold  = 0.45;
const double kNmsThreshold   = 0.45;
const int    kMaxDetections  = 20;

const List<String> kDamageClasses = [
  'longitudinal_crack',
  'transverse_crack',
  'alligator_crack',
  'pothole',
];

const List<String> kSeverityClasses = ['low', 'medium', 'high'];

// ─── Detection result ─────────────────────────────────────────────

class Detection {
  final List<double> bbox;      // [x, y, w, h] normalised 0-1
  final String       damageType;
  final String       severity;
  final double       confidence;

  const Detection({
    required this.bbox,
    required this.damageType,
    required this.severity,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'bbox':       bbox,
    'class':      damageType,
    'severity':   severity,
    'confidence': confidence,
  };

  @override
  String toString() =>
    'Detection($damageType | $severity | conf=${confidence.toStringAsFixed(2)} | bbox=$bbox)';
}

// ─── Detector ────────────────────────────────────────────────────

class StreetWatchDetector {
  Interpreter? _interpreter;
  List<List<double>>? _anchors;
  bool _initialized = false;

  // ── Initialise ────────────────────────────────────────────────

  Future<void> init() async {
    // Load TFLite model with GPU delegate
    final options = InterpreterOptions()
      ..addDelegate(GpuDelegateV2());   // Android GPU
      // For iOS, use: ..addDelegate(CoreMlDelegate())

    _interpreter = await Interpreter.fromAsset(
      'assets/streetwatch_int8.tflite',
      options: options,
    );

    // Load pre-generated anchor boxes
    final anchorJson = await rootBundle.loadString('assets/anchors.json');
    final anchorData = json.decode(anchorJson);
    _anchors = (anchorData['anchors'] as List)
        .map((a) => (a as List).map((v) => (v as num).toDouble()).toList())
        .toList();

    _initialized = true;
    debugPrint('[StreetWatch] Initialized. Anchors: \${_anchors!.length}');
  }

  void dispose() {
    _interpreter?.close();
    _initialized = false;
  }

  // ── Preprocess ────────────────────────────────────────────────

  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width:  kImageSize,
      height: kImageSize,
      interpolation: img.Interpolation.linear,
    );

    final buffer = Float32List(1 * kImageSize * kImageSize * 3);
    int idx = 0;
    for (int y = 0; y < kImageSize; y++) {
      for (int x = 0; x < kImageSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[idx++] = pixel.r / 255.0;
        buffer[idx++] = pixel.g / 255.0;
        buffer[idx++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  // ── Softmax ───────────────────────────────────────────────────

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps   = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum    = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  // ── Decode box offsets → absolute cx/cy/w/h ──────────────────

  List<double> _decodeBox(List<double> pred, List<double> anchor) {
    const varXY = 0.1;
    const varWH = 0.2;
    final cx = pred[0] * varXY * anchor[2] + anchor[0];
    final cy = pred[1] * varXY * anchor[3] + anchor[1];
    final w  = math.exp(pred[2] * varWH) * anchor[2];
    final h  = math.exp(pred[3] * varWH) * anchor[3];
    return [cx, cy, w, h];
  }

  // ── NMS ──────────────────────────────────────────────────────

  double _iou(List<double> a, List<double> b) {
    // a, b in cx/cy/w/h
    final ax1 = a[0] - a[2] / 2, ay1 = a[1] - a[3] / 2;
    final ax2 = a[0] + a[2] / 2, ay2 = a[1] + a[3] / 2;
    final bx1 = b[0] - b[2] / 2, by1 = b[1] - b[3] / 2;
    final bx2 = b[0] + b[2] / 2, by2 = b[1] + b[3] / 2;

    final ix1   = math.max(ax1, bx1);
    final iy1   = math.max(ay1, by1);
    final ix2   = math.min(ax2, bx2);
    final iy2   = math.min(ay2, by2);
    final inter = math.max(0, ix2 - ix1) * math.max(0, iy2 - iy1);
    final union = a[2] * a[3] + b[2] * b[3] - inter;
    return inter / (union + 1e-6);
  }

  List<int> _nms(List<List<double>> boxes, List<double> scores) {
    final order = List.generate(scores.length, (i) => i)
        ..sort((a, b) => scores[b].compareTo(scores[a]));

    final keep    = <int>[];
    final removed = <bool>[...List.filled(scores.length, false)];

    for (final i in order) {
      if (removed[i]) continue;
      keep.add(i);
      for (final j in order) {
        if (j == i || removed[j]) continue;
        if (_iou(boxes[i], boxes[j]) > kNmsThreshold) {
          removed[j] = true;
        }
      }
    }
    return keep;
  }

  // ── Main Inference ────────────────────────────────────────────

  Future<List<Detection>> detect(img.Image image) async {
    assert(_initialized, 'Call init() before detect()');

    // 1. Preprocess
    final inputData = _preprocessImage(image);
    final input     = inputData.reshape([1, kImageSize, kImageSize, 3]);

    // 2. Allocate outputs
    //    Output shapes must match the TFLite model:
    //      [0] pred_boxes   : [1, N, 4]
    //      [1] pred_classes : [1, N, NUM_CLASSES+1]
    //      [2] pred_severity: [1, N, 3]
    final outputShapes = _interpreter!.getOutputTensors()
        .map((t) => t.shape)
        .toList();
    final outputs = outputShapes.map((shape) {
      final size = shape.reduce((a, b) => a * b);
      return Float32List(size).reshape(shape);
    }).toList();

    // 3. Run inference
    final stopwatch = Stopwatch()..start();
    _interpreter!.runForMultipleInputs([input], {
      0: outputs[0],   // boxes
      1: outputs[1],   // class logits
      2: outputs[2],   // severity logits
    });
    final inferenceMs = stopwatch.elapsedMilliseconds;
    debugPrint('[StreetWatch] Inference: \${inferenceMs}ms');

    // 4. Post-process
    final nAnchors   = _anchors!.length;
    final boxPreds   = outputs[0][0]  as List;  // [N, 4]
    final clsLogits  = outputs[1][0]  as List;  // [N, C+1]
    final sevLogits  = outputs[2][0]  as List;  // [N, 3]

    final candidateBoxes  = <List<double>>[];
    final candidateScores = <double>[];
    final candidateCls    = <int>[];
    final candidateSev    = <int>[];

    for (int i = 0; i < nAnchors; i++) {
      // Class probabilities (skip background class 0)
      final rawCls   = List<double>.from(clsLogits[i] as List);
      final clsProbs = _softmax(rawCls).sublist(1);   // skip bg
      final clsScore = clsProbs.reduce(math.max);
      final clsIdx   = clsProbs.indexOf(clsScore);

      if (clsScore < kConfThreshold) continue;

      // Decode box
      final anchor  = _anchors![i];
      final rawBox  = List<double>.from(boxPreds[i] as List);
      final decoded = _decodeBox(rawBox, anchor);

      // Severity
      final rawSev  = List<double>.from(sevLogits[i] as List);
      final sevProbs = _softmax(rawSev);
      final sevIdx   = sevProbs.indexOf(sevProbs.reduce(math.max));

      candidateBoxes.add(decoded);
      candidateScores.add(clsScore);
      candidateCls.add(clsIdx);
      candidateSev.add(sevIdx);
    }

    if (candidateBoxes.isEmpty) return [];

    // Per-class NMS
    final allKeep = <int>{};
    for (int c = 0; c < kDamageClasses.length; c++) {
      final clsIndices = [
        for (int i = 0; i < candidateCls.length; i++)
          if (candidateCls[i] == c) i
      ];
      if (clsIndices.isEmpty) continue;

      final clsBoxes  = clsIndices.map((i) => candidateBoxes[i]).toList();
      final clsScores = clsIndices.map((i) => candidateScores[i]).toList();

      final kept = _nms(clsBoxes, clsScores);
      for (final k in kept) allKeep.add(clsIndices[k]);
    }

    // Sort by score, cap at kMaxDetections
    final sortedKeep = allKeep.toList()
        ..sort((a, b) => candidateScores[b].compareTo(candidateScores[a]));
    final finalKeep = sortedKeep.take(kMaxDetections);

    return finalKeep.map((i) {
      final box = candidateBoxes[i];
      final x   = math.max(0.0, box[0] - box[2] / 2);
      final y   = math.max(0.0, box[1] - box[3] / 2);
      return Detection(
        bbox:       [double.parse(x.toStringAsFixed(4)),
                     double.parse(y.toStringAsFixed(4)),
                     double.parse(box[2].toStringAsFixed(4)),
                     double.parse(box[3].toStringAsFixed(4))],
        damageType: kDamageClasses[candidateCls[i]],
        severity:   kSeverityClasses[candidateSev[i]],
        confidence: double.parse(candidateScores[i].toStringAsFixed(4)),
      );
    }).toList();
  }
}
'''

# ══════════════════════════════════════════════════════
#  Dart: Usage in camera screen
# ══════════════════════════════════════════════════════
CAMERA_USAGE_DART = '''
// lib/screens/camera_screen.dart  (relevant snippet)
// ---------------------------------------------------

final _detector = StreetWatchDetector();

@override
void initState() {
  super.initState();
  _detector.init();
}

@override
void dispose() {
  _detector.dispose();
  super.dispose();
}

Future<void> _analyzeImage(XFile imageFile) async {
  final bytes    = await imageFile.readAsBytes();
  final image    = img.decodeImage(bytes)!;

  setState(() => _isAnalyzing = true);

  final detections = await _detector.detect(image);

  setState(() {
    _detections  = detections;
    _isAnalyzing = false;
  });

  if (detections.isNotEmpty) {
    // Send to backend (async, non-blocking)
    _sendToBackend(detections, imageFile);
  }
}

Future<void> _sendToBackend(
  List<Detection> detections,
  XFile imageFile,
) async {
  final payload = {
    'detections': detections.map((d) => d.toJson()).toList(),
    'timestamp':  DateTime.now().toIso8601String(),
    'location':   await _getCurrentLocation(),
  };

  await http.post(
    Uri.parse('https://your-backend/api/reports'),
    headers: {'Content-Type': 'application/json'},
    body:    json.encode(payload),
  );
}
'''

if __name__ == "__main__":
    print("Flutter Integration Guide")
    print("="*50)
    print("\n1. Add to pubspec.yaml:")
    print(PUBSPEC_ADDITIONS)
    print("\n2. Dart detector class:")
    print(DART_CODE[:500] + "\n  ... (see flutter_integration.py for full code)")
