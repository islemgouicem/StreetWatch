"""
StreetWatch AI — SSDLite Multi-Task Detection Head
===================================================
Depthwise-separable (DW-Sep) convolutions ONLY throughout.
No standard 3x3 convs — this is what makes it "Lite" and mobile-ready.

Architecture:
  Backbone outputs:  c3 [B, 112, 20, 20]   c4 [B, 320, 10, 10]
                          |                       |
  Channel projection:  proj_c3 (DW-Sep)      proj_c4 (DW-Sep)
                          |                       |
  Extra layers:        [20x20]              [10x10] --> extra1 --> [5x5]
                                                               --> extra2 --> [3x3]
                          |                   |                |               |
  Prediction heads:   [4 anchors]         [6 anchors]    [6 anchors]     [4 anchors]
                          |                   |                |               |
                    bbox / cls / sev    bbox / cls / sev  ...             ...
                          |
  Output: concat all → [B, total_anchors, 4]  bbox deltas
                        [B, total_anchors, C+1] class logits (bg + 4 classes)
                        [B, total_anchors, 3]  severity logits

Anchor counts:
  20x20 x 4 = 1600
  10x10 x 6 =  600
   5x5  x 6 =  150
   3x3  x 4 =   36
  ──────────────────
  Total     = 2386 anchors
"""

import math
from typing import Dict, Tuple

import numpy as np
import torch
import torch.nn as nn

from Software_eng.StreetWatch.ai_model.efficentNet_and_ssdlite.config import ModelConfig


# ─────────────────────────────────────────────────────────────────────────────
#  Building Blocks
# ─────────────────────────────────────────────────────────────────────────────

def dw_sep_conv(in_ch: int, out_ch: int, stride: int = 1) -> nn.Sequential:
    """
    Depthwise Separable Convolution (MobileNet-style).
    ~8-9x fewer FLOPs than a standard Conv2d of same dimensions.

    depthwise  → BN → ReLU6
    pointwise  → BN → ReLU6
    """
    return nn.Sequential(
        # Depthwise: one 3x3 filter per channel (groups=in_ch)
        nn.Conv2d(in_ch, in_ch, kernel_size=3, stride=stride,
                  padding=1, groups=in_ch, bias=False),
        nn.BatchNorm2d(in_ch),
        nn.ReLU6(inplace=True),
        # Pointwise: 1x1 conv to mix channels
        nn.Conv2d(in_ch, out_ch, kernel_size=1, bias=False),
        nn.BatchNorm2d(out_ch),
        nn.ReLU6(inplace=True),
    )


def prediction_head(in_ch: int, n_anchors: int, out_per_anchor: int) -> nn.Sequential:
    """
    Per-scale prediction head.
    1 DW-Sep conv for feature mixing, then 1x1 pointwise for prediction.
    """
    return nn.Sequential(
        # DW conv (spatial feature extraction)
        nn.Conv2d(in_ch, in_ch, kernel_size=3, padding=1,
                  groups=in_ch, bias=False),
        nn.BatchNorm2d(in_ch),
        nn.ReLU6(inplace=True),
        # 1x1 projection to prediction dimension
        nn.Conv2d(in_ch, n_anchors * out_per_anchor, kernel_size=1, bias=True),
    )


# ─────────────────────────────────────────────────────────────────────────────
#  Anchor Generator
# ─────────────────────────────────────────────────────────────────────────────

class AnchorGenerator(nn.Module):
    """
    Pre-computes all default (prior) anchor boxes for SSD.

    Anchors are FIXED — not learned.  Registered as a buffer so they
    move to the correct device automatically with .to(device).

    For each (scale_k, feature_map_location, aspect_ratio):
      width  = s_k * sqrt(ar)
      height = s_k / sqrt(ar)
    Plus one extra anchor per scale with s = sqrt(s_k * s_{k+1}).

    Output shape: [total_anchors, 4]  in normalised (cx, cy, w, h) format.
    """

    def __init__(self, cfg: ModelConfig):
        super().__init__()
        anchors = self._build(cfg)
        self.register_buffer("default_boxes", anchors)

    def _build(self, cfg: ModelConfig) -> torch.Tensor:
        scales   = cfg.anchor_scales
        fmap_sizes = cfg.feature_map_sizes
        ar_sets  = cfg.anchor_aspect_ratios
        boxes: list = []

        for k, (fm, ratios) in enumerate(zip(fmap_sizes, ar_sets)):
            s_k  = scales[k]
            s_k1 = scales[k + 1] if k + 1 < len(scales) else 1.0
            s_extra = math.sqrt(s_k * s_k1)

            for i in range(fm):
                for j in range(fm):
                    cx = (j + 0.5) / fm
                    cy = (i + 0.5) / fm

                    # Ratio 1.0, scale s_k
                    boxes.append([cx, cy, s_k, s_k])
                    # Ratio 1.0, extra scale
                    boxes.append([cx, cy, s_extra, s_extra])

                    for ar in ratios:
                        if ar == 1.0:
                            continue   # already added above
                        w = s_k * math.sqrt(ar)
                        h = s_k / math.sqrt(ar)
                        boxes.append([cx, cy, w, h])

        t = torch.tensor(boxes, dtype=torch.float32)
        return torch.clamp(t, 0.0, 1.0)

    def forward(self) -> torch.Tensor:
        return self.default_boxes


# ─────────────────────────────────────────────────────────────────────────────
#  SSDLite Head
# ─────────────────────────────────────────────────────────────────────────────

