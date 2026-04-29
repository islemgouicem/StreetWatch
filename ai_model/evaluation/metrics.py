from ultralytics import YOLO
import os

# ── Resolve paths relative to this script's location ─────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(script_dir)  # ai_model/

_weights = os.path.join(project_dir, "runs", "Baseline_YOLOv8Nano_Scratch", "weights", "best.pt")
_data    = os.path.join(project_dir, "training", "rdd2022.yaml")

model = YOLO(_weights)

# ── Run evaluation on test split ──────────────────────────────────────────────
results = model.val(
    data  = _data,
    split = 'test',
    imgsz = 320,
)

# ── Print metrics ─────────────────────────────────────────────────────────────
print(f"\nmAP@0.5:      {results.box.map50:.4f}")
print(f"mAP@0.5:0.95: {results.box.map:.4f}")
print(f"Precision:    {results.box.mp:.4f}")
print(f"Recall:       {results.box.mr:.4f}")

# ── Per-class breakdown ───────────────────────────────────────────────────────
_class_names = [
    'longitudinal crack',
    'transverse crack',
    'alligator crack',
    'other corruption',
    'Pothole'
]

print("\nPer-class AP@0.5:")
for i, ap in enumerate(results.box.ap50):
    print(f"  {_class_names[i]:<22}: {ap:.4f}")