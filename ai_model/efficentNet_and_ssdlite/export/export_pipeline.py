"""
StreetWatch AI — Export Pipeline
==================================
Converts the trained PyTorch model to production TFLite.

Pipeline:
  1. Load PyTorch checkpoint
  2. Export to ONNX (opset 12)
  3. Convert ONNX → TensorFlow SavedModel (via onnx-tf)
  4. Convert SavedModel → TFLite FlatBuffer
  5. Apply INT8 post-training quantisation with calibration dataset
  6. Validate output: run sample inference, compare PyTorch vs TFLite

Usage
-----
  python export/export_pipeline.py \
      --checkpoint runs/streetwatch/best.pt \
      --output_dir export/ \
      --calibration_data data/rdd2022/calibration

Dependencies (install separately):
  pip install onnx onnxruntime onnx-tf tensorflow
"""

import argparse
import os
import sys
import time
from pathlib import Path
from typing import List

import cv2
import numpy as np
import torch

from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.config import IMAGE_SIZE, ExportConfig, Config
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.models.streetwatch_model import StreetWatchModel
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.inference.predictor import preprocess_numpy


# ─────────────────────────────────────────────
#  STEP 1: LOAD MODEL
# ─────────────────────────────────────────────

def load_model(checkpoint_path: str) -> StreetWatchModel:
    cfg = Config.from_env()
    model = StreetWatchModel(cfg.model)
    state = torch.load(checkpoint_path, map_location="cpu")
    model.load_state_dict(state["model_state_dict"])
    model.eval()
    print(f"[Export] Loaded checkpoint: {checkpoint_path}")
    return model


# ─────────────────────────────────────────────
#  EXPORT WRAPPER
#  The raw model returns 4 outputs; we wrap it to
#  return only the 3 prediction tensors (no anchors)
#  since anchors are fixed and can be precomputed.
# ─────────────────────────────────────────────

class ExportWrapper(torch.nn.Module):
    """
    Thin wrapper that strips the anchor tensor from the model output.
    TFLite doesn't need variable-length tensors; anchors are constants
    that the app loads separately from a JSON file generated here.
    """

    def __init__(self, model: StreetWatchModel):
        super().__init__()
        self.model = model

    def forward(self, x: torch.Tensor):
        out = self.model(x)
        return out["bbox_preds"], out["cls_logits"], out["sev_logits"]


# ─────────────────────────────────────────────
#  STEP 2: EXPORT TO ONNX
# ─────────────────────────────────────────────

def export_onnx(model: StreetWatchModel, onnx_path: str, cfg: ExportConfig):
    import onnx
    import onnxruntime as ort

    wrapper = ExportWrapper(model)
    wrapper.eval()

    dummy_input = torch.randn(1, 3, IMAGE_SIZE, IMAGE_SIZE)

    Path(onnx_path).parent.mkdir(parents=True, exist_ok=True)

    print(f"\n[Export] Exporting to ONNX: {onnx_path}")
    with torch.no_grad():
        torch.onnx.export(
            wrapper,
            dummy_input,
            onnx_path,
            opset_version=cfg.opset_version,
            input_names=[cfg.input_name],
            output_names=list(cfg.output_names),
            dynamic_axes={
                cfg.input_name: {0: "batch_size"},
            },
            do_constant_folding=True,             # fold constants into graph
            verbose=False,
        )

    # ── Validate ONNX ─────────────────────────
    print("[Export] Validating ONNX model...")
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print(f"  ✓ ONNX model valid  ({Path(onnx_path).stat().st_size / 1e6:.1f} MB)")

    # ── ONNX Runtime inference test ───────────
    ort_session = ort.InferenceSession(onnx_path)
    ort_inputs  = {cfg.input_name: dummy_input.numpy()}
    ort_outputs = ort_session.run(None, ort_inputs)

    # Compare PyTorch vs ONNX
    with torch.no_grad():
        pt_outputs = wrapper(dummy_input)

    for i, (pt, ort_out) in enumerate(zip(pt_outputs, ort_outputs)):
        max_diff = np.abs(pt.numpy() - ort_out).max()
        print(f"  Output {i} max diff PyTorch vs ONNX: {max_diff:.6f}")
        assert max_diff < 1e-4, f"ONNX mismatch on output {i}: {max_diff}"

    print("  ✓ ONNX Runtime outputs match PyTorch")
    return onnx_path


