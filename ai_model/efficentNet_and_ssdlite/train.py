# data/dataset.py

import json
from pathlib import Path
import cv2
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader

from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.config import IMAGE_SIZE, Config


# ─────────────────────────────────────────────
#  DATASET
# ─────────────────────────────────────────────

class RDDDataset(Dataset):
    def __init__(self, ann_file, img_root, cfg, augment=False):
        self.img_root = Path(img_root)
        self.cfg = cfg
        self.augment = augment

        with open(ann_file) as f:
            coco = json.load(f)

        # ✅ FIX: proper mapping from COCO
        self.cat_id_to_idx = {
            cat["id"]: i for i, cat in enumerate(coco["categories"])
        }

        self.images = {img["id"]: img for img in coco["images"]}
        self.ann_by_image = {img_id: [] for img_id in self.images}

        for ann in coco["annotations"]:
            if ann["category_id"] in self.cat_id_to_idx:
                self.ann_by_image[ann["image_id"]].append(ann)

        self.img_ids = list(self.images.keys())
        print(f"[Dataset] Loaded {len(self.img_ids)} images")

    def __len__(self):
        return len(self.img_ids)

    def __getitem__(self, idx):
        img_id = self.img_ids[idx]
        info = self.images[img_id]
        path = self.img_root / info["file_name"]

        img = cv2.imread(str(path))
        if img is None:
            img = np.zeros((IMAGE_SIZE, IMAGE_SIZE, 3), np.uint8)

        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        h, w = img.shape[:2]

        boxes, labels, sev = [], [], []

        for ann in self.ann_by_image[img_id]:
            cls_idx = self.cat_id_to_idx.get(ann["category_id"])
            if cls_idx is None:
                continue

            x, y, bw, bh = ann["bbox"]

            if bw < 2 or bh < 2:
                continue

            # ✅ keep boxes
            boxes.append([x, y, bw, bh])
            labels.append(cls_idx)

            # ✅ FAST severity (no Sobel)
            area = (bw * bh) / (h * w)
            if area < 0.01:
                sev.append(0)
            elif area < 0.05:
                sev.append(1)
            else:
                sev.append(2)

        boxes = np.array(boxes, np.float32) if boxes else np.zeros((0, 4), np.float32)
        labels = np.array(labels, np.int64) if labels else np.zeros(0, np.int64)
        sev = np.array(sev, np.int64) if sev else np.zeros(0, np.int64)

        # ── Resize ─────────────────────────────
        img = cv2.resize(img, (IMAGE_SIZE, IMAGE_SIZE))

        if len(boxes):
            sx, sy = IMAGE_SIZE / w, IMAGE_SIZE / h
            boxes[:, 0] *= sx
            boxes[:, 1] *= sy
            boxes[:, 2] *= sx
            boxes[:, 3] *= sy

            cx = (boxes[:, 0] + boxes[:, 2] / 2) / IMAGE_SIZE
            cy = (boxes[:, 1] + boxes[:, 3] / 2) / IMAGE_SIZE
            nw = boxes[:, 2] / IMAGE_SIZE
            nh = boxes[:, 3] / IMAGE_SIZE

            boxes = np.stack([cx, cy, nw, nh], axis=1)

        # ── Tensor ─────────────────────────────
        img = torch.from_numpy(img.astype(np.float32) / 255.0).permute(2, 0, 1)

        boxes = torch.from_numpy(boxes).float()
        labels = torch.from_numpy(labels).long()
        sev = torch.from_numpy(sev).long()

        return img, boxes, labels, sev


# ─────────────────────────────────────────────
#  COLLATE
# ─────────────────────────────────────────────

def collate_fn(batch):
    images, boxes, labels, sev = zip(*batch)
    return torch.stack(images), list(boxes), list(labels), list(sev)


# ─────────────────────────────────────────────
#  DATALOADER
# ─────────────────────────────────────────────

def build_dataloaders(cfg: Config):
    tcfg = cfg.training
    dcfg = cfg.data

    train_ds = RDDDataset(dcfg.train_json, dcfg.train_images, tcfg, augment=False)
    val_ds = RDDDataset(dcfg.val_json, dcfg.val_images, tcfg, augment=False)

    train_loader = DataLoader(
        train_ds,
        batch_size=tcfg.batch_size,
        shuffle=True,
        num_workers=4,
        pin_memory=True,
        persistent_workers=True,
        collate_fn=collate_fn,
        drop_last=True,
    )

    val_loader = DataLoader(
        val_ds,
        batch_size=tcfg.batch_size,
        shuffle=False,
        num_workers=4,
        pin_memory=True,
        persistent_workers=True,
        collate_fn=collate_fn,
    )

    return train_loader, val_loader