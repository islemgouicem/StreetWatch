"""
StreetWatch AI — Full Model
============================
Combines EfficientNet-Lite0 backbone + SSDLite multi-task head
into a single nn.Module ready for training and ONNX export.
"""

from typing import Dict, List, Tuple

import torch
import torch.nn as nn

from config import ModelConfig
from models.backbone import EfficientNetLite0Backbone
from models.ssdlite_head import SSDLiteHead


class StreetWatchModel(nn.Module):
    """
    Full StreetWatch road damage detection model.

    Inputs:  [B, 3, 320, 320]  normalised RGB image
    Outputs: {
        "bbox_preds": [B, A, 4]       box deltas (SSD encoded)
        "cls_logits": [B, A, C+1]     class logits (0 = background)
        "sev_logits": [B, A, 3]       severity logits
        "anchors":    [A, 4]          default boxes (cx, cy, w, h) normalised
    }
    where A = 2386 total anchors.
    """

    def __init__(self, cfg: ModelConfig):
        super().__init__()
        self.cfg      = cfg
        self.backbone = EfficientNetLite0Backbone(pretrained=cfg.backbone_pretrained)
        self.head     = SSDLiteHead(self.backbone.out_channels, cfg)

        total   = sum(p.numel() for p in self.parameters())
        trainable = sum(p.numel() for p in self.parameters() if p.requires_grad)
        print(f"[Model] Total params: {total:,}  trainable: {trainable:,}")

    # ──────────────────────────────────────────────────────────────────────
    def forward(self, x: torch.Tensor) -> Dict[str, torch.Tensor]:
        c3, c4 = self.backbone(x)
        return self.head(c3, c4)

    # ──────────────────────────────────────────────────────────────────────
    #  Phase management helpers
    # ──────────────────────────────────────────────────────────────────────

    def freeze_backbone(self) -> None:
        """Phase 1: freeze backbone, train head only."""
        self.backbone.freeze()
        trainable = sum(p.numel() for p in self.parameters() if p.requires_grad)
        print(f"  Backbone frozen.  Trainable params: {trainable:,}")

    def unfreeze_backbone(self) -> None:
        """Phase 2: unfreeze for full end-to-end fine-tuning."""
        self.backbone.unfreeze()
        trainable = sum(p.numel() for p in self.parameters() if p.requires_grad)
        print(f"  Backbone unfrozen.  Trainable params: {trainable:,}")

    # ──────────────────────────────────────────────────────────────────────
    #  Optimiser parameter groups (differential learning rates)
    # ──────────────────────────────────────────────────────────────────────

    def get_param_groups(self, base_lr: float, backbone_lr_factor: float, weight_decay: float) -> List[dict]:
        """
        Return parameter groups with differential LR:
          - Backbone: base_lr × backbone_lr_factor  (conservative, preserves ImageNet features)
          - Head:     base_lr                        (free to adapt to damage domain)
        """
        return [
            {
                "params": list(self.backbone.parameters()),
                "lr": base_lr * backbone_lr_factor,
                "name": "backbone",
            },
            {
                "params": list(self.head.parameters()),
                "lr": base_lr,
                "name": "head",
            },
        ]

    # ──────────────────────────────────────────────────────────────────────
    #  Model info
    # ──────────────────────────────────────────────────────────────────────

    @property
    def n_params(self) -> int:
        return sum(p.numel() for p in self.parameters())

    @property
    def n_trainable(self) -> int:
        return sum(p.numel() for p in self.parameters() if p.requires_grad)
