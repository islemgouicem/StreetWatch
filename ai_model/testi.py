import json
import os
from PIL import Image
import numpy as np

# Create folders
os.makedirs("data/dummy_test/images/train", exist_ok=True)
os.makedirs("data/dummy_test/images/val", exist_ok=True)
os.makedirs("data/dummy_test/annotations", exist_ok=True)

# Create 4 dummy images (train) and 2 (val) — just noise
def create_dummy_image(path):
    img = Image.fromarray(np.uint8(np.random.rand(512, 512, 3) * 255))
    img.save(path)

for i in range(4):
    create_dummy_image(f"data/dummy_test/images/train/img_{i}.jpg")
for i in range(2):
    create_dummy_image(f"data/dummy_test/images/val/img_{i}.jpg")

# Create minimal COCO annotations
def make_coco_json(num_images):
    return {
        "images": [
            {"id": i, "file_name": f"img_{i}.jpg", "height": 512, "width": 512}
            for i in range(num_images)
        ],
        "annotations": [
            {
                "id": j,
                "image_id": i,
                "category_id": i % 4,  # cycle through 4 damage classes
                "bbox": [50, 50, 100, 100],  # [x, y, w, h]
                "area": 10000,
                "iscrowd": 0
            }
            for i in range(num_images)
            for j in range(2)  # 2 damage instances per image
        ],
        "categories": [
            {"id": 0, "name": "pothole"},
            {"id": 1, "name": "longitudinal_crack"},
            {"id": 2, "name": "transverse_crack"},
            {"id": 3, "name": "alligator_crack"}
        ]
    }

with open("data/dummy_test/annotations/instances_train.json", "w") as f:
    json.dump(make_coco_json(4), f)

with open("data/dummy_test/annotations/instances_val.json", "w") as f:
    json.dump(make_coco_json(2), f)

print("✓ Dummy dataset created")