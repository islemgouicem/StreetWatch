# inference/tflite_inference.py
"""
StreetWatch — YOLOv12s Road Damage Detection
Converted from: yolo12s_RDD2022_best.pt (rezzzq/yolo12s-road-damage-rdd2022)
Input : 320×320  →  Output: [1, 9, 2100]
"""
import cv2
import numpy as np
import time


class StreetWatchTFLiteEngine:
    def __init__(self, tflite_model_path, conf_thresh=0.45, iou_thresh=0.45):
        self.conf_threshold = conf_thresh
        self.iou_threshold  = iou_thresh

        # ── Class names matching RDD2022 (same order the model was trained with)
        self.classes = [
            'longitudinal_crack',   # D00
            'transverse_crack',     # D10
            'alligator_crack',      # D20
            'pothole',              # D40
            'repair',               # Repair
        ]

        try:
            import tensorflow as tf
            self.interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
        except ImportError:
            import tflite_runtime.interpreter as tflite
            self.interpreter = tflite.Interpreter(model_path=tflite_model_path)

        self.interpreter.allocate_tensors()
        self.input_details  = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        # ── Read actual shapes from the model — never hardcode ────────────────
        in_shape  = self.input_details[0]['shape']   # e.g. [1, 320, 320, 3]
        out_shape = self.output_details[0]['shape']  # e.g. [1, 9, 2100]

        if in_shape[1] == 3:                         # NCHW layout (rare for TFLite)
            self.layout = "NCHW"
            self.in_h, self.in_w = in_shape[2], in_shape[3]
        else:                                        # NHWC (standard)
            self.layout = "NHWC"
            self.in_h, self.in_w = in_shape[1], in_shape[2]

        self.num_predictions = out_shape[2]          # 2100 for 320×320
        self.num_classes     = len(self.classes)     # 5

        print(f"[Engine] Model     : {tflite_model_path}")
        print(f"[Engine] Layout    : {self.layout} | Input : {self.in_h}×{self.in_w}")
        print(f"[Engine] Output    : {out_shape}  → {self.num_predictions} predictions")
        print(f"[Engine] Classes   : {self.classes}")

    # ── PREPROCESSING ─────────────────────────────────────────────────────────

    def preprocess(self, frame: np.ndarray):
        orig_h, orig_w = frame.shape[:2]
        scale = min(self.in_w / orig_w, self.in_h / orig_h)
        new_w, new_h = int(orig_w * scale), int(orig_h * scale)

        resized = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
        canvas  = np.full((self.in_h, self.in_w, 3), 114, dtype=np.uint8)
        pad_x   = (self.in_w - new_w) // 2
        pad_y   = (self.in_h - new_h) // 2
        canvas[pad_y:pad_y + new_h, pad_x:pad_x + new_w] = resized

        rgb = cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB)
        if self.layout == "NCHW":
            rgb = rgb.transpose(2, 0, 1)

        tensor = np.expand_dims(rgb, 0).astype(np.float32) / 255.0
        meta   = {
            'orig_shape': (orig_h, orig_w),
            'scale': scale,
            'pad': (pad_x, pad_y),
        }
        return tensor, meta

    # ── POSTPROCESSING ────────────────────────────────────────────────────────

    def postprocess(self, raw_output, meta):
        """
        YOLOv8/12 TFLite output: [1, 9, N]
        9 = [cx, cy, w, h, cls0..cls4]
        N = num_predictions (2100 for 320×320)
        """
        preds = np.squeeze(raw_output)       # (9, 2100)
        if preds.shape[0] < preds.shape[1]:
            preds = preds.T                  # → (2100, 9)

        orig_h, orig_w = meta['orig_shape']
        scale          = meta['scale']
        pad_x, pad_y   = meta['pad']

        boxes, scores, class_ids = [], [], []

        for pred in preds:
            cx, cy, w, h  = pred[:4]
            class_scores  = pred[4:4 + self.num_classes]
            cls_id        = int(np.argmax(class_scores))
            confidence    = float(class_scores[cls_id])

            if confidence < self.conf_threshold or w <= 0 or h <= 0:
                continue

            x1 = int(np.clip((cx - w / 2 - pad_x) / scale, 0, orig_w))
            y1 = int(np.clip((cy - h / 2 - pad_y) / scale, 0, orig_h))
            x2 = int(np.clip((cx + w / 2 - pad_x) / scale, 0, orig_w))
            y2 = int(np.clip((cy + h / 2 - pad_y) / scale, 0, orig_h))

            boxes.append([x1, y1, x2 - x1, y2 - y1])
            scores.append(confidence)
            class_ids.append(cls_id)

        indices = cv2.dnn.NMSBoxes(
            boxes, scores, self.conf_threshold, self.iou_threshold
        )
        detections = []
        for i in (indices.flatten() if len(indices) else []):
            x, y, bw, bh = boxes[i]
            detections.append({
                'class':      self.classes[class_ids[i]],
                'confidence': round(scores[i], 4),
                'bbox':       [x, y, x + bw, y + bh],
                'severity':   self._severity(bw * bh, orig_w * orig_h),
            })
        return detections

    @staticmethod
    def _severity(box_area: float, img_area: float) -> str:
        ratio = box_area / img_area
        if ratio < 0.002: return 'low'
        if ratio < 0.02:  return 'medium'
        return 'high'

    # ── PREDICT ───────────────────────────────────────────────────────────────

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
            },
        }


