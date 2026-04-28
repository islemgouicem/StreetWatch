"""
StreetWatch AI — Central Configuration
=======================================
Single source of truth for all hyperparameters.
Modify here; no values should be scattered across training code.
"""

from dataclasses import dataclass, field
from typing import List, Tuple
import os


# ─────────────────────────────────────────────────────────────────────────────
#  Class Definitions  (RDD2022 standard labels)
# ─────────────────────────────────────────────────────────────────────────────

DAMAGE_CLASSES = ["D00", "D10", "D20", "D40"]

DAMAGE_DISPLAY_NAMES = {
    "D00": "longitudinal_crack",
    "D10": "transverse_crack",
    "D20": "alligator_crack",
    "D40": "pothole",
}

SEVERITY_LEVELS = ["low", "medium", "high"]


# ─────────────────────────────────────────────────────────────────────────────
#  Model Configuration
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class ModelConfig:
    # ── Input ──────────────────────────────────────────────────────────────
    input_size: int = 320          # Width = Height (square input for SSD)
    input_channels: int = 3

    # ── Backbone: EfficientNet-Lite0 ───────────────────────────────────────
    backbone_name: str = "efficientnet_lite0"
    backbone_pretrained: bool = True
    # Reduction stages to extract (→ 20×20 @ stride-16, 10×10 @ stride-32)
    backbone_out_indices: Tuple[int, ...] = (3, 4)
    # Actual channel depths at those stages (EfficientNet-Lite0 specific)
    backbone_channels: Tuple[int, ...] = (112, 320)

    # ── SSDLite Head ───────────────────────────────────────────────────────
    num_classes: int = 4            # Background is index 0; classes start at 1
    num_severity_classes: int = 3   # low=0 / medium=1 / high=2
    # Feature map spatial sizes (after backbone + extra layers)
    feature_map_sizes: Tuple[int, ...] = (20, 10, 5, 3)
    # Number of anchors per location at each scale
    num_anchors_per_loc: Tuple[int, ...] = (4, 6, 6, 4)
    # Channel dimension for projection + extra layers
    extra_layer_channels: Tuple[int, ...] = (256, 256)
    prediction_channels: int = 256

    # ── Anchor Configuration ───────────────────────────────────────────────
    anchor_scales: Tuple[float, ...] = (0.20, 0.35, 0.55, 0.725, 0.90)
    anchor_aspect_ratios: Tuple[Tuple[float, ...], ...] = (
        (1.0, 2.0, 0.5),                # Scale 0 → 4 anchors
        (1.0, 2.0, 0.5, 3.0, 1 / 3),   # Scale 1 → 6 anchors
        (1.0, 2.0, 0.5, 3.0, 1 / 3),   # Scale 2 → 6 anchors
        (1.0, 2.0, 0.5),                # Scale 3 → 4 anchors
    )
    anchor_variance: Tuple[float, float] = (0.1, 0.2)

    # ── Matching Thresholds ────────────────────────────────────────────────
    iou_threshold_pos: float = 0.50
    iou_threshold_neg: float = 0.50

    # ── Inference ──────────────────────────────────────────────────────────
    confidence_threshold: float = 0.45
    nms_iou_threshold: float = 0.45
    max_detections: int = 50


# ─────────────────────────────────────────────────────────────────────────────
#  Training Configuration
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class TrainingConfig:
    phase1_epochs: int = 15
    phase2_epochs: int = 65

    batch_size: int = 16
    num_workers: int = 4

    phase1_lr: float = 0.010
    phase2_lr: float = 0.005
    backbone_lr_factor: float = 0.1
    weight_decay: float = 5e-4
    momentum: float = 0.9

    warmup_epochs: int = 3
    lr_scheduler: str = "cosine"

    lambda_cls: float = 1.0
    lambda_bbox: float = 1.0
    lambda_severity: float = 0.5

    focal_alpha: float = 0.25
    focal_gamma: float = 2.0

    gradient_clip_norm: float = 10.0
    patience: int = 20

    checkpoint_dir: str = "checkpoints"
    log_interval: int = 50
    seed: int = 42
    pin_memory: bool = True
    save_every_n_epochs: int = 5
    early_stop_patience: int = 20
    aug_mosaic_prob: float = 0.50
    aug_flip_prob: float = 0.50
    aug_perspective_prob: float = 0.25
    aug_blur_prob: float = 0.20


# ─────────────────────────────────────────────────────────────────────────────
#  Data Configuration
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class DataConfig:
    data_root: str = "data/rdd2022"
    train_json: str = "data/rdd2022/annotations/instances_train.json"
    val_json: str = "data/rdd2022/annotations/instances_val.json"
    test_json: str = "data/rdd2022/annotations/instances_test.json"
    train_images: str = "data/rdd2022/images/train"
    val_images: str = "data/rdd2022/images/val"
    test_images: str = "data/rdd2022/images/test"

    severity_area_weight: float = 0.60
    severity_edge_weight: float = 0.40
    severity_low_threshold: float = 0.30
    severity_high_threshold: float = 0.60

    use_mosaic: bool = True
    mosaic_prob: float = 0.50


# ─────────────────────────────────────────────────────────────────────────────
#  Export Configuration
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class ExportConfig:
    output_dir: str = "exported_models"
    best_weights: str = "checkpoints/best_model.pth"
    onnx_path: str = "exported_models/streetwatch.onnx"
    tflite_fp16_path: str = "exported_models/streetwatch_fp16.tflite"
    tflite_int8_path: str = "exported_models/streetwatch_int8.tflite"
    calibration_dataset: str = "data/rdd2022/images/val"
    num_calibration_samples: int = 200
    target_latency_ms: int = 100
    target_model_size_mb: float = 10.0
    opset_version: int = 12
    input_name: str = "image"
    output_names: Tuple[str, str, str] = ("pred_boxes", "pred_classes", "pred_severity")


# ─────────────────────────────────────────────────────────────────────────────
#  Convenience Accessor
# ─────────────────────────────────────────────────────────────────────────────

class Config:
    model = ModelConfig()
    training = TrainingConfig()
    data = DataConfig()
    export = ExportConfig()

    @staticmethod
    def from_env() -> "Config":
        """Override dataset paths from SW_DATA_ROOT environment variable if set."""
        cfg = Config()
        root = os.environ.get("SW_DATA_ROOT", "")
        if root:
            cfg.data.data_root = root
            cfg.data.train_json = f"{root}/annotations/instances_train.json"
            cfg.data.val_json = f"{root}/annotations/instances_val.json"
            cfg.data.test_json = f"{root}/annotations/instances_test.json"
            cfg.data.train_images = f"{root}/images/train"
            cfg.data.val_images = f"{root}/images/val"
            cfg.data.test_images = f"{root}/images/test"
        return cfg


# Backward-compatible aliases for older modules.
NUM_CLASSES = len(DAMAGE_CLASSES)
NUM_SEVERITY = len(SEVERITY_LEVELS)
IMAGE_SIZE = Config.model.input_size
SEVERITY_CLASSES = SEVERITY_LEVELS
SEVERITY_AREA_WEIGHT = Config.data.severity_area_weight
SEVERITY_EDGE_WEIGHT = Config.data.severity_edge_weight
SEVERITY_LOW_THRESHOLD = Config.data.severity_low_threshold
SEVERITY_HIGH_THRESHOLD = Config.data.severity_high_threshold
AREA_SCALE = 50.0
EDGE_SCALE = 3.0
TrainConfig = TrainingConfig