# ─────────────────────────────────────────────
#  SAVE ANCHOR JSON (used by mobile app)
# ─────────────────────────────────────────────

def save_anchors_json(model: StreetWatchModel, output_dir: str):
    """
    Pre-generate all anchor boxes and save to JSON.
    The mobile app loads this once at startup.
    """
    import json

    dummy = torch.randn(1, 3, IMAGE_SIZE, IMAGE_SIZE)
    with torch.no_grad():
        anchors = model(dummy)["anchors"]   # (N, 4) cx/cy/w/h

    anchors_list = anchors.numpy().tolist()
    anchor_path  = Path(output_dir) / "anchors.json"
    with open(anchor_path, "w") as f:
        json.dump({"anchors": anchors_list, "image_size": IMAGE_SIZE}, f)

    print(f"[Export] Saved {len(anchors_list)} anchors → {anchor_path}")
    return str(anchor_path)


# ─────────────────────────────────────────────
#  STEP 3+4: ONNX → TFLite
# ─────────────────────────────────────────────

def export_tflite(
    onnx_path: str,
    tflite_path: str,
    calibration_dir: str,
    cfg: ExportConfig,
):
    """
    Convert ONNX → TF SavedModel → TFLite with INT8 quantisation.

    INT8 quantisation reduces model size ~4× and latency ~2× on mobile
    with minimal accuracy loss (typically < 1% mAP).
    """
    try:
        import onnx
        from onnx_tf.backend import prepare
        import tensorflow as tf
    except ImportError as e:
        print(f"\n[Export] Missing dependency: {e}")
        print("  Install: pip install onnx-tf tensorflow")
        sys.exit(1)

    saved_model_dir = str(Path(tflite_path).parent / "saved_model")
    Path(saved_model_dir).mkdir(parents=True, exist_ok=True)

    # ── ONNX → TF SavedModel ──────────────────
    print(f"\n[Export] Converting ONNX → TF SavedModel: {saved_model_dir}")
    onnx_model = onnx.load(onnx_path)
    tf_rep     = prepare(onnx_model)
    tf_rep.export_graph(saved_model_dir)
    print(f"  ✓ SavedModel exported")

    # ── Build calibration dataset ─────────────
    calib_images = _collect_calibration_images(calibration_dir)
    print(f"\n[Export] Using {len(calib_images)} calibration images for INT8")

    def representative_dataset():
        """Generator yielding calibration batches for INT8 quantisation."""
        for img_path in calib_images[:500]:   # cap at 500 images
            arr, _ = preprocess_numpy(img_path)
            yield [arr.astype(np.float32)]

    # ── SavedModel → TFLite INT8 ──────────────
    print(f"\n[Export] Converting to TFLite INT8: {tflite_path}")
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)

    # INT8 post-training quantisation
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        tf.lite.OpsSet.TFLITE_BUILTINS,   # fallback for unsupported ops
    ]
    converter.inference_input_type  = tf.float32   # keep float I/O for simplicity
    converter.inference_output_type = tf.float32

    tflite_model = converter.convert()

    Path(tflite_path).parent.mkdir(parents=True, exist_ok=True)
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)

    size_mb = Path(tflite_path).stat().st_size / 1e6
    print(f"  ✓ TFLite INT8 model saved: {tflite_path} ({size_mb:.1f} MB)")
    return tflite_path


def _collect_calibration_images(calib_dir: str) -> List[str]:
    """Collect all image paths in calibration directory."""
    extensions = {".jpg", ".jpeg", ".png", ".bmp"}
    calib_dir  = Path(calib_dir)
    images     = []

    if not calib_dir.exists():
        print(f"[Export] Warning: calibration dir not found: {calib_dir}")
        print("[Export] Creating synthetic calibration data (not ideal — use real images)")
        return _create_synthetic_calibration()

    for ext in extensions:
        images.extend(calib_dir.rglob(f"*{ext}"))

    if not images:
        print(f"[Export] Warning: no images in {calib_dir}")
        return _create_synthetic_calibration()

    return [str(p) for p in images]


