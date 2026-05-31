"""StreetWatch AI - Model Preprocessing Script.

This script reproduces the exact preprocessing used by the TFLite inference
engine:

- letterbox resize to the model input size
- center padding with a neutral gray value
- BGR -> RGB conversion
- optional NHWC or NCHW layout
- float32 normalization to [0, 1]

The script can be used as a reusable preprocessing module or as a small CLI
utility to inspect the processed tensor for a single image.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Dict, Tuple

import cv2
import numpy as np


DEFAULT_INPUT_SIZE = 320
DEFAULT_PAD_VALUE = 114


def letterbox_resize(
    frame: np.ndarray,
    input_size: int = DEFAULT_INPUT_SIZE,
    pad_value: int = DEFAULT_PAD_VALUE,
) -> Tuple[np.ndarray, Dict[str, object]]:
    """Resize an image while preserving aspect ratio and padding to a square."""

    orig_h, orig_w = frame.shape[:2]
    scale = min(input_size / orig_w, input_size / orig_h)
    new_w = max(1, int(round(orig_w * scale)))
    new_h = max(1, int(round(orig_h * scale)))

    resized = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
    canvas = np.full((input_size, input_size, 3), pad_value, dtype=np.uint8)

    pad_x = (input_size - new_w) // 2
    pad_y = (input_size - new_h) // 2
    canvas[pad_y:pad_y + new_h, pad_x:pad_x + new_w] = resized

    meta: Dict[str, object] = {
        "orig_shape": (orig_h, orig_w),
        "input_size": input_size,
        "scale": scale,
        "pad": (pad_x, pad_y),
        "resized_shape": (new_h, new_w),
    }
    return canvas, meta


def preprocess_frame(
    frame: np.ndarray,
    input_size: int = DEFAULT_INPUT_SIZE,
    nchw: bool = False,
    normalize: bool = True,
) -> Tuple[np.ndarray, Dict[str, object]]:
    """Preprocess a BGR frame into a model-ready tensor."""

    canvas, meta = letterbox_resize(frame, input_size=input_size)
    rgb = cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB)

    if nchw:
        rgb = rgb.transpose(2, 0, 1)

    tensor = rgb.astype(np.float32)
    if normalize:
        tensor /= 255.0

    tensor = np.expand_dims(tensor, 0)
    meta["layout"] = "NCHW" if nchw else "NHWC"
    meta["normalized"] = normalize
    return tensor, meta


def preprocess_image(
    image_path: str | Path,
    input_size: int = DEFAULT_INPUT_SIZE,
    nchw: bool = False,
    normalize: bool = True,
) -> Tuple[np.ndarray, Dict[str, object]]:
    """Load an image from disk and preprocess it."""

    path = Path(image_path)
    frame = cv2.imread(str(path))
    if frame is None:
        raise FileNotFoundError(f"Unable to load image: {path}")

    return preprocess_frame(
        frame,
        input_size=input_size,
        nchw=nchw,
        normalize=normalize,
    )


def save_tensor(tensor: np.ndarray, output_path: str | Path) -> Path:
    """Save the preprocessed tensor as a NumPy .npy file."""

    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    np.save(path, tensor)
    return path


def save_preview(
    image_path: str | Path,
    output_path: str | Path,
    input_size: int = DEFAULT_INPUT_SIZE,
) -> Path:
    """Save the letterboxed image preview for visual inspection."""

    frame = cv2.imread(str(image_path))
    if frame is None:
        raise FileNotFoundError(f"Unable to load image: {image_path}")

    canvas, _ = letterbox_resize(frame, input_size=input_size)
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(path), canvas)
    return path


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="StreetWatch image preprocessing utility",
    )
    parser.add_argument("--image", required=True, help="Path to a road damage image")
    parser.add_argument("--input-size", type=int, default=DEFAULT_INPUT_SIZE)
    parser.add_argument("--nchw", action="store_true", help="Return CHW layout instead of HWC")
    parser.add_argument("--no-normalize", action="store_true", help="Skip scaling pixels to [0, 1]")
    parser.add_argument("--output", help="Optional .npy file path for the preprocessed tensor")
    parser.add_argument("--preview", help="Optional path for the letterboxed image preview")
    return parser


def main() -> None:
    parser = build_arg_parser()
    args = parser.parse_args()

    tensor, meta = preprocess_image(
        args.image,
        input_size=args.input_size,
        nchw=args.nchw,
        normalize=not args.no_normalize,
    )

    print("[Preprocess] Image:", args.image)
    print("[Preprocess] Tensor shape:", tensor.shape)
    print("[Preprocess] Layout:", meta["layout"])
    print("[Preprocess] Scale:", round(float(meta["scale"]), 6))
    print("[Preprocess] Pad:", meta["pad"])
    print("[Preprocess] Normalized:", meta["normalized"])

    if args.output:
      saved = save_tensor(tensor, args.output)
      print(f"[Preprocess] Tensor saved -> {saved}")

    if args.preview:
        saved_preview = save_preview(args.image, args.preview, input_size=args.input_size)
        print(f"[Preprocess] Preview saved -> {saved_preview}")


if __name__ == "__main__":
    main()
