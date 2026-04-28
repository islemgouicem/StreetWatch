from typing import List, Tuple

import torch


def cxcywh_to_xyxy(boxes: torch.Tensor) -> torch.Tensor:
    cx, cy, w, h = boxes.unbind(-1)
    x1 = cx - 0.5 * w
    y1 = cy - 0.5 * h
    x2 = cx + 0.5 * w
    y2 = cy + 0.5 * h
    return torch.stack([x1, y1, x2, y2], dim=-1)


def xyxy_to_cxcywh(boxes: torch.Tensor) -> torch.Tensor:
    x1, y1, x2, y2 = boxes.unbind(-1)
    w = (x2 - x1).clamp(min=1e-6)
    h = (y2 - y1).clamp(min=1e-6)
    cx = x1 + 0.5 * w
    cy = y1 + 0.5 * h
    return torch.stack([cx, cy, w, h], dim=-1)


def box_iou(boxes1: torch.Tensor, boxes2: torch.Tensor) -> torch.Tensor:
    if boxes1.numel() == 0 or boxes2.numel() == 0:
        return boxes1.new_zeros((boxes1.shape[0], boxes2.shape[0]))
    b1 = cxcywh_to_xyxy(boxes1)
    b2 = cxcywh_to_xyxy(boxes2)
    lt = torch.maximum(b1[:, None, :2], b2[None, :, :2])
    rb = torch.minimum(b1[:, None, 2:], b2[None, :, 2:])
    wh = (rb - lt).clamp(min=0)
    inter = wh[..., 0] * wh[..., 1]
    a1 = (b1[:, 2] - b1[:, 0]).clamp(min=0) * (b1[:, 3] - b1[:, 1]).clamp(min=0)
    a2 = (b2[:, 2] - b2[:, 0]).clamp(min=0) * (b2[:, 3] - b2[:, 1]).clamp(min=0)
    union = a1[:, None] + a2[None, :] - inter
    return inter / union.clamp(min=1e-6)


def encode_boxes(gt_boxes: torch.Tensor, anchors: torch.Tensor, variance: Tuple[float, float]) -> torch.Tensor:
    v0, v1 = variance
    g_cxcy = (gt_boxes[:, :2] - anchors[:, :2]) / (anchors[:, 2:] * v0)
    g_wh = torch.log((gt_boxes[:, 2:] / anchors[:, 2:]).clamp(min=1e-6)) / v1
    return torch.cat([g_cxcy, g_wh], dim=1)


def decode_boxes(pred_deltas: torch.Tensor, anchors: torch.Tensor, variance: Tuple[float, float]) -> torch.Tensor:
    v0, v1 = variance
    cxcy = pred_deltas[..., :2] * anchors[..., 2:] * v0 + anchors[..., :2]
    wh = torch.exp(pred_deltas[..., 2:] * v1) * anchors[..., 2:]
    return torch.cat([cxcy, wh], dim=-1)


def match_anchors_to_targets(
    anchors: torch.Tensor,
    gt_boxes: torch.Tensor,
    gt_labels: torch.Tensor,
    gt_severity: torch.Tensor,
    iou_threshold: float,
    variance: Tuple[float, float],
    num_classes: int,
) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    num_anchors = anchors.shape[0]
    encoded_targets = anchors.new_zeros((num_anchors, 4))
    cls_targets = torch.zeros((num_anchors,), dtype=torch.long, device=anchors.device)
    sev_targets = torch.full((num_anchors,), -1, dtype=torch.long, device=anchors.device)
    pos_mask = torch.zeros((num_anchors,), dtype=torch.bool, device=anchors.device)

    if gt_boxes.numel() == 0:
        return encoded_targets, cls_targets, sev_targets, pos_mask

    ious = box_iou(anchors, gt_boxes)
    best_gt_iou, best_gt_idx = ious.max(dim=1)
    best_anchor_iou, best_anchor_idx = ious.max(dim=0)
    best_gt_idx[best_anchor_idx] = torch.arange(gt_boxes.shape[0], device=anchors.device)
    best_gt_iou[best_anchor_idx] = 1.0

    pos_mask = best_gt_iou >= iou_threshold
    matched_gt = gt_boxes[best_gt_idx]
    encoded_targets[pos_mask] = encode_boxes(matched_gt[pos_mask], anchors[pos_mask], variance)

    # +1 because class 0 is reserved for background.
    cls_targets[pos_mask] = gt_labels[best_gt_idx[pos_mask]].clamp(min=0, max=num_classes - 1) + 1
    sev_targets[pos_mask] = gt_severity[best_gt_idx[pos_mask]].clamp(min=0, max=2)
    return encoded_targets, cls_targets, sev_targets, pos_mask


def match_batch(
    anchors: torch.Tensor,
    gt_boxes_list: List[torch.Tensor],
    gt_labels_list: List[torch.Tensor],
    gt_severity_list: List[torch.Tensor],
    iou_threshold: float,
    variance: Tuple[float, float],
    num_classes: int,
) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    bsz = len(gt_boxes_list)
    num_anchors = anchors.shape[0]
    bbox_t = anchors.new_zeros((bsz, num_anchors, 4))
    cls_t = torch.zeros((bsz, num_anchors), dtype=torch.long, device=anchors.device)
    sev_t = torch.full((bsz, num_anchors), -1, dtype=torch.long, device=anchors.device)
    pos_mask = torch.zeros((bsz, num_anchors), dtype=torch.bool, device=anchors.device)

    for i in range(bsz):
        bt, ct, st, pm = match_anchors_to_targets(
            anchors=anchors,
            gt_boxes=gt_boxes_list[i].to(anchors.device),
            gt_labels=gt_labels_list[i].to(anchors.device),
            gt_severity=gt_severity_list[i].to(anchors.device),
            iou_threshold=iou_threshold,
            variance=variance,
            num_classes=num_classes,
        )
        bbox_t[i] = bt
        cls_t[i] = ct
        sev_t[i] = st
        pos_mask[i] = pm
    return bbox_t, cls_t, sev_t, pos_mask
