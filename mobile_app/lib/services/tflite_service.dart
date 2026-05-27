import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Recognition {
  final int id;
  final String label;
  final double score;
  final Rect location;

  Recognition(this.id, this.label, this.score, this.location);

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}

class TfliteService {
  Interpreter? _interpreter;

  static const String modelPath = 'assets/models/road_damage_mobile.tflite';
  static const double confidenceThreshold = 0.45;
  static const double nmsThreshold = 0.40;
  static const int numClasses = 5;
  static const int numPredictions = 2100;
  static const int inputSize = 320;
  static const int maxDetections = 10;

  static const List<String> labels = [
    'longitudinal_crack',
    'transverse_crack',
    'alligator_crack',
    'pothole',
    'other_damage',
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  Future<List<Recognition>> runInference(File imageFile) async {
    if (_interpreter == null) {
      await loadModel();
    }
    if (_interpreter == null) {
      throw Exception('Model failed to load');
    }

    // 1. Read and resize image
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: inputSize,
      height: inputSize,
    );

    // 2. Build input: YOLOv8 standard = 0-1 float32 normalized
    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0,
          ];
        }),
      ),
    );

    // 3. Prepare output buffer [1, 9, 2100]
    var output = List.generate(
      1,
      (i) => List.generate(9, (j) => List.filled(numPredictions, 0.0)),
    );

    // 4. Run inference
    _interpreter!.run(input, output);

    // 5. Post-process with sigmoid on class scores
    return _parseOutput(output[0]);
  }

  /// Sigmoid activation function
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  List<Recognition> _parseOutput(List<List<double>> output) {
    List<Recognition> recognitions = [];

    for (int i = 0; i < numPredictions; i++) {
      // Apply sigmoid to class scores (rows 4-8)
      double maxScore = 0.0;
      int classId = -1;

      for (int c = 0; c < numClasses; c++) {
        double rawScore = output[4 + c][i];
        double score = _sigmoid(rawScore);
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore > confidenceThreshold) {
        double cx = output[0][i];
        double cy = output[1][i];
        double w = output[2][i];
        double h = output[3][i];

        // Sanity check: bbox values should be reasonable (within 0-inputSize range)
        if (w <= 0 || h <= 0 || w > inputSize * 2 || h > inputSize * 2)
          continue;
        if (cx < -inputSize || cy < -inputSize) continue;

        // Normalized coordinates (0.0 to 1.0)
        double left = (cx - w / 2) / inputSize;
        double topVal = (cy - h / 2) / inputSize;
        double width = w / inputSize;
        double height = h / inputSize;

        // Clip to valid range
        left = left.clamp(0.0, 1.0);
        topVal = topVal.clamp(0.0, 1.0);
        width = width.clamp(0.0, 1.0 - left);
        height = height.clamp(0.0, 1.0 - topVal);

        if (width < 0.01 || height < 0.01) continue; // skip tiny boxes

        recognitions.add(
          Recognition(
            classId,
            labels[classId],
            maxScore,
            Rect.fromLTWH(left, topVal, width, height),
          ),
        );
      }
    }

    // NMS then limit to top N
    var results = _nms(recognitions);
    if (results.length > maxDetections) {
      results = results.sublist(0, maxDetections);
    }
    return results;
  }

  List<Recognition> _nms(List<Recognition> recognitions) {
    List<Recognition> selected = [];
    recognitions.sort((a, b) => b.score.compareTo(a.score));

    while (recognitions.isNotEmpty) {
      Recognition first = recognitions.removeAt(0);
      selected.add(first);

      recognitions.removeWhere((next) {
        // Only suppress same-class detections
        if (first.id != next.id) return false;
        double intersectionArea = _calculateIntersection(
          first.location,
          next.location,
        );
        double unionArea =
            first.location.width * first.location.height +
            next.location.width * next.location.height -
            intersectionArea;
        if (unionArea <= 0) return true;
        double iou = intersectionArea / unionArea;
        return iou > nmsThreshold;
      });
    }

    return selected;
  }

  double _calculateIntersection(Rect a, Rect b) {
    double left = max(a.left, b.left);
    double top = max(a.top, b.top);
    double right = min(a.right, b.right);
    double bottom = min(a.bottom, b.bottom);

    if (right > left && bottom > top) {
      return (right - left) * (bottom - top);
    }
    return 0.0;
  }

  void close() {
    _interpreter?.close();
  }
}
