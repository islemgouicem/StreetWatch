"""StreetWatch AI - Quantization Pipeline Script.

This script converts a TensorFlow SavedModel into an INT8-quantized TFLite
model using a real calibration dataset.

Pipeline:
- collect calibration images
- preprocess each image using the same letterbox logic as inference
- convert the SavedModel to TFLite
- apply post-training quantization with a representative dataset

The script is intentionally standalone so it can be submitted as a separate
artifact alongside the preprocessing script.
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path
from typing import Iterable, Iterator, List

import cv2
import numpy as np

from model_preprocessing import DEFAULT_INPUT_SIZE, preprocess_image


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def collect_images(root_dir: str | Path, max_images: int | None = None) -> List[Path]:
    """Collect calibration images recursively from a directory."""

    root = Path(root_dir)
    if not root.exists():
        raise FileNotFoundError(f"Calibration directory not found: {root}")

    images: List[Path] = []
    for path in sorted(root.rglob("*")):
        if path.suffix.lower() in IMAGE_EXTENSIONS:
            images.append(path)
            if max_images is not None and len(images) >= max_images:
                break

    if not images:
        raise FileNotFoundError(f"No calibration images found in: {root}")

    return images


def create_synthetic_calibration(
    input_size: int = DEFAULT_INPUT_SIZE,
    count: int = 50,
) -> List[Path]:
    """Create a fallback synthetic calibration set when real images are missing."""

    tmp_dir = Path(tempfile.mkdtemp(prefix="streetwatch_calib_"))
    synthetic_paths: List[Path] = []

    for index in range(count):
        image = np.random.randint(0, 256, (input_size, input_size, 3), dtype=np.uint8)
        path = tmp_dir / f"calib_{index:04d}.png"
        cv2.imwrite(str(path), image)
        synthetic_paths.append(path)

    return synthetic_paths


def representative_dataset(
    image_paths: Iterable[Path],
    input_size: int = DEFAULT_INPUT_SIZE,
    nchw: bool = False,
) -> Iterator[List[np.ndarray]]:
    """Yield representative samples for INT8 calibration."""

    for image_path in image_paths:
        tensor, _ = preprocess_image(
            image_path,
            input_size=input_size,
            nchw=nchw,
            normalize=True,
        )
        yield [tensor.astype(np.float32)]


def quantize_saved_model(
    saved_model_dir: str | Path,
    output_path: str | Path,
    calibration_dir: str | Path,
    input_size: int = DEFAULT_INPUT_SIZE,
    nchw: bool = False,
    max_calibration_images: int = 500,
    use_synthetic_calibration: bool = True,
) -> Path:
    """Convert a TensorFlow SavedModel into an INT8 quantized TFLite file."""

    try:
        import tensorflow as tf
    except ImportError as exc:
        raise RuntimeError(
            "TensorFlow is required for quantization. Install tensorflow before running this script."
        ) from exc

    saved_model_path = Path(saved_model_dir)
    if not saved_model_path.exists():
        raise FileNotFoundError(f"SavedModel directory not found: {saved_model_path}")

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    try:
        calibration_images = collect_images(calibration_dir, max_images=max_calibration_images)
        print(f"[Quantize] Using {len(calibration_images)} calibration images from {calibration_dir}")
    except FileNotFoundError as exc:
        if not use_synthetic_calibration:
            raise
        print(f"[Quantize] {exc}")
        print("[Quantize] Falling back to synthetic calibration data")
        calibration_images = create_synthetic_calibration(input_size=input_size)

    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_path))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = lambda: representative_dataset(
        calibration_images,
        input_size=input_size,
        nchw=nchw,
    )
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        tf.lite.OpsSet.TFLITE_BUILTINS,
    ]
    converter.inference_input_type = tf.float32
    converter.inference_output_type = tf.float32

    print(f"[Quantize] Converting SavedModel -> TFLite: {saved_model_path}")
    tflite_model = converter.convert()

    output.write_bytes(tflite_model)
    size_mb = output.stat().st_size / 1e6
    print(f"[Quantize] Saved quantized model -> {output} ({size_mb:.2f} MB)")
    return output


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="StreetWatch INT8 quantization pipeline",
    )
    parser.add_argument(
        "--saved-model-dir",
        default="export/saved_model",
        help="Path to the TensorFlow SavedModel directory",
    )
    parser.add_argument(
        "--calibration-dir",
        default="dataset/train/images",
        help="Directory containing calibration images",
    )
    parser.add_argument(
        "--output",
        default="export/streetwatch_int8.tflite",
        help="Output TFLite file path",
    )
    parser.add_argument("--input-size", type=int, default=DEFAULT_INPUT_SIZE)
    parser.add_argument("--nchw", action="store_true", help="Preprocess images as CHW before quantization")
    parser.add_argument("--max-calibration-images", type=int, default=500)
    parser.add_argument(
        "--no-synthetic-calibration",
        action="store_true",
        help="Fail instead of using synthetic calibration data when real images are unavailable",
    )
    return parser


def main() -> None:
    parser = build_arg_parser()
    args = parser.parse_args()

    quantize_saved_model(
        saved_model_dir=args.saved_model_dir,
        output_path=args.output,
        calibration_dir=args.calibration_dir,
        input_size=args.input_size,
        nchw=args.nchw,
        max_calibration_images=args.max_calibration_images,
        use_synthetic_calibration=not args.no_synthetic_calibration,
    )


if __name__ == "__main__":
    main()
