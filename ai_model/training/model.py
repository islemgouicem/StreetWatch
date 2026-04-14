from ultralytics import YOLO

# ── Model config ──────────────────────────────────────────────────────────────
# Using yolov8n.yaml (architecture)

_architecture = 'yolov8n.yaml'

model = YOLO(_architecture)