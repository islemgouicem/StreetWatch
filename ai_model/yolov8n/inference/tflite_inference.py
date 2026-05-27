# inference/tflite_inference.py
"""
On-Device Embedded AI: Preprocessing & TFLite Inference Engine
StreetWatch — YOLOv8n Road Damage Detection
"""
import cv2
import numpy as np
import time

class StreetWatchTFLiteEngine:
    def __init__(self, tflite_model_path, conf_thresh=0.45, iou_thresh=0.45):
        self.conf_threshold = conf_thresh
        self.iou_threshold  = iou_thresh
        self.classes = [
            'longitudinal_crack', 'transverse_crack',
            'alligator_crack', 'pothole', 'broken_sign'
        ]

        try:
            import tensorflow as tf
            self.interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
        except ImportError:
            # Use tflite_runtime on embedded devices (lighter than full TF)
            import tflite_runtime.interpreter as tflite
            self.interpreter = tflite.Interpreter(model_path=tflite_model_path)

        self.interpreter.allocate_tensors()
        self.input_details  = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        shape = self.input_details[0]['shape']  # [1, H, W, 3] or [1, 3, H, W]
        if shape[1] == 3:
            self.layout = "NCHW"
            self.in_h, self.in_w = shape[2], shape[3]
        else:
            self.layout = "NHWC"
            self.in_h, self.in_w = shape[1], shape[2]

        print(f"[Engine] Loaded: {tflite_model_path}")
        print(f"[Engine] Layout: {self.layout} | Input: {self.in_h}x{self.in_w}")

    def preprocess(self, frame: np.ndarray):
        """
        Letterbox resize → BGR→RGB → normalize to [0,1] → add batch dim.
        Matches exactly what YOLOv8 expects at inference time.
        """
        orig_h, orig_w = frame.shape[:2]

        # Letterbox: uniform scale, pad with gray (114) to avoid distortion
        scale = min(self.in_w / orig_w, self.in_h / orig_h)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        resized = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_LINEAR)

        canvas = np.full((self.in_h, self.in_w, 3), 114, dtype=np.uint8)
        pad_x  = (self.in_w - new_w) // 2
        pad_y  = (self.in_h - new_h) // 2
        canvas[pad_y:pad_y + new_h, pad_x:pad_x + new_w] = resized

        rgb = cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB)

        if self.layout == "NCHW":
            rgb = rgb.transpose(2, 0, 1)  # HWC → CHW

        tensor = np.expand_dims(rgb, 0).astype(np.float32) / 255.0
        meta   = {'orig_shape': (orig_h, orig_w), 'scale': scale,
                  'pad': (pad_x, pad_y)}
        return tensor, meta

    def postprocess(self, raw_output, meta):
        """
        Parse YOLOv8 raw output [1, 9, 8400]:
        9 = [cx, cy, w, h, cls0, cls1, cls2, cls3, cls4]
        Apply confidence filter + NMS → list of detections.
        """
        preds = np.squeeze(raw_output)          # (9, 8400)
        if preds.shape[0] < preds.shape[1]:
            preds = preds.T                     # → (8400, 9)

        orig_h, orig_w = meta['orig_shape']
        scale  = meta['scale']
        pad_x, pad_y = meta['pad']

        boxes, scores, class_ids = [], [], []

        for pred in preds:
            cx, cy, w, h = pred[:4]
            class_scores  = pred[4:]
            cls_id        = int(np.argmax(class_scores))
            confidence    = float(class_scores[cls_id])

            if confidence < self.conf_threshold:
                continue

            # Map back to original image coordinates
            x1 = int(np.clip((cx - w/2 - pad_x) / scale, 0, orig_w))
            y1 = int(np.clip((cy - h/2 - pad_y) / scale, 0, orig_h))
            x2 = int(np.clip((cx + w/2 - pad_x) / scale, 0, orig_w))
            y2 = int(np.clip((cy + h/2 - pad_y) / scale, 0, orig_h))

            boxes.append([x1, y1, x2 - x1, y2 - y1])
            scores.append(confidence)
            class_ids.append(cls_id)

        # NMS
        indices = cv2.dnn.NMSBoxes(boxes, scores,
                                   self.conf_threshold, self.iou_threshold)
        detections = []
        for i in (indices.flatten() if len(indices) else []):
            x, y, w, h = boxes[i]
            detections.append({
                'class':      self.classes[class_ids[i]],
                'confidence': round(scores[i], 4),
                'bbox':       [x, y, x + w, y + h],
                'severity':   self._severity(w * h, orig_w * orig_h),
            })
        return detections

    @staticmethod
    def _severity(box_area: float, img_area: float) -> str:
        ratio = box_area / img_area
        if ratio < 0.002:  return 'low'
        if ratio < 0.02:   return 'medium'
        return 'high'

    def predict(self, frame: np.ndarray) -> dict:
        t0 = time.perf_counter()
        tensor, meta = self.preprocess(frame)
        t1 = time.perf_counter()

        self.interpreter.set_tensor(self.input_details[0]['index'], tensor)
        self.interpreter.invoke()
        raw = self.interpreter.get_tensor(self.output_details[0]['index'])
        t2 = time.perf_counter()

        detections = self.postprocess(raw, meta)
        t3 = time.perf_counter()

        return {
            'detections': detections,
            'timing_ms': {
                'preprocess':  round((t1 - t0) * 1000, 2),
                'inference':   round((t2 - t1) * 1000, 2),
                'postprocess': round((t3 - t2) * 1000, 2),
                'total':       round((t3 - t0) * 1000, 2),
            }
        }


if __name__ == "__main__":
    import os

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(BASE_DIR, "..", "export", "road_damage_mobile.tflite")
    model_path = os.path.normpath(model_path)
    
    if not os.path.exists(model_path):
        print(f"Model not found: {model_path}")
    else:
        engine = StreetWatchTFLiteEngine(model_path)

        # Benchmark with synthetic 1080p frame
        mock_frame = np.random.randint(0, 255, (1080, 1920, 3), dtype=np.uint8)

        print("Warming up...")
        for _ in range(3):
            engine.predict(mock_frame)

        result = engine.predict(mock_frame)
        t = result['timing_ms']

        print(f"\nPreprocess  : {t['preprocess']} ms")
        print(f"Inference   : {t['inference']} ms")
        print(f"Postprocess : {t['postprocess']} ms")
        print(f"Total       : {t['total']} ms")
        print(f"Detections  : {result['detections']}")