"""
StreetWatch AI — Inference Predictor
======================================
Single entry-point for all inference use cases:

  1. PyTorch model prediction (development / validation)
  2. TFLite model prediction (mobile production)

Both return the same JSON-contract output format.
"""

import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

import cv2
import numpy as np
import torch
import torch.nn.functional as F

from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.config import (
    DAMAGE_DISPLAY_NAMES, SEVERITY_CLASSES,
    IMAGE_SIZE, Config,
)
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.models.streetwatch_model import StreetWatchModel
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.training.anchor_utils import decode_boxes


# ─────────────────────────────────────────────
#  IMAGE PREPROCESSOR  (shared by both backends)
# ─────────────────────────────────────────────

def preprocess_image(
    image: Union[str, np.ndarray],
    size: int = IMAGE_SIZE,
) -> Tuple[torch.Tensor, Tuple[int, int]]:
    """
    Load and preprocess a single image for inference.

    Args
    ----
    image : file path (str/Path) or BGR numpy array from cv2.imread
    size  : target square size (default 320)

    Returns
    -------
    tensor     : (1, 3, size, size) float32 in [0, 1]
    orig_size  : (orig_H, orig_W) for coordinate de-normalisation
    """
    if isinstance(image, (str, Path)):
        img = cv2.imread(str(image))
        if img is None:
            raise FileNotFoundError(f"Image not found: {image}")
    else:
        img = image.copy()

    orig_h, orig_w = img.shape[:2]
    img_rgb  = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resz = cv2.resize(img_rgb, (size, size))
    tensor   = torch.from_numpy(img_resz.astype(np.float32) / 255.0).permute(2, 0, 1)
    return tensor.unsqueeze(0), (orig_h, orig_w)


def preprocess_numpy(
    image: Union[str, np.ndarray],
    size: int = IMAGE_SIZE,
) -> Tuple[np.ndarray, Tuple[int, int]]:
    """
    Same as preprocess_image but returns a numpy array for TFLite.
    Output shape: (1, size, size, 3) — NHWC format required by TFLite.
    """
    if isinstance(image, (str, Path)):
        img = cv2.imread(str(image))
        if img is None:
            raise FileNotFoundError(f"Image not found: {image}")
    else:
        img = image.copy()

    orig_h, orig_w = img.shape[:2]
    img_rgb  = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resz = cv2.resize(img_rgb, (size, size))
    arr      = img_resz.astype(np.float32) / 255.0
    return arr[np.newaxis, ...], (orig_h, orig_w)   # NHWC


# ─────────────────────────────────────────────
#  PYTORCH PREDICTOR (development / server)
# ─────────────────────────────────────────────

class PyTorchPredictor:
    """
    Run inference using the PyTorch model.
    Use this for development, evaluation, and server-side inference.
    """

    def __init__(
        self,
        checkpoint_path: str,
        device: Optional[str] = None,
        conf_threshold: float = 0.45,
        nms_iou_threshold: float = 0.45,
    ):
        if device is None:
            device = (
                "cuda" if torch.cuda.is_available() else
                "mps"  if torch.backends.mps.is_available() else
                "cpu"
            )
        self.device = torch.device(device)
        self.conf_threshold   = conf_threshold
        self.nms_iou_threshold = nms_iou_threshold
        cfg = Config.from_env()
        self.model_cfg = cfg.model
        self.model = StreetWatchModel(self.model_cfg)
        state = torch.load(checkpoint_path, map_location=self.device)
        self.model.load_state_dict(state["model_state_dict"])
        self.model.to(self.device).eval()
        print(f"[PyTorchPredictor] Loaded checkpoint: {checkpoint_path}")

    def predict(self, image: Union[str, np.ndarray]) -> Dict:
        """
        Run inference on a single image.

        Returns
        -------
        {
          "detections": [...],
          "inference_ms": float
        }
        """
        tensor, orig_size = preprocess_image(image)
        tensor = tensor.to(self.device)

        t0 = time.perf_counter()
        out = self.model(tensor)
        boxes = decode_boxes(out["bbox_preds"], out["anchors"].unsqueeze(0), self.model_cfg.anchor_variance)[0]
        cls_probs = F.softmax(out["cls_logits"][0], dim=-1)[:, 1:]
        conf, cls_idx = cls_probs.max(dim=-1)
        sev_idx = out["sev_logits"][0].argmax(dim=-1)
        keep = conf >= self.conf_threshold
        detections = []
        if keep.any():
            from torchvision.ops import batched_nms
            b = boxes[keep]
            c = conf[keep]
            l = cls_idx[keep]
            s = sev_idx[keep]
            x1 = (b[:, 0] - b[:, 2] / 2).clamp(0, 1)
            y1 = (b[:, 1] - b[:, 3] / 2).clamp(0, 1)
            x2 = (b[:, 0] + b[:, 2] / 2).clamp(0, 1)
            y2 = (b[:, 1] + b[:, 3] / 2).clamp(0, 1)
            keep_nms = batched_nms(torch.stack([x1, y1, x2, y2], dim=1), c, l, self.nms_iou_threshold)
            class_names = list(DAMAGE_DISPLAY_NAMES.values())
            for i in keep_nms:
                cx, cy, bw, bh = b[i]
                detections.append({
                    "bbox": [round(float((cx - bw / 2).clamp(0, 1)), 4),
                             round(float((cy - bh / 2).clamp(0, 1)), 4),
                             round(float(bw.clamp(0, 1)), 4),
                             round(float(bh.clamp(0, 1)), 4)],
                    "class": class_names[int(l[i])],
                    "severity": SEVERITY_CLASSES[int(s[i])],
                    "confidence": round(float(c[i]), 4),
                })
        inference_ms = (time.perf_counter() - t0) * 1000

        return {"detections": detections}


