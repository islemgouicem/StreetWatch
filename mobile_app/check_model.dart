import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final interpreter = await Interpreter.fromFile(File('assets/models/road_damage_mobile.tflite'));
    final inputTensors = interpreter.getInputTensors();
    final outputTensors = interpreter.getOutputTensors();

    print('Input Tensors:');
    for (var tensor in inputTensors) {
      print('Name: ${tensor.name}');
      print('Shape: ${tensor.shape}');
      print('Type: ${tensor.type}');
    }

    print('\nOutput Tensors:');
    for (var tensor in outputTensors) {
      print('Name: ${tensor.name}');
      print('Shape: ${tensor.shape}');
      print('Type: ${tensor.type}');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
