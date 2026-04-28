"""
StreetWatch AI — Dataset & Proxy Severity Labels
=================================================
Loads RDD2022 in COCO format and computes severity proxy labels
on-the-fly using bounding-box area ratio + Sobel edge density.

No severity annotations required.
"""

import os
import json
import random
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import cv2
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader

from config import (
    DAMAGE_CLASSES, IMAGE_SIZE,
    SEVERITY_AREA_WEIGHT, SEVERITY_EDGE_WEIGHT,
    SEVERITY_LOW_THRESHOLD, SEVERITY_HIGH_THRESHOLD,
    AREA_SCALE, EDGE_SCALE, Config,
)


# ─────────────────────────────────────────────
#  SEVERITY PROXY LABEL
# ─────────────────────────────────────────────

def compute_edge_density(crop: np.ndarray) -> float:
    """
    Sobel edge density inside a damage crop.
    Returns a value in [0, 1] (normalised by 255).

    High edge density → rough/complex damage texture → higher severity.
    """
    if crop.size == 0:
        return 0.0
    gray = cv2.cvtColor(crop, cv2.COLOR_RGB2GRAY) if crop.ndim == 3 else crop
    if gray.shape[0] < 16 or gray.shape[1] < 16:
        gray = cv2.resize(gray, (16, 16))
    sx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
    sy = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
    magnitude = np.sqrt(sx ** 2 + sy ** 2)
    return float(magnitude.mean() / 255.0)


def compute_severity_label(
    bbox_xywh: Tuple[float, float, float, float],
    image_hw: Tuple[int, int],
    img_crop: Optional[np.ndarray] = None,
) -> int:
    """
    Proxy severity label: 0=low, 1=medium, 2=high.

    score = 0.6 * clamp(area_ratio * AREA_SCALE)
          + 0.4 * clamp(edge_density * EDGE_SCALE)
    """
    _, _, bw, bh = bbox_xywh
    ih, iw = image_hw
    area_ratio = (bw * bh) / max(ih * iw, 1)

    area_signal = min(area_ratio * AREA_SCALE, 1.0)

    if img_crop is not None and img_crop.size > 0:
        edge_signal = min(compute_edge_density(img_crop) * EDGE_SCALE, 1.0)
    else:
        edge_signal = 0.0

    score = SEVERITY_AREA_WEIGHT * area_signal + SEVERITY_EDGE_WEIGHT * edge_signal

    if score < SEVERITY_LOW_THRESHOLD:
        return 0   # low
    elif score < SEVERITY_HIGH_THRESHOLD:
        return 1   # medium
    else:
        return 2   # high


# ─────────────────────────────────────────────
#  COCO → INTERNAL FORMAT
# ─────────────────────────────────────────────

RDD_CAT_MAP: Dict[str, int] = {
    "D00": 0,   # longitudinal_crack
    "D10": 1,   # transverse_crack
    "D20": 2,   # alligator_crack
    "D40": 3,   # pothole
}

FULL_NAME_MAP: Dict[str, int] = {v: i for i, v in enumerate(DAMAGE_CLASSES)}


def _rdd_cat_to_idx(cat_name: str) -> Optional[int]:
    cat_name = cat_name.strip()
    if cat_name in RDD_CAT_MAP:
        return RDD_CAT_MAP[cat_name]
    if cat_name in FULL_NAME_MAP:
        return FULL_NAME_MAP[cat_name]
    return None


# ─────────────────────────────────────────────
#  AUGMENTATION
# ─────────────────────────────────────────────

