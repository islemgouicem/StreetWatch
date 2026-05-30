import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
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

  // FIXED: your model outputs 8400 predictions
  static const int numPredictions = 2100;

  static const int inputSize = 320;

  static const int maxDetections = 10;

  static const List<String> labels = [
    'longitudinal_crack',
    'transverse_crack',
    'alligator_crack',
    'pothole',
    'other',
  ];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);

      print('Model loaded successfully');

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('Input shape: $inputShape');
      print('Output shape: $outputShape');
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

    // Read image
    final imageBytes = await imageFile.readAsBytes();

    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      return [];
    }

    // PREPROCESS (YOLO LETTERBOX)
    final preprocessResult = _letterbox(originalImage);

    final img.Image processedImage = preprocessResult.image;

    // Build input tensor NHWC float32 [1,320,320,3]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = processedImage.getPixel(x, y);

          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        }),
      ),
    );

    // Output buffer [1, 9, 8400]
    var output = List.generate(
      1,
      (i) => List.generate(9, (j) => List.filled(numPredictions, 0.0)),
    );
    ;

    // Run inference
    _interpreter!.run(input, output);

    // Parse detections
    return _parseOutput(
      output[0],
      originalImage.width,
      originalImage.height,
      preprocessResult.scale,
      preprocessResult.padX,
      preprocessResult.padY,
    );
  }

  // =========================================================
  // LETTERBOX PREPROCESSING
  // =========================================================

  _LetterboxResult _letterbox(img.Image image) {
    final double scale = min(inputSize / image.width, inputSize / image.height);

    final int newWidth = (image.width * scale).round();
    final int newHeight = (image.height * scale).round();

    final resized = img.copyResize(image, width: newWidth, height: newHeight);

    final canvas = img.Image(width: inputSize, height: inputSize);

    // Fill gray 114
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));

    final int padX = ((inputSize - newWidth) / 2).round();
    final int padY = ((inputSize - newHeight) / 2).round();

    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    return _LetterboxResult(canvas, scale, padX, padY);
  }

  // =========================================================
  // OUTPUT PARSING
  // =========================================================

  List<Recognition> _parseOutput(
    List<List<double>> output,
    int originalWidth,
    int originalHeight,
    double scale,
    int padX,
    int padY,
  ) {
    List<Recognition> recognitions = [];

    for (int i = 0; i < numPredictions; i++) {
      double maxScore = 0.0;
      int classId = -1;

      // IMPORTANT:
      // Most YOLOv8 TFLite exports ALREADY APPLY SIGMOID
      // so we DO NOT apply sigmoid again here.
      for (int c = 0; c < numClasses; c++) {
        double score = output[4 + c][i];

        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore < confidenceThreshold) {
        continue;
      }

      double cx = output[0][i];
      double cy = output[1][i];
      double w = output[2][i];
      double h = output[3][i];

      if (w <= 0 || h <= 0) {
        continue;
      }

      // Convert to original image coordinates
      double x1 = (cx - w / 2 - padX) / scale;
      double y1 = (cy - h / 2 - padY) / scale;
      double x2 = (cx + w / 2 - padX) / scale;
      double y2 = (cy + h / 2 - padY) / scale;

      // Clamp
      x1 = x1.clamp(0.0, originalWidth.toDouble());
      y1 = y1.clamp(0.0, originalHeight.toDouble());

      x2 = x2.clamp(0.0, originalWidth.toDouble());
      y2 = y2.clamp(0.0, originalHeight.toDouble());

      final rect = Rect.fromLTRB(x1, y1, x2, y2);

      recognitions.add(Recognition(classId, labels[classId], maxScore, rect));
    }

    // Apply NMS
    List<Recognition> results = _nms(recognitions);

    // Keep top detections
    if (results.length > maxDetections) {
      results = results.sublist(0, maxDetections);
    }

    return results;
  }

  // =========================================================
  // NMS
  // =========================================================

  List<Recognition> _nms(List<Recognition> recognitions) {
    List<Recognition> selected = [];

    recognitions.sort((a, b) => b.score.compareTo(a.score));

    while (recognitions.isNotEmpty) {
      final first = recognitions.removeAt(0);

      selected.add(first);

      recognitions.removeWhere((next) {
        // suppress only same class
        if (first.id != next.id) {
          return false;
        }

        final intersection = _calculateIntersection(
          first.location,
          next.location,
        );

        final union =
            first.location.width * first.location.height +
            next.location.width * next.location.height -
            intersection;

        if (union <= 0) {
          return true;
        }

        final iou = intersection / union;

        return iou > nmsThreshold;
      });
    }

    return selected;
  }

  double _calculateIntersection(Rect a, Rect b) {
    final left = max(a.left, b.left);
    final top = max(a.top, b.top);
    final right = min(a.right, b.right);
    final bottom = min(a.bottom, b.bottom);

    if (right > left && bottom > top) {
      return (right - left) * (bottom - top);
    }

    return 0.0;
  }

  void close() {
    _interpreter?.close();
  }
}

class _LetterboxResult {
  final img.Image image;
  final double scale;
  final int padX;
  final int padY;

  _LetterboxResult(this.image, this.scale, this.padX, this.padY);
}