class SSDLiteHead(nn.Module):
    """
    SSDLite multi-task prediction head.

    Three parallel output branches per anchor:
      1. Bounding box regression  (4 deltas)
      2. Damage classification    (C+1 logits, index 0 = background)
      3. Severity prediction      (3 logits: low / medium / high)
    """

    def __init__(self, backbone_out_channels: Tuple[int, int], cfg: ModelConfig):
        super().__init__()
        self.cfg = cfg

        c3_ch, c4_ch = backbone_out_channels
        extra_ch = cfg.extra_layer_channels   # (256, 256)
        pred_ch  = cfg.prediction_channels    # 256

        # ── 1. Channel projection (align all scales to pred_ch) ──────────
        self.proj_c3 = dw_sep_conv(c3_ch, pred_ch)       # 20x20
        self.proj_c4 = dw_sep_conv(c4_ch, pred_ch)       # 10x10

        # ── 2. Extra feature layers (stride-2 to downsample) ─────────────
        self.extra1 = dw_sep_conv(pred_ch,    extra_ch[0], stride=2)  # 10→5
        self.extra2 = dw_sep_conv(extra_ch[0], extra_ch[1], stride=2) # 5→3

        # ── 3. Per-scale prediction heads ─────────────────────────────────
        feat_channels = [pred_ch, pred_ch, extra_ch[0], extra_ch[1]]
        n_anchors     = cfg.num_anchors_per_loc   # (4, 6, 6, 4)
        num_cls       = cfg.num_classes + 1       # +1 for background
        num_sev       = cfg.num_severity_classes

        self.bbox_heads = nn.ModuleList([
            prediction_head(ch, na, 4)
            for ch, na in zip(feat_channels, n_anchors)
        ])
        self.cls_heads = nn.ModuleList([
            prediction_head(ch, na, num_cls)
            for ch, na in zip(feat_channels, n_anchors)
        ])
        self.sev_heads = nn.ModuleList([
            prediction_head(ch, na, num_sev)
            for ch, na in zip(feat_channels, n_anchors)
        ])

        # ── 4. Anchor generator ───────────────────────────────────────────
        self.anchor_gen = AnchorGenerator(cfg)

        # ── 5. Weight initialisation ──────────────────────────────────────
        self._init_weights()

    # ──────────────────────────────────────────────────────────────────────
    def _init_weights(self) -> None:
        """
        Initialise classification head biases for focal loss stability.

        Setting bias = log((1-p)/p) for p=0.01 means the network starts
        predicting ~1% probability for any class, preventing large initial
        focal loss spikes that destabilise early training.
        """
        prior_prob = 0.01
        bias_init  = -math.log((1.0 - prior_prob) / prior_prob)  # ≈ 4.595

        for head in self.cls_heads:
            last_conv = head[-1]
            if hasattr(last_conv, "bias") and last_conv.bias is not None:
                nn.init.constant_(last_conv.bias, bias_init)

        # Xavier init for bbox and severity heads
        for module in list(self.bbox_heads) + list(self.sev_heads):
            for m in module.modules():
                if isinstance(m, nn.Conv2d):
                    nn.init.xavier_uniform_(m.weight)
                    if m.bias is not None:
                        nn.init.zeros_(m.bias)

    # ──────────────────────────────────────────────────────────────────────
    def forward(
        self,
        c3: torch.Tensor,
        c4: torch.Tensor,
    ) -> Dict[str, torch.Tensor]:
        """
        Args:
            c3: [B, 112, 20, 20]  backbone stride-16 feature map
            c4: [B, 320, 10, 10]  backbone stride-32 feature map

        Returns:
            {
              "bbox_preds": [B, 2386, 4]
              "cls_logits": [B, 2386, 5]   (bg + 4 damage classes)
              "sev_logits": [B, 2386, 3]
              "anchors":    [2386, 4]       cx/cy/w/h normalised
            }
        """
        # Project + build feature pyramid
        f0 = self.proj_c3(c3)    # [B, 256, 20, 20]
        f1 = self.proj_c4(c4)    # [B, 256, 10, 10]
        f2 = self.extra1(f1)     # [B, 256,  5,  5]
        f3 = self.extra2(f2)     # [B, 256,  3,  3]

        features = [f0, f1, f2, f3]

        all_bbox, all_cls, all_sev = [], [], []

        for i, feat in enumerate(features):
            B  = feat.shape[0]
            na = self.cfg.num_anchors_per_loc[i]

            bbox = self.bbox_heads[i](feat)   # [B, na*4,   H, W]
            cls  = self.cls_heads[i](feat)    # [B, na*C+1, H, W]
            sev  = self.sev_heads[i](feat)    # [B, na*S,   H, W]

            # [B, na*K, H, W] → [B, H*W*na, K]
            bbox = bbox.permute(0, 2, 3, 1).contiguous().view(B, -1, 4)
            cls  = cls.permute(0, 2, 3, 1).contiguous().view(B, -1, self.cfg.num_classes + 1)
            sev  = sev.permute(0, 2, 3, 1).contiguous().view(B, -1, self.cfg.num_severity_classes)

            all_bbox.append(bbox)
            all_cls.append(cls)
            all_sev.append(sev)

        return {
            "bbox_preds": torch.cat(all_bbox, dim=1),
            "cls_logits": torch.cat(all_cls,  dim=1),
            "sev_logits": torch.cat(all_sev,  dim=1),
            "anchors":    self.anchor_gen(),
        }