class Augmenter:
    def __init__(self, cfg):
        self.cfg = cfg

    @staticmethod
    def _clip_boxes(boxes: np.ndarray, h: int, w: int):
        x1 = np.clip(boxes[:, 0], 0, w)
        y1 = np.clip(boxes[:, 1], 0, h)
        x2 = np.clip(boxes[:, 0] + boxes[:, 2], 0, w)
        y2 = np.clip(boxes[:, 1] + boxes[:, 3], 0, h)
        bw = x2 - x1
        bh = y2 - y1
        mask = (bw > 2) & (bh > 2)
        return np.stack([x1, y1, bw, bh], axis=1)[mask], mask

    def _horizontal_flip(self, img, boxes):
        h, w = img.shape[:2]
        img = img[:, ::-1].copy()
        if len(boxes):
            boxes = boxes.copy()
            boxes[:, 0] = w - boxes[:, 0] - boxes[:, 2]
        return img, boxes

    def _color_jitter(self, img):
        img = img.astype(np.float32)
        alpha = random.uniform(0.6, 1.4)
        img = np.clip(img * alpha, 0, 255)
        mean = img.mean()
        beta = random.uniform(0.7, 1.3)
        img = np.clip((img - mean) * beta + mean, 0, 255)
        img_u8 = img.astype(np.uint8)
        hsv = cv2.cvtColor(img_u8, cv2.COLOR_RGB2HSV).astype(np.float32)
        hsv[:, :, 1] = np.clip(hsv[:, :, 1] * random.uniform(0.7, 1.3), 0, 255)
        return cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2RGB)

    def _motion_blur(self, img):
        ksize = random.choice([3, 5, 7])
        kernel = np.zeros((ksize, ksize))
        if random.random() > 0.5:
            kernel[ksize // 2, :] = 1.0 / ksize
        else:
            kernel[:, ksize // 2] = 1.0 / ksize
        return cv2.filter2D(img, -1, kernel)

    def _perspective_transform(self, img, boxes):
        h, w = img.shape[:2]
        margin = 0.08
        src = np.float32([[0, 0], [w, 0], [w, h], [0, h]])
        def jitter(v, limit): return v + random.uniform(-limit, limit)
        dst = np.float32([
            [jitter(0, w * margin), jitter(0, h * margin)],
            [jitter(w, w * margin), jitter(0, h * margin)],
            [jitter(w, w * margin), jitter(h, h * margin)],
            [jitter(0, w * margin), jitter(h, h * margin)],
        ])
        M = cv2.getPerspectiveTransform(src, dst)
        img = cv2.warpPerspective(img, M, (w, h), borderMode=cv2.BORDER_REPLICATE)
        if len(boxes):
            new_boxes = []
            for box in boxes:
                x, y, bw, bh = box
                corners = np.float32([[x,y],[x+bw,y],[x+bw,y+bh],[x,y+bh]])
                corners = cv2.perspectiveTransform(corners.reshape(-1,1,2), M).reshape(-1,2)
                nx, ny = corners[:,0].min(), corners[:,1].min()
                nw = corners[:,0].max() - nx
                nh = corners[:,1].max() - ny
                new_boxes.append([nx, ny, nw, nh])
            boxes = np.array(new_boxes, dtype=np.float32)
            boxes, _ = self._clip_boxes(boxes, h, w)
        return img, boxes

    def _mosaic(self, img, boxes, labels, sev_labels, dataset: "RDDDataset"):
        h, w = img.shape[:2]
        cx, cy = w // 2, h // 2
        canvas = np.zeros((h, w, 3), dtype=np.uint8)
        all_boxes, all_labels, all_sev = [], [], []

        images_data = [(img, boxes, labels, sev_labels)]
        for _ in range(3):
            idx = random.randint(0, len(dataset) - 1)
            images_data.append(dataset._load_raw(idx))

        quads = [(0, 0, cx, cy), (cx, 0, w, cy), (0, cy, cx, h), (cx, cy, w, h)]
        for i, (qx1, qy1, qx2, qy2) in enumerate(quads):
            qi, qb, ql, qs = images_data[i]
            qh, qw = qy2 - qy1, qx2 - qx1
            canvas[qy1:qy2, qx1:qx2] = cv2.resize(qi, (qw, qh))
            if len(qb):
                scale_x, scale_y = qw / qi.shape[1], qh / qi.shape[0]
                b = qb.copy().astype(np.float32)
                b[:, 0] = b[:, 0] * scale_x + qx1
                b[:, 1] = b[:, 1] * scale_y + qy1
                b[:, 2] *= scale_x
                b[:, 3] *= scale_y
                b, mask = self._clip_boxes(b, h, w)
                if len(b):
                    all_boxes.append(b)
                    all_labels.append(ql[mask])
                    all_sev.append(qs[mask])

        boxes_out = np.concatenate(all_boxes) if all_boxes else np.zeros((0, 4), np.float32)
        labels_out = np.concatenate(all_labels) if all_labels else np.zeros(0, np.int64)
        sev_out = np.concatenate(all_sev) if all_sev else np.zeros(0, np.int64)
        return canvas, boxes_out, labels_out, sev_out

    def __call__(self, img, boxes, labels, sev_labels, dataset=None):
        if dataset is not None and random.random() < self.cfg.aug_mosaic_prob:
            img, boxes, labels, sev_labels = self._mosaic(img, boxes, labels, sev_labels, dataset)
        if random.random() < self.cfg.aug_flip_prob:
            img, boxes = self._horizontal_flip(img, boxes)
        if random.random() < self.cfg.aug_perspective_prob and len(boxes):
            img, boxes = self._perspective_transform(img, boxes)
        img = self._color_jitter(img)
        if random.random() < self.cfg.aug_blur_prob:
            img = self._motion_blur(img)
        return img, boxes, labels, sev_labels


# ─────────────────────────────────────────────
#  DATASET
# ─────────────────────────────────────────────

class RDDDataset(Dataset):
    """
    RDD2022 in COCO format.

    Returns per sample:
        image     : FloatTensor [3, H, W] in [0, 1]
        boxes     : FloatTensor [N, 4]  normalised (cx, cy, w, h)
        class_ids : LongTensor  [N]
        sev_ids   : LongTensor  [N]  — 0/1/2 proxy labels
    """

    def __init__(self, ann_file: str, img_root: str, cfg, augment: bool = False):
        super().__init__()
        self.img_root = Path(img_root)
        self.cfg = cfg
        self.augment = augment
        self.augmenter = Augmenter(cfg) if augment else None

        with open(ann_file) as f:
            coco = json.load(f)

        self.cat_id_to_idx: Dict[int, int] = {}
        for cat in coco.get("categories", []):
            idx = _rdd_cat_to_idx(cat["name"])
            if idx is not None:
                self.cat_id_to_idx[cat["id"]] = idx

        self.images = {img["id"]: img for img in coco["images"]}
        self.ann_by_image: Dict[int, List[dict]] = {img_id: [] for img_id in self.images}

        for ann in coco.get("annotations", []):
            img_id = ann["image_id"]
            if img_id in self.ann_by_image and ann["category_id"] in self.cat_id_to_idx:
                self.ann_by_image[img_id].append(ann)

        self.img_ids: List[int] = list(self.images.keys())
        print(f"[Dataset] Loaded {len(self.img_ids)} images from {ann_file}")

    def __len__(self):
        return len(self.img_ids)

    def _load_raw(self, idx: int):
        img_id = self.img_ids[idx]
        img_info = self.images[img_id]
        img_path = self.img_root / img_info["file_name"]

        img = cv2.imread(str(img_path))
        if img is None:
            img = np.zeros((IMAGE_SIZE, IMAGE_SIZE, 3), np.uint8)
            return img, np.zeros((0,4), np.float32), np.zeros(0, np.int64), np.zeros(0, np.int64)

        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        orig_h, orig_w = img.shape[:2]
        anns = self.ann_by_image[img_id]
        boxes, cls_ids, sev_ids = [], [], []

        for ann in anns:
            cls_idx = self.cat_id_to_idx.get(ann["category_id"])
            if cls_idx is None:
                continue
            x, y, bw, bh = ann["bbox"]
            if bw < 2 or bh < 2:
                continue
            x1, y1 = max(0, int(x)), max(0, int(y))
            x2, y2 = min(orig_w, int(x+bw)), min(orig_h, int(y+bh))
            crop = img[y1:y2, x1:x2]
            sev = compute_severity_label((x, y, bw, bh), (orig_h, orig_w), crop)
            boxes.append([x, y, bw, bh])
            cls_ids.append(cls_idx)
            sev_ids.append(sev)

        boxes_arr = np.array(boxes, np.float32)  if boxes   else np.zeros((0,4), np.float32)
        cls_arr   = np.array(cls_ids, np.int64)  if cls_ids else np.zeros(0, np.int64)
        sev_arr   = np.array(sev_ids, np.int64)  if sev_ids else np.zeros(0, np.int64)
        return img, boxes_arr, cls_arr, sev_arr

    def __getitem__(self, idx: int):
        img, boxes, cls_ids, sev_ids = self._load_raw(idx)

        if self.augment and self.augmenter is not None:
            img, boxes, cls_ids, sev_ids = self.augmenter(
                img, boxes, cls_ids, sev_ids, dataset=self)

        orig_h, orig_w = img.shape[:2]
        img = cv2.resize(img, (IMAGE_SIZE, IMAGE_SIZE))

        if len(boxes):
            sx, sy = IMAGE_SIZE / orig_w, IMAGE_SIZE / orig_h
            boxes[:, 0] *= sx;  boxes[:, 1] *= sy
            boxes[:, 2] *= sx;  boxes[:, 3] *= sy
            cx = (boxes[:, 0] + boxes[:, 2] / 2) / IMAGE_SIZE
            cy = (boxes[:, 1] + boxes[:, 3] / 2) / IMAGE_SIZE
            nw = boxes[:, 2] / IMAGE_SIZE
            nh = boxes[:, 3] / IMAGE_SIZE
            boxes = np.stack([cx, cy, nw, nh], axis=1)

        img_t  = torch.from_numpy(img.astype(np.float32) / 255.0).permute(2, 0, 1)
        boxes_t = torch.from_numpy(boxes).float()  if len(boxes)   else torch.zeros(0, 4)
        cls_t   = torch.from_numpy(cls_ids).long() if len(cls_ids) else torch.zeros(0, dtype=torch.long)
        sev_t   = torch.from_numpy(sev_ids).long() if len(sev_ids) else torch.zeros(0, dtype=torch.long)
        return img_t, boxes_t, cls_t, sev_t


# ─────────────────────────────────────────────
#  COLLATE + DATALOADERS
# ─────────────────────────────────────────────

def collate_fn(batch):
    images, boxes, cls_ids, sev_ids = zip(*batch)
    return torch.stack(images, dim=0), list(boxes), list(cls_ids), list(sev_ids)


def build_dataloaders(cfg: Config):
    tcfg = cfg.training
    dcfg = cfg.data
    train_ds = RDDDataset(dcfg.train_json, dcfg.train_images, tcfg, augment=True)
    val_ds = RDDDataset(dcfg.val_json, dcfg.val_images, tcfg, augment=False)
    train_loader = DataLoader(train_ds, batch_size=tcfg.batch_size, shuffle=True,
                              num_workers=tcfg.num_workers, pin_memory=tcfg.pin_memory,
                              collate_fn=collate_fn, drop_last=True)
    val_loader = DataLoader(val_ds, batch_size=tcfg.batch_size, shuffle=False,
                              num_workers=tcfg.num_workers, pin_memory=tcfg.pin_memory,
                              collate_fn=collate_fn)
    return train_loader, val_loader
