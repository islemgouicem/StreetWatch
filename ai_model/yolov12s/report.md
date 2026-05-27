# StreetWatch — TFLite Inference Benchmark Report

## Overview

This report summarizes the empirical evaluation of the StreetWatch on-device road damage detection pipeline using the exported TensorFlow Lite model:

- Model: YOLOv12s
- Dataset: RDD2022
- Deployment Format: TensorFlow Lite (Float32)
- Input Resolution: 320×320
- Runtime Backend: TensorFlow Lite + XNNPACK CPU delegate
- Platform: Windows 11 CPU environment
- Device CPU: Intel Core i5-1135G7

The objective of this benchmark was to evaluate:
- inference latency,
- throughput (FPS),
- detection quality,
- and end-to-end mobile deployment feasibility.

---

# Model Configuration

| Property | Value |
|---|---|
| Architecture | YOLOv12s |
| Detection Type | Single-stage anchor-free detector |
| Input Tensor | `[1, 320, 320, 3]` |
| Output Tensor | `[1, 9, 2100]` |
| Number of Classes | 5 |
| Classes | longitudinal_crack, transverse_crack, alligator_crack, pothole, repair |
| Runtime | TensorFlow Lite |
| Delegate | XNNPACK CPU delegate |

---

# Tensor Shapes

## Input Tensor

```text
[1, 320, 320, 3]