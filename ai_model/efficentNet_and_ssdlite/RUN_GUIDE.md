# StreetWatch AI Quick Run Guide

This is the shortest end-to-end path to train and export the StreetWatch model.

## 1) Setup

From this folder (`streetwatch_ai/streetwatch_ai`):

```bash
pip install -r requirements.txt
```

## 2) Prepare dataset

Expected structure:

```text
data/rdd2022/
  images/
    train/
    val/
    test/
  annotations/
    instances_train.json
    instances_val.json
    instances_test.json
```

If you only have raw RDD2022 XML annotations:

```bash
python data/prepare_rdd2022.py \
  --image_dir /path/to/rdd2022/images \
  --ann_dir /path/to/rdd2022/annotations \
  --output_dir data/rdd2022
```

## 3) Train (GPU)

```bash
python train.py --epochs 80 --batch_size 16 --lr 0.005
```

Outputs (default):

- Checkpoints in `runs/streetwatch/` (or configured checkpoint directory)
- Best model checkpoint: `best.pt`

To resume:

```bash
python train.py --resume runs/streetwatch/checkpoint_epoch040.pt
```

## 4) Evaluate

```bash
python evaluate.py \
  --checkpoint runs/streetwatch/best.pt \
  --ann_file data/rdd2022/annotations/instances_test.json \
  --img_root data/rdd2022/images/test
```

## 5) Export mobile model (INT8 TFLite)

Make sure you have calibration images in `data/rdd2022/calibration/` (real road images recommended).

```bash
python export/export_pipeline.py \
  --checkpoint runs/streetwatch/best.pt \
  --output_dir export \
  --calibration_data data/rdd2022/calibration
```

Expected export artifacts:

- `export/streetwatch_int8.tflite`  (mobile model)
- `export/anchors.json`             (anchor priors used in post-processing)

## 6) Flutter integration (assets)

Copy exported files into your Flutter app assets folder, for example:

```text
flutter_app/assets/models/streetwatch_int8.tflite
flutter_app/assets/models/anchors.json
```

Add them in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/streetwatch_int8.tflite
    - assets/models/anchors.json
```

Then load both in your detector class (`flutter_integration.py` provides the Dart template):

- Load TFLite model with `Interpreter.fromAsset(...)`
- Load and parse `anchors.json` with `rootBundle.loadString(...)`
- During inference, decode model box deltas using anchors, then apply confidence filtering + NMS

## Notes

- Keep inference output contract unchanged:
  - `{"detections": [{"bbox":[x,y,w,h], "class":..., "severity":..., "confidence":...}]}`
- `anchors.json` must match the exact model/head anchor configuration used during training/export.
