"""
StreetWatch AI — RDD2022 Data Preparation
==========================================
Downloads RDD2022 and converts to COCO JSON format.

The dataset is available on Roboflow (free) which handles
the COCO conversion automatically, or via IEEE DataPort.

Usage:
  python data/prepare_rdd2022.py --output_dir data/rdd2022

Roboflow option (recommended, fastest):
  1. Go to: https://universe.roboflow.com/search?q=RDD2022
  2. Export as COCO format
  3. Place under data/rdd2022/
  
Manual option (full dataset):
  1. Download from: https://github.com/sekilab/RoadDamageDetector
  2. Run this script to convert XML annotations → COCO JSON
"""

import argparse
import json
import os
import random
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List


# RDD2022 XML label → COCO category name
XML_LABEL_MAP = {
    "D00": "D00",   # longitudinal crack
    "D10": "D10",   # transverse crack
    "D20": "D20",   # alligator crack
    "D40": "D40",   # pothole
}

CATEGORIES = [
    {"id": 1, "name": "D00", "supercategory": "road_damage"},
    {"id": 2, "name": "D10", "supercategory": "road_damage"},
    {"id": 3, "name": "D20", "supercategory": "road_damage"},
    {"id": 4, "name": "D40", "supercategory": "road_damage"},
]

LABEL_TO_CAT_ID = {"D00": 1, "D10": 2, "D20": 3, "D40": 4}


