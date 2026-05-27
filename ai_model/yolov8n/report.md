# StreetWatch TFLite Inference Report

## Objective

Evaluate the exported YOLOv8n TensorFlow Lite model for on-device road damage detection.

## Environment

* Model: `road_damage_mobile.tflite`
* Framework: TensorFlow Lite
* Input Size: `320 × 320`
* Input Layout: `NHWC`
* Language: Python 3.11
* Hardware: CPU (XNNPACK delegate enabled)

## Pipeline

The inference engine performs:

1. Image preprocessing

   * Letterbox resize
   * RGB conversion
   * Normalization to `[0,1]`

2. TensorFlow Lite inference

3. YOLOv8 output postprocessing

   * Confidence filtering
   * Non-Maximum Suppression (NMS)
   * Severity estimation

## Performance Results

| Step           | Time     |
| -------------- | -------- |
| Preprocessing  | 3.13 ms  |
| Inference      | 33.72 ms |
| Postprocessing | 22.86 ms |
| Total          | 59.71 ms |

Estimated throughput: approximately `16 FPS`.

## Detection Result

The test produced:

```python
Detections : []
```

This is expected because the benchmark used a randomly generated synthetic image instead of a real road image.

## Severity Estimation

The system estimates damage severity using the ratio:

```text
bounding_box_area / image_area
```

Severity levels:

* `low`
* `medium`
* `high`

## Conclusion

The TensorFlow Lite model loaded and executed successfully without tensor or graph errors. The inference pipeline is operational and suitable for mobile deployment after integration testing with real road images.