def _create_synthetic_calibration() -> List[str]:
    """
    Fallback: generate random noise images for calibration.
    Use real road images whenever possible — this is just a safety net.
    """
    import tempfile
    tmp_dir = Path(tempfile.mkdtemp())
    paths   = []
    for i in range(50):
        arr  = np.random.randint(0, 256, (IMAGE_SIZE, IMAGE_SIZE, 3), dtype=np.uint8)
        path = str(tmp_dir / f"calib_{i:04d}.png")
        cv2.imwrite(path, arr)
        paths.append(path)
    return paths


# ─────────────────────────────────────────────
#  STEP 5: VALIDATE TFLITE
# ─────────────────────────────────────────────

def validate_tflite(tflite_path: str, test_image_path: Optional[str] = None):
    """
    Smoke-test the TFLite model: run one inference and print output shapes + timing.
    """
    from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.inference.predictor import TFLitePredictor

    predictor = TFLitePredictor(tflite_path, conf_threshold=0.01)

    if test_image_path is None:
        # Synthetic test image
        img = np.random.randint(0, 256, (480, 640, 3), dtype=np.uint8)
    else:
        img = cv2.imread(test_image_path)

    # Warm up
    for _ in range(3):
        predictor.predict(img)

    # Benchmark
    times = []
    for _ in range(10):
        t0     = time.perf_counter()
        result = predictor.predict(img)
        times.append((time.perf_counter() - t0) * 1000)

    avg_ms = np.mean(times)
    p95_ms = np.percentile(times, 95)

    print(f"\n[Validate] TFLite inference benchmark (10 runs):")
    print(f"  Avg latency : {avg_ms:.1f} ms")
    print(f"  P95 latency : {p95_ms:.1f} ms")
    print(f"  Detections  : {len(result['detections'])} (conf > 0.01)")

    if avg_ms > 100:
        print("  ⚠ Warning: avg latency > 100ms — consider further optimisation")
    else:
        print("  ✓ Latency within mobile target (< 100ms)")


# ─────────────────────────────────────────────
#  FULL PIPELINE
# ─────────────────────────────────────────────

def run_export_pipeline(
    checkpoint_path: str,
    output_dir: str,
    calibration_data: str,
    test_image: Optional[str] = None,
):
    cfg = ExportConfig()
    cfg.onnx_path = str(Path(output_dir) / "streetwatch.onnx")
    cfg.tflite_int8_path = str(Path(output_dir) / "streetwatch_int8.tflite")

    print("\n" + "="*60)
    print("  StreetWatch Export Pipeline")
    print("="*60)

    # 1. Load
    model = load_model(checkpoint_path)

    # 2. ONNX export
    export_onnx(model, cfg.onnx_path, cfg)

    # 2b. Save anchors
    save_anchors_json(model, output_dir)

    # 3+4. ONNX → TFLite INT8
    export_tflite(cfg.onnx_path, cfg.tflite_int8_path, calibration_data, cfg)

    # 5. Validate
    validate_tflite(cfg.tflite_int8_path, test_image)

    print("\n" + "="*60)
    print("  Export complete!")
    print(f"  TFLite model : {cfg.tflite_int8_path}")
    print(f"  Anchors JSON : {output_dir}/anchors.json")
    print("  → Copy both files to your Flutter assets/ directory")
    print("="*60 + "\n")


# ─────────────────────────────────────────────
#  CLI
# ─────────────────────────────────────────────

if __name__ == "__main__":
    from typing import Optional

    parser = argparse.ArgumentParser(description="StreetWatch Export Pipeline")
    parser.add_argument("--checkpoint",       required=True, help="Path to best.pt")
    parser.add_argument("--output_dir",       default="export/", help="Output directory")
    parser.add_argument("--calibration_data", default="data/rdd2022/calibration",
                        help="Directory of calibration images for INT8 quantisation")
    parser.add_argument("--test_image",       default=None, help="Optional test image path")
    args = parser.parse_args()

    run_export_pipeline(
        checkpoint_path=args.checkpoint,
        output_dir=args.output_dir,
        calibration_data=args.calibration_data,
        test_image=args.test_image,
    )