def parse_rdd_xml(xml_path: str) -> List[Dict]:
    """Parse a single RDD2022 XML annotation file."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
    except Exception:
        return []

    annotations = []
    for obj in root.findall("object"):
        name = obj.find("name")
        if name is None or name.text not in LABEL_TO_CAT_ID:
            continue

        bndbox = obj.find("bndbox")
        if bndbox is None:
            continue

        try:
            xmin = float(bndbox.find("xmin").text)
            ymin = float(bndbox.find("ymin").text)
            xmax = float(bndbox.find("xmax").text)
            ymax = float(bndbox.find("ymax").text)
        except (AttributeError, ValueError):
            continue

        w = xmax - xmin
        h = ymax - ymin
        if w <= 0 or h <= 0:
            continue

        annotations.append({
            "category_name": name.text,
            "bbox": [xmin, ymin, w, h],
            "area": w * h,
        })

    return annotations


def convert_to_coco(
    image_dir: str,
    ann_dir: str,
    output_json: str,
) -> Dict:
    """
    Convert a directory of images + XML annotations to COCO JSON.

    Expected structure:
        image_dir/
            image_000001.jpg
            image_000002.jpg
            ...
        ann_dir/
            image_000001.xml
            image_000002.xml
            ...
    """
    image_dir = Path(image_dir)
    ann_dir   = Path(ann_dir)

    image_extensions = {".jpg", ".jpeg", ".png", ".bmp"}
    image_paths = sorted([
        p for p in image_dir.iterdir()
        if p.suffix.lower() in image_extensions
    ])

    coco = {
        "info":        {"description": "RDD2022 converted to COCO format"},
        "categories":  CATEGORIES,
        "images":      [],
        "annotations": [],
    }

    ann_id = 1

    for img_id, img_path in enumerate(image_paths, start=1):
        # Get image dimensions
        try:
            import cv2
            img = cv2.imread(str(img_path))
            if img is None:
                continue
            h, w = img.shape[:2]
        except Exception:
            continue

        coco["images"].append({
            "id":        img_id,
            "file_name": img_path.name,
            "width":     w,
            "height":    h,
        })

        # Find corresponding XML
        xml_path = ann_dir / (img_path.stem + ".xml")
        if not xml_path.exists():
            continue

        for ann in parse_rdd_xml(str(xml_path)):
            cat_id = LABEL_TO_CAT_ID[ann["category_name"]]
            coco["annotations"].append({
                "id":           ann_id,
                "image_id":     img_id,
                "category_id":  cat_id,
                "bbox":         ann["bbox"],
                "area":         ann["area"],
                "iscrowd":      0,
            })
            ann_id += 1

    Path(output_json).parent.mkdir(parents=True, exist_ok=True)
    with open(output_json, "w") as f:
        json.dump(coco, f, indent=2)

    print(f"[DataPrep] Saved {len(coco['images'])} images, "
          f"{len(coco['annotations'])} annotations → {output_json}")
    return coco


def split_coco_annotations(
    coco_json: str,
    output_dir: str,
    train_ratio: float = 0.80,
    val_ratio:   float = 0.10,
    seed:        int   = 42,
):
    """
    Split a single COCO JSON into train / val / test splits.
    Saves three JSON files to output_dir/annotations/.
    """
    with open(coco_json) as f:
        coco = json.load(f)

    random.seed(seed)
    img_ids = [img["id"] for img in coco["images"]]
    random.shuffle(img_ids)

    n = len(img_ids)
    n_train = int(n * train_ratio)
    n_val   = int(n * val_ratio)

    splits = {
        "train": set(img_ids[:n_train]),
        "val":   set(img_ids[n_train:n_train + n_val]),
        "test":  set(img_ids[n_train + n_val:]),
    }

    out_dir = Path(output_dir) / "annotations"
    out_dir.mkdir(parents=True, exist_ok=True)

    id_to_image = {img["id"]: img for img in coco["images"]}

    for split_name, split_ids in splits.items():
        split_images = [id_to_image[i] for i in split_ids]
        split_anns   = [a for a in coco["annotations"] if a["image_id"] in split_ids]

        split_coco = {
            "info":        coco.get("info", {}),
            "categories":  coco["categories"],
            "images":      split_images,
            "annotations": split_anns,
        }

        out_path = out_dir / f"{split_name}.json"
        with open(out_path, "w") as f:
            json.dump(split_coco, f, indent=2)

        print(f"[DataPrep] {split_name:5s}: {len(split_images):5d} images, "
              f"{len(split_anns):6d} annotations → {out_path}")

    # Calibration subset (200 images from val, for INT8 quantisation)
    calib_ids = list(splits["val"])[:200]
    calib_dir = Path(output_dir) / "calibration"
    calib_dir.mkdir(exist_ok=True)

    # Copy calibration images
    img_dir = Path(coco_json).parent / "images"
    if img_dir.exists():
        for img_id in calib_ids:
            img_info = id_to_image[img_id]
            src = img_dir / img_info["file_name"]
            if src.exists():
                shutil.copy(src, calib_dir / img_info["file_name"])
        print(f"[DataPrep] Calibration images copied: {calib_dir}")


def print_dataset_statistics(ann_json: str):
    """Print class distribution of a COCO annotation file."""
    with open(ann_json) as f:
        coco = json.load(f)

    cat_id_to_name = {c["id"]: c["name"] for c in coco["categories"]}
    counts = {}
    for ann in coco["annotations"]:
        name = cat_id_to_name.get(ann["category_id"], "unknown")
        counts[name] = counts.get(name, 0) + 1

    total = sum(counts.values())
    print(f"\n[Stats] {Path(ann_json).name}: {len(coco['images'])} images, "
          f"{total} annotations")
    for name, count in sorted(counts.items()):
        pct = 100 * count / max(total, 1)
        print(f"  {name:<25} {count:6d}  ({pct:.1f}%)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prepare RDD2022 dataset")
    parser.add_argument("--image_dir",   required=True, help="Directory of images")
    parser.add_argument("--ann_dir",     required=True, help="Directory of XML annotations")
    parser.add_argument("--output_dir",  default="data/rdd2022")
    args = parser.parse_args()

    # 1. Convert XML → COCO
    all_json = str(Path(args.output_dir) / "all_annotations.json")
    convert_to_coco(args.image_dir, args.ann_dir, all_json)

    # 2. Split into train/val/test
    split_coco_annotations(all_json, args.output_dir)

    # 3. Print stats
    for split in ["train", "val", "test"]:
        split_json = str(Path(args.output_dir) / "annotations" / f"{split}.json")
        if Path(split_json).exists():
            print_dataset_statistics(split_json)
