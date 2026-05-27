import sys
import subprocess
import os

# Install specific YOLOv12 version
subprocess.check_call([
    sys.executable, "-m", "pip", "install", 
    "git+https://github.com/sunsmarterjie/yolov12.git@3bca22b336e96cfdabfec4c062b84eef210e9563",
    "-q", "--no-deps"
])

# Install other dependencies
subprocess.check_call([
    sys.executable, "-m", "pip", "install",
    "ultralytics-thop>=2.0.0", "-q"
])

from typing import Dict, List, Any
import base64
import io
from PIL import Image


class EndpointHandler:
    def __init__(self, path: str = ""):
        """Initialize the handler with the model path."""
        # Import after installing the correct version
        from ultralytics import YOLO
        
        model_file = f"{path}/yolo12s_RDD2022_best.pt"
        print(f"Loading model from: {model_file}")
        self.model = YOLO(model_file)
        self.class_names = self.model.names
        print(f"Model loaded with classes: {self.class_names}")
        
    def __call__(self, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Process inference request."""
        inputs = data.get("inputs", data.get("image", ""))
        parameters = data.get("parameters", {})
        conf_threshold = parameters.get("confidence", 0.25)
        
        # Decode image
        if isinstance(inputs, str):
            if inputs.startswith("http"):
                image = inputs
            else:
                image_bytes = base64.b64decode(inputs)
                image = Image.open(io.BytesIO(image_bytes))
        elif isinstance(inputs, bytes):
            image = Image.open(io.BytesIO(inputs))
        else:
            image = inputs
            
        # Run inference
        results = self.model(image, conf=conf_threshold, verbose=False)
        
        # Format results
        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                conf = float(box.conf[0])
                cls = int(box.cls[0])
                
                detections.append({
                    "label": self.class_names[cls],
                    "score": round(conf, 4),
                    "box": {
                        "xmin": int(x1),
                        "ymin": int(y1),
                        "xmax": int(x2),
                        "ymax": int(y2)
                    }
                })
        
        return detections