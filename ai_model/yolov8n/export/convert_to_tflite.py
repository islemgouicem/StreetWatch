from ultralytics import YOLO
import os

# ── Resolve paths relative to this script's location ─────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(script_dir)  # ai_model/


# ── Load best trained weights ─────────────────────────────────────────────────
_weights = os.path.join(project_dir, "runs", "Baseline_YOLOv8Nano_Scratch", "weights", "best.pt")

model = YOLO(_weights)

# ── Export to TFLite (int8 quantized) ────────────────────────────────────────
model.export(
    format = 'tflite',
    imgsz  = 320,
    int8   = True,      # quantize: float32 → int8 (~4x smaller, faster on mobile)
)

# Output: best_int8.tflite  → drop into Flutter assets/ folder

# ── Severity (called after inference, not inside model) ───────────────────────
def compute_severity(bbox_w_norm: float, bbox_h_norm: float) -> str:
    area = bbox_w_norm * bbox_h_norm
    if area < 0.002:  return 'low'
    elif area < 0.02: return 'medium'
    else:             return 'high'