# ─────────────────────────────────────────────
#  TFLITE PREDICTOR (mobile production)
# ─────────────────────────────────────────────

class TFLitePredictor:
    """
    Run inference using the quantised TFLite model.
    This is what runs on the mobile device (via flutter_tflite or tflite_flutter).

    On Android: use GPU delegate (passed as options to the Flutter plugin).
    On iOS:     use Core ML delegate.

    This Python implementation mirrors exactly what the Flutter app does,
    allowing offline validation before shipping.
    """

    def __init__(
        self,
        tflite_path: str,
        conf_threshold: float = 0.45,
        nms_iou_threshold: float = 0.45,
        use_gpu_delegate: bool = False,   # set True in benchmarking
    ):
        try:
            import tensorflow as tf
            self._tf = tf
        except ImportError:
            raise ImportError(
                "TensorFlow required for TFLite inference.\n"
                "Install with: pip install tensorflow"
            )

        self.conf_threshold    = conf_threshold
        self.nms_iou_threshold = nms_iou_threshold

        # Load interpreter
        interpreter_options = {}
        if use_gpu_delegate:
            try:
                delegate = self._tf.lite.experimental.load_delegate("libtensorflowlite_gpu_delegate.so")
                interpreter_options["experimental_delegates"] = [delegate]
            except Exception:
                print("[TFLitePredictor] GPU delegate unavailable, falling back to CPU")

        self.interpreter = self._tf.lite.Interpreter(
            model_path=tflite_path,
            **interpreter_options
        )
        self.interpreter.allocate_tensors()

        self.input_details  = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        print(f"[TFLitePredictor] Loaded: {tflite_path}")
        print(f"  Input  shape: {self.input_details[0]['shape']}")
        for od in self.output_details:
            print(f"  Output '{od['name']}': {od['shape']}")

    def _run_tflite(self, arr: np.ndarray) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        Run TFLite interpreter and return (boxes, cls_logits, sev_logits).
        All outputs are numpy arrays.
        """
        self.interpreter.set_tensor(self.input_details[0]["index"], arr)
        self.interpreter.invoke()

        # Output order matches ExportConfig.output_names:
        #   [pred_boxes, pred_classes, pred_severity, pred_scores]
        boxes      = self.interpreter.get_tensor(self.output_details[0]["index"])[0]  # (N, 4)
        cls_logits = self.interpreter.get_tensor(self.output_details[1]["index"])[0]  # (N, C)
        sev_logits = self.interpreter.get_tensor(self.output_details[2]["index"])[0]  # (N, 3)

        return boxes, cls_logits, sev_logits

    @staticmethod
    def _softmax(x: np.ndarray) -> np.ndarray:
        e = np.exp(x - x.max(axis=-1, keepdims=True))
        return e / e.sum(axis=-1, keepdims=True)

    @staticmethod
    def _nms(
        boxes_xyxy: np.ndarray,
        scores: np.ndarray,
        iou_threshold: float,
    ) -> np.ndarray:
        """Simple class-agnostic NMS (numpy implementation for TFLite path)."""
        x1, y1, x2, y2 = boxes_xyxy[:, 0], boxes_xyxy[:, 1], boxes_xyxy[:, 2], boxes_xyxy[:, 3]
        areas  = (x2 - x1) * (y2 - y1)
        order  = scores.argsort()[::-1]
        keep   = []

        while order.size > 0:
            i = order[0]
            keep.append(i)
            if order.size == 1:
                break
            rest = order[1:]

            ix1 = np.maximum(x1[i], x1[rest])
            iy1 = np.maximum(y1[i], y1[rest])
            ix2 = np.minimum(x2[i], x2[rest])
            iy2 = np.minimum(y2[i], y2[rest])

            inter = np.maximum(0, ix2 - ix1) * np.maximum(0, iy2 - iy1)
            iou   = inter / (areas[i] + areas[rest] - inter + 1e-6)
            order = rest[iou <= iou_threshold]

        return np.array(keep, dtype=np.int32)

    def predict(self, image: Union[str, np.ndarray]) -> Dict:
        """
        Run TFLite inference on a single image.

        Note: TFLite model does NOT include the decode/NMS ops.
        Those are applied here in Python (or in Dart on the device).
        For production Flutter app, this logic is replicated in Dart.
        """
        arr, orig_size = preprocess_numpy(image)

        t0 = time.perf_counter()
        boxes, cls_logits, sev_logits = self._run_tflite(arr)
        inference_ms = (time.perf_counter() - t0) * 1000

        # Class probabilities (exclude bg class 0)
        cls_probs = self._softmax(cls_logits)[:, 1:]   # (N, NUM_CLASSES)
        conf      = cls_probs.max(axis=-1)              # (N,)
        cls_idx   = cls_probs.argmax(axis=-1)           # (N,)

        # Severity
        sev_probs = self._softmax(sev_logits)           # (N, 3)
        sev_idx   = sev_probs.argmax(axis=-1)           # (N,)

        # Filter by confidence
        keep_mask = conf >= self.conf_threshold
        if not keep_mask.any():
            return {"detections": []}

        boxes_k   = boxes[keep_mask]
        conf_k    = conf[keep_mask]
        cls_k     = cls_idx[keep_mask]
        sev_k     = sev_idx[keep_mask]

        # cx/cy/w/h → x1/y1/x2/y2 for NMS
        x1 = np.clip(boxes_k[:, 0] - boxes_k[:, 2] / 2, 0, 1)
        y1 = np.clip(boxes_k[:, 1] - boxes_k[:, 3] / 2, 0, 1)
        x2 = np.clip(boxes_k[:, 0] + boxes_k[:, 2] / 2, 0, 1)
        y2 = np.clip(boxes_k[:, 1] + boxes_k[:, 3] / 2, 0, 1)
        boxes_xyxy = np.stack([x1, y1, x2, y2], axis=1)

        nms_keep = self._nms(boxes_xyxy, conf_k, self.nms_iou_threshold)

        detections = []
        for i in nms_keep:
            bx, by, bw, bh = boxes_k[i]
            out_x = max(0.0, float(bx - bw / 2))
            out_y = max(0.0, float(by - bh / 2))
            detections.append({
                "bbox":       [round(out_x, 4), round(out_y, 4),
                               round(float(bw), 4), round(float(bh), 4)],
                "class":      list(DAMAGE_DISPLAY_NAMES.values())[int(cls_k[i])],
                "severity":   SEVERITY_CLASSES[int(sev_k[i])],
                "confidence": round(float(conf_k[i]), 4),
            })

        return {
            "detections": detections,
        }


# ─────────────────────────────────────────────
#  VISUALISATION UTILITY (dev / debugging)
# ─────────────────────────────────────────────

SEVERITY_COLORS = {
    "low":    (0, 200, 0),     # green
    "medium": (0, 165, 255),   # orange
    "high":   (0, 0, 220),     # red
}

def visualise_detections(
    image: Union[str, np.ndarray],
    result: Dict,
    output_path: Optional[str] = None,
) -> np.ndarray:
    """
    Draw bounding boxes and labels on the image.

    bbox coordinates are normalised [0,1] and will be scaled to image dims.
    """
    if isinstance(image, (str, Path)):
        img = cv2.imread(str(image))
    else:
        img = image.copy()

    h, w = img.shape[:2]

    for det in result.get("detections", []):
        x, y, bw, bh = det["bbox"]
        x1 = int(x  * w);  y1 = int(y  * h)
        x2 = int((x + bw) * w); y2 = int((y + bh) * h)

        color = SEVERITY_COLORS.get(det["severity"], (200, 200, 200))
        cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)

        label = f"{det['class']} | {det['severity']} | {det['confidence']:.2f}"
        (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)
        cv2.rectangle(img, (x1, y1 - th - 6), (x1 + tw + 4, y1), color, -1)
        cv2.putText(img, label, (x1 + 2, y1 - 4),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 255), 1)

    inf_ms = result.get("inference_ms", 0)
    cv2.putText(img, f"Inference: {inf_ms}ms", (10, 24),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)

    if output_path:
        cv2.imwrite(output_path, img)

    return img
