import os
import json
import shutil
import cv2
from pathlib import Path
from tqdm import tqdm

# YOLO Class ID -> RDD Category Name
# Standard RDD2022 YOLO mapping: 0:D00, 1:D10, 2:D20, 3:D40
ID_TO_CAT = {0: "D00", 1: "D10", 2: "D20", 3: "D40"}
CATEGORIES = [
    {"id": 1, "name": "D00", "supercategory": "road_damage"},
    {"id": 2, "name": "D10", "supercategory": "road_damage"},
    {"id": 3, "name": "D20", "supercategory": "road_damage"},
    {"id": 4, "name": "D40", "supercategory": "road_damage"},
]

def yolo_to_coco_box(yolo_box, img_w, img_h):
    """Convert YOLO (xc, yc, w, h) normalized to COCO (x, y, w, h) absolute."""
    xc, yc, w, h = yolo_box
    abs_w = w * img_w
    abs_h = h * img_h
    abs_x = (xc * img_w) - (abs_w / 2)
    abs_y = (yc * img_h) - (abs_h / 2)
    return [abs_x, abs_y, abs_w, abs_h]

def process_split(split_name, input_root, output_root):
    img_dir = Path(input_root) / split_name / "images"
    lbl_dir = Path(input_root) / split_name / "labels"
    
    out_img_dir = Path(output_root) / "images" / split_name
    out_ann_dir = Path(output_root) / "annotations"
    out_img_dir.mkdir(parents=True, exist_ok=True)
    out_ann_dir.mkdir(parents=True, exist_ok=True)

    coco = {
        "info": {"description": f"RDD2022 {split_name} converted from YOLO"},
        "categories": CATEGORIES,
        "images": [],
        "annotations": []
    }

    ann_id = 1
    image_paths = list(img_dir.glob("*.jpg")) + list(img_dir.glob("*.png")) + list(img_dir.glob("*.jpeg"))
    
    print(f"Processing {split_name} split...")
    for img_id, img_path in enumerate(tqdm(image_paths), start=1):
        # Load image to get dimensions
        img = cv2.imread(str(img_path))
        if img is None: continue
        h, w = img.shape[:2]

        # Copy image to project data folder
        shutil.copy(img_path, out_img_dir / img_path.name)

        coco["images"].append({
            "id": img_id,
            "file_name": img_path.name,
            "width": w,
            "height": h
        })

        # Process labels
        lbl_path = lbl_dir / (img_path.stem + ".txt")
        if lbl_path.exists():
            with open(lbl_path, 'r') as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) != 5: continue
                    
                    cls_id = int(parts[0])
                    # COCO IDs usually start at 1
                    cat_id = cls_id + 1 
                    
                    yolo_box = [float(x) for x in parts[1:]]
                    coco_box = yolo_to_coco_box(yolo_box, w, h)

                    coco["annotations"].append({
                        "id": ann_id,
                        "image_id": img_id,
                        "category_id": cat_id,
                        "bbox": coco_box,
                        "area": coco_box[2] * coco_box[3],
                        "iscrowd": 0
                    })
                    ann_id += 1

    output_json = out_ann_dir / f"instances_{split_name}.json"
    with open(output_json, 'w') as f:
        json.dump(coco, f, indent=2)
    print(f"Saved {output_json}")

if __name__ == "__main__":
    INPUT_FOLDER = "data/RDD_SPLIT"
    OUTPUT_FOLDER = "data/rdd2022"
    
    for split in ["train", "val", "test"]:
        if os.path.exists(os.path.join(INPUT_FOLDER, split)):
            process_split(split, INPUT_FOLDER, OUTPUT_FOLDER)
            
    # Create calibration folder (optional, used for model compression later)
    calib_dir = Path(OUTPUT_FOLDER) / "calibration"
    calib_dir.mkdir(exist_ok=True)
    val_imgs = list((Path(OUTPUT_FOLDER) / "images/val").glob("*.jpg"))[:200]
    for img in val_imgs:
        shutil.copy(img, calib_dir / img.name)
    print(f"Copied {len(val_imgs)} images to calibration folder.")
