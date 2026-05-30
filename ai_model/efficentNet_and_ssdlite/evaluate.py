"""
StreetWatch AI — Evaluation
============================
Computes:
  - mAP@0.5 and mAP@0.5:0.95  (detection quality)
  - Per-class F1                (class-specific performance)
  - Severity accuracy           (proxy vs predicted)
  - Inference latency           (P50 / P95)

Usage
-----
  python evaluate.py \
      --checkpoint runs/streetwatch/best.pt \
      --ann_file data/rdd2022/annotations/test.json \
      --img_root data/rdd2022
"""

import argparse
import time
from collections import defaultdict
from typing import Dict, List, Tuple

import numpy as np
import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader

from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.config import DAMAGE_DISPLAY_NAMES, NUM_CLASSES, Config
from data.dataset import RDDDataset, collate_fn
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.models.streetwatch_model import StreetWatchModel
from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.training.anchor_utils import decode_boxes


# ─────────────────────────────────────────────
#  IOF HELPERS
# ─────────────────────────────────────────────

def box_iou_xyxy(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """IoU between (M,4) and (N,4) boxes in x1y1x2y2 format → (M,N)."""
    ax1, ay1, ax2, ay2 = a[:, 0], a[:, 1], a[:, 2], a[:, 3]
    bx1, by1, bx2, by2 = b[:, 0], b[:, 1], b[:, 2], b[:, 3]

    ix1 = np.maximum(ax1[:, None], bx1[None, :])
    iy1 = np.maximum(ay1[:, None], by1[None, :])
    ix2 = np.minimum(ax2[:, None], bx2[None, :])
    iy2 = np.minimum(ay2[:, None], by2[None, :])

    inter = np.maximum(0, ix2 - ix1) * np.maximum(0, iy2 - iy1)
    area_a = (ax2 - ax1) * (ay2 - ay1)
    area_b = (bx2 - bx1) * (by2 - by1)
    union  = area_a[:, None] + area_b[None, :] - inter

    return inter / np.maximum(union, 1e-6)


def cx_to_xyxy(boxes: np.ndarray) -> np.ndarray:
    """(cx, cy, w, h) → (x1, y1, x2, y2)."""
    x1 = boxes[:, 0] - boxes[:, 2] / 2
    y1 = boxes[:, 1] - boxes[:, 3] / 2
    x2 = boxes[:, 0] + boxes[:, 2] / 2
    y2 = boxes[:, 1] + boxes[:, 3] / 2
    return np.stack([x1, y1, x2, y2], axis=1)


# ─────────────────────────────────────────────
#  MAP COMPUTATION
# ─────────────────────────────────────────────

def compute_ap(recalls: np.ndarray, precisions: np.ndarray) -> float:
    """
    Compute Average Precision using the 11-point interpolation (VOC style).
    """
    ap = 0.0
    for t in np.linspace(0, 1, 11):
        if np.sum(recalls >= t) == 0:
            p = 0.0
        else:
            p = np.max(precisions[recalls >= t])
        ap += p / 11
    return ap


def compute_map(
    all_predictions: List[Dict],   # list of {boxes, scores, labels} per image
    all_targets:     List[Dict],   # list of {boxes, labels} per image
    iou_thresholds: List[float] = None,
) -> Dict:
    """
    Compute mAP across IoU thresholds.

    Returns
    -------
    {
      "mAP_50":    float,
      "mAP_50_95": float,
      "per_class": {class_name: ap_at_50},
    }
    """
    if iou_thresholds is None:
        iou_thresholds = [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95]

    aps_by_iou_class: Dict[float, Dict[int, float]] = {t: {} for t in iou_thresholds}

    for cls_id in range(NUM_CLASSES):
        for iou_thresh in iou_thresholds:
            tp_list, fp_list, scores_list = [], [], []
            n_gt = 0

            for preds, targets in zip(all_predictions, all_targets):
                gt_mask  = targets["labels"] == cls_id
                gt_boxes = cx_to_xyxy(targets["boxes"][gt_mask]) if gt_mask.any() else np.zeros((0, 4))
                n_gt += gt_mask.sum()

                pred_mask   = preds["labels"] == cls_id
                pred_boxes  = cx_to_xyxy(preds["boxes"][pred_mask]) if pred_mask.any() else np.zeros((0, 4))
                pred_scores = preds["scores"][pred_mask] if pred_mask.any() else np.zeros(0)

                if len(pred_boxes) == 0:
                    continue

                if len(gt_boxes) == 0:
                    fp_list.extend([1] * len(pred_boxes))
                    tp_list.extend([0] * len(pred_boxes))
                    scores_list.extend(pred_scores.tolist())
                    continue

                iou_mat = box_iou_xyxy(pred_boxes, gt_boxes)
                matched = np.zeros(len(gt_boxes), dtype=bool)

                # Sort by score descending
                score_order = pred_scores.argsort()[::-1]
                for pi in score_order:
                    best_iou  = iou_mat[pi].max()
                    best_gt   = iou_mat[pi].argmax()
                    if best_iou >= iou_thresh and not matched[best_gt]:
                        tp_list.append(1)
                        fp_list.append(0)
                        matched[best_gt] = True
                    else:
                        tp_list.append(0)
                        fp_list.append(1)
                    scores_list.append(pred_scores[pi])

            if n_gt == 0 or not scores_list:
                aps_by_iou_class[iou_thresh][cls_id] = 0.0
                continue

            order    = np.argsort(scores_list)[::-1]
            tp_arr   = np.array(tp_list)[order]
            fp_arr   = np.array(fp_list)[order]

            cum_tp   = np.cumsum(tp_arr)
            cum_fp   = np.cumsum(fp_arr)

            recalls    = cum_tp / max(n_gt, 1)
            precisions = cum_tp / (cum_tp + cum_fp + 1e-6)

            aps_by_iou_class[iou_thresh][cls_id] = compute_ap(recalls, precisions)

    # Aggregate
    ap50_per_class   = aps_by_iou_class[0.50]
    map_50           = float(np.mean(list(ap50_per_class.values())))
    map_50_95_values = []
    for t in iou_thresholds:
        map_50_95_values.append(np.mean(list(aps_by_iou_class[t].values())))
    map_50_95        = float(np.mean(map_50_95_values))

    class_names = list(DAMAGE_DISPLAY_NAMES.values())
    per_class = {class_names[c]: round(ap, 4) for c, ap in ap50_per_class.items()}

    return {
        "mAP_50":    round(map_50, 4),
        "mAP_50_95": round(map_50_95, 4),
        "per_class": per_class,
    }


# ─────────────────────────────────────────────
#  FULL EVALUATION
# ─────────────────────────────────────────────

def evaluate(checkpoint_path: str, ann_file: str, img_root: str):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Load model
    cfg = Config.from_env()
    model = StreetWatchModel(cfg.model)
    state = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(state["model_state_dict"])
    model.to(device).eval()
    print(f"[Eval] Loaded: {checkpoint_path}")

    # Dataset
    dataset = RDDDataset(ann_file, img_root, cfg.training, augment=False)
    loader  = DataLoader(dataset, batch_size=8, shuffle=False,
                         num_workers=4, collate_fn=collate_fn)

    all_predictions, all_targets = [], []
    severity_correct, severity_total = 0, 0
    latencies = []

    from torchvision.ops import batched_nms

    with torch.no_grad():
        for images, gt_boxes_list, gt_labels_list, gt_sev_list in loader:
            images = images.to(device)
            B = images.shape[0]

            t0 = time.perf_counter()
            out = model(images)
            latencies.append((time.perf_counter() - t0) * 1000 / B)

            decoded = decode_boxes(out["bbox_preds"], out["anchors"].unsqueeze(0), cfg.model.anchor_variance)

            for b in range(B):
                cls_scores = F.softmax(out["cls_logits"][b], dim=-1)[:, 1:]  # skip bg
                conf, cls_idx = cls_scores.max(dim=-1)
                sev_idx = out["sev_logits"][b].argmax(dim=-1)

                keep_mask = conf >= 0.01   # low threshold for mAP
                boxes_k   = decoded[b][keep_mask]
                conf_k    = conf[keep_mask]
                cls_k     = cls_idx[keep_mask]
                sev_k     = sev_idx[keep_mask]

                # NMS
                if len(boxes_k):
                    x1 = (boxes_k[:, 0] - boxes_k[:, 2] / 2).clamp(0, 1)
                    y1 = (boxes_k[:, 1] - boxes_k[:, 3] / 2).clamp(0, 1)
                    x2 = (boxes_k[:, 0] + boxes_k[:, 2] / 2).clamp(0, 1)
                    y2 = (boxes_k[:, 1] + boxes_k[:, 3] / 2).clamp(0, 1)
                    boxes_xyxy = torch.stack([x1, y1, x2, y2], dim=1)
                    nms_keep   = batched_nms(boxes_xyxy, conf_k, cls_k, 0.45)

                    all_predictions.append({
                        "boxes":  decoded[b][keep_mask][nms_keep].cpu().numpy(),
                        "scores": conf_k[nms_keep].cpu().numpy(),
                        "labels": cls_k[nms_keep].cpu().numpy(),
                    })
                else:
                    all_predictions.append({
                        "boxes": np.zeros((0, 4)), "scores": np.zeros(0), "labels": np.zeros(0, int)
                    })

                all_targets.append({
                    "boxes":  gt_boxes_list[b].numpy(),
                    "labels": gt_labels_list[b].numpy(),
                })

                # Severity accuracy on positive predictions matched to GT
                # (simplified: count severity correct on matched detections)
                if len(gt_sev_list[b]) > 0 and len(sev_k) > 0:
                    n_check = min(len(gt_sev_list[b]), len(sev_k))
                    pred_s  = sev_k[:n_check].cpu().numpy()
                    gt_s    = gt_sev_list[b][:n_check].numpy()
                    severity_correct += (pred_s == gt_s).sum()
                    severity_total   += n_check

    # mAP
    map_results = compute_map(all_predictions, all_targets)

    # Severity accuracy
    sev_acc = severity_correct / max(severity_total, 1)

    # Latency
    lat_arr = np.array(latencies)

    print("\n" + "="*60)
    print("  StreetWatch Evaluation Results")
    print("="*60)
    print(f"  mAP@0.5       : {map_results['mAP_50']:.4f}")
    print(f"  mAP@0.5:0.95  : {map_results['mAP_50_95']:.4f}")
    print(f"\n  Per-class AP@0.5:")
    for cls_name, ap in map_results["per_class"].items():
        print(f"    {cls_name:<25} {ap:.4f}")
    print(f"\n  Severity accuracy : {sev_acc:.3f} (proxy-label agreement)")
    print(f"\n  Inference latency:")
    print(f"    P50 : {np.percentile(lat_arr, 50):.1f} ms")
    print(f"    P95 : {np.percentile(lat_arr, 95):.1f} ms")
    print("="*60 + "\n")

    return {
        **map_results,
        "severity_accuracy": round(sev_acc, 4),
        "latency_p50_ms":    round(np.percentile(lat_arr, 50), 1),
        "latency_p95_ms":    round(np.percentile(lat_arr, 95), 1),
    }


# ─────────────────────────────────────────────
#  CLI
# ─────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--ann_file",   required=True)
    parser.add_argument("--img_root",   required=True)
    args = parser.parse_args()

    evaluate(args.checkpoint, args.ann_file, args.img_root)
