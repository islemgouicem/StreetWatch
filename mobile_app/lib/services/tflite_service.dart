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
  List<String>? _labels;

  static const String modelPath = 'assets/models/road_damage_mobile.tflite';
  
  // RDD2022 classes
  static const List<String> labels = [
    'Longitudinal Crack',
    'Transverse Crack',
    'Alligator Crack',
    'Pothole',
    'Broken Sign'
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('Model loaded successfully');
      
      // Check input/output shapes
      var inputShape = _interpreter!.getInputTensors().first.shape;
      var outputShape = _interpreter!.getOutputTensors().first.shape;
      print('Input shape: $inputShape');
      print('Output shape: $outputShape');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<Recognition>> runInference(File imageFile) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // 1. Pre-process image
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    // Resize to 640x640 (standard YOLOv8)
    img.Image resizedImage = img.copyResize(originalImage, width: 640, height: 640);

    // Convert to Float32 list and normalize
    var input = List.generate(
      1,
      (index) => List.generate(
        640,
        (y) => List.generate(
          640,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // 2. Prepare output buffer
    // For YOLOv8, output is [1, 9, 8400]
    // 9 = [cx, cy, w, h, class0, class1, class2, class3, class4]
    var output = List.filled(1 * 9 * 8400, 0.0).reshape([1, 9, 8400]);

    // 3. Run inference
    _interpreter!.run(input, output);

    // 4. Post-process
    return _parseYoloV8Output(output[0], originalImage.width, originalImage.height);
  }

  List<Recognition> _parseYoloV8Output(List<List<double>> output, int imgWidth, int imgHeight) {
    List<Recognition> recognitions = [];
    
    // output is [9, 8400]
    // We need to transpose it or iterate through columns
    for (int i = 0; i < 8400; i++) {
      // Find class with highest score
      double maxScore = 0.0;
      int classId = -1;
      
      for (int c = 0; c < 5; c++) {
        double score = output[4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore > 0.45) { // Confidence threshold
        double cx = output[0][i];
        double cy = output[1][i];
        double w = output[2][i];
        double h = output[3][i];

        // Convert from normalized to pixel coordinates
        // Assuming model input was 640x640
        double left = (cx - w / 2) * imgWidth / 640;
        double top = (cy - h / 2) * imgHeight / 640;
        double width = w * imgWidth / 640;
        double height = h * imgHeight / 640;

        recognitions.add(Recognition(
          classId,
          labels[classId],
          maxScore,
          Rect.fromLTWH(left, top, width, height),
        ));
      }
    }

    // Apply Non-Maximum Suppression (NMS)
    return _nms(recognitions);
  }

  List<Recognition> _nms(List<Recognition> recognitions) {
    List<Recognition> selected = [];
    recognitions.sort((a, b) => b.score.compareTo(a.score));

    while (recognitions.isNotEmpty) {
      Recognition first = recognitions.removeAt(0);
      selected.add(first);

      recognitions.removeWhere((next) {
        double intersectionArea = _calculateIntersection(first.location, next.location);
        double unionArea = first.location.width * first.location.height +
            next.location.width * next.location.height -
            intersectionArea;
        double iou = intersectionArea / unionArea;
        return iou > 0.45; // NMS threshold
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