# ── QUICK TEST ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import os
    import glob

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

    # ── Paths ──────────────────────────────────────────────────────────────
    model_path = os.path.normpath(
        os.path.join(BASE_DIR, "..", "export", "road_damage_mobile.tflite")
    )

    test_images_dir = os.path.normpath(
        os.path.join(BASE_DIR, "..", "dataset", "train", "images")
    )

    if not os.path.exists(model_path):
        print(f"Model not found: {model_path}")
        exit()

    if not os.path.exists(test_images_dir):
        print(f"Test images folder not found: {test_images_dir}")
        exit()

    # ── Load engine ────────────────────────────────────────────────────────
    engine = StreetWatchTFLiteEngine(model_path)

    # ── Collect test images ────────────────────────────────────────────────
    image_paths = glob.glob(os.path.join(test_images_dir, "*.jpg"))

    if len(image_paths) == 0:
        print("No test images found.")
        exit()

    print(f"\nFound {len(image_paths)} test images.")

    # ── Iterate through dataset ────────────────────────────────────────────
    total_time = 0

    for idx, image_path in enumerate(image_paths):

        image_name = os.path.basename(image_path)

        frame = cv2.imread(image_path)

        if frame is None:
            print(f"Failed to load {image_name}")
            continue

        # Run inference
        result = engine.predict(frame)

        t = result['timing_ms']
        total_time += t['total']

        print("\n==================================================")
        print(f"[{idx + 1}/{len(image_paths)}] {image_name}")
        print("==================================================")

        print(f"Preprocess  : {t['preprocess']} ms")
        print(f"Inference   : {t['inference']} ms")
        print(f"Postprocess : {t['postprocess']} ms")
        print(f"Total       : {t['total']} ms")

        print("\nDetections:")

        if len(result['detections']) == 0:
            print("  No detections")

        else:
            for det in result['detections']:
                print(
                    f"  {det['class']} | "
                    f"conf={det['confidence']:.2f} | "
                    f"severity={det['severity']}"
                )

                # Draw bounding box
                x1, y1, x2, y2 = det['bbox']

                color = (0, 255, 0)

                if det['severity'] == 'medium':
                    color = (0, 165, 255)

                elif det['severity'] == 'high':
                    color = (0, 0, 255)

                label = (
                    f"{det['class']} "
                    f"{det['confidence']:.2f} "
                    f"({det['severity']})"
                )

                cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

                cv2.putText(
                    frame,
                    label,
                    (x1, max(20, y1 - 10)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.6,
                    color,
                    2
                )

        # Resize display
        display = cv2.resize(frame, (1280, 720))

        cv2.imshow("StreetWatch Test Inference", display)

        # Press:
        #   q -> quit
        #   any other key -> next image
        key = cv2.waitKey(0)

        if key == ord('q'):
            break

    cv2.destroyAllWindows()

    # ── Summary ────────────────────────────────────────────────────────────
    avg_time = total_time / len(image_paths)

    print("\n==================================================")
    print("FINAL SUMMARY")
    print("==================================================")

    print(f"Images processed : {len(image_paths)}")
    print(f"Average latency  : {avg_time:.2f} ms/image")
    print(f"Approx FPS       : {1000 / avg_time:.2f}")