from ultralytics import YOLO
import yaml
import wandb
import os

# you should run the following command in the terminal:
# uv run train.py

# ── Get the directory where this script is located ──────────────────────────
script_dir = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(script_dir, 'config.yaml')
with open(config_path, 'r') as f:
    cfg = yaml.safe_load(f)

# ── Initialize WandB ─────────────────────────────────────────────────────────
wandb.init(
    project=cfg['wandb_project'],
    name=cfg['name'],
    config={
        "architecture": "yolov8n",
        "epochs": cfg['epoch'],
        "batch_size": cfg['batch'],
        "imgsz": cfg['imgsz'],
        "pretrained": cfg['pretrained'],
    }
)


# ── Train with config parameters ──────────────────────────────────────────────
model = YOLO('yolov8n.yaml')

results = model.train(
    data = os.path.join(script_dir, 'rdd2022.yaml'),
    epochs        = cfg['epoch'],
    warmup_epochs = cfg['warmup_epochs'],
    batch         = cfg['batch'],
    imgsz         = cfg['imgsz'],
    save_period   = cfg['save_period'],
    workers       = cfg['workers'],
    project = os.path.join(script_dir, cfg['project_folder']),
    name          = cfg['name'],
    seed          = cfg['seed'],
    cos_lr        = cfg['cos_lr'],
    pretrained    = cfg['pretrained'],
    mosaic        = cfg['mosaic'],
    mixup         = cfg['mixup'],
    fliplr        = cfg['fliplr'],
    hsv_h         = cfg['hsv_h'],
    hsv_s         = cfg['hsv_s'],
    hsv_v         = cfg['hsv_v'],

    exist_ok      = True,
    plots         = True,      # Plot loss curves
    save          = True,      # Save checkpoints

)

wandb.finish()
# ── Resume training if interrupted ────────────────────────────────────────────
# weight_path = f"{cfg['project']}/{cfg['name']}/weights/last.pt"
# model = YOLO(weight_path)
# results = model.train(resume=True)