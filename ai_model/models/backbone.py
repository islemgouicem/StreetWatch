"""
StreetWatch AI — EfficientNet-Lite0 Backbone
=============================================
Multi-scale feature extractor built on timm's EfficientNet-Lite0.

For a 320x320 input, the two output feature maps are:
  Stage 3  ->  20x20, 112 channels  (stride-16)
  Stage 4  ->  10x10, 320 channels  (stride-32)

These feed into the SSDLite head which adds extra layers for 5x5 and 3x3.

Design notes:
- features_only=True avoids loading the classification head
- freeze()/unfreeze() enable Phase-1 / Phase-2 training split
- out_channels property is read by SSDLiteHead to size projection layers
"""

from typing import Tuple

import timm
import torch
import torch.nn as nn


class EfficientNetLite0Backbone(nn.Module):

    def __init__(self, pretrained: bool = True):
        super().__init__()

        self._backbone = timm.create_model(
            "efficientnet_lite0",
            pretrained=pretrained,
            features_only=True,
            out_indices=(3, 4),   # stride-16 and stride-32 stages
        )

        # Resolve actual channel widths from model metadata
        info = self._backbone.feature_info.info(indices=(3, 4))
        self._out_channels: Tuple[int, int] = tuple(fi["num_chs"] for fi in info)

        print(
            f"[Backbone] EfficientNet-Lite0  pretrained={pretrained}  "
            f"channels={self._out_channels}  "
            f"params={sum(p.numel() for p in self.parameters()):,}"
        )

    @property
    def out_channels(self) -> Tuple[int, int]:
        """Channel depths of the two output feature maps (c3_ch, c4_ch)."""
        return self._out_channels

    def forward(self, x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        Args:
            x: [B, 3, 320, 320]
        Returns:
            c3: [B, 112, 20, 20]  stride-16
            c4: [B, 320, 10, 10]  stride-32
        """
        feats = self._backbone(x)
        return feats[0], feats[1]

    def freeze(self) -> None:
        """Freeze backbone — Phase-1 training."""
        for p in self._backbone.parameters():
            p.requires_grad = False

    def unfreeze(self) -> None:
        """Unfreeze backbone — Phase-2 end-to-end fine-tuning."""
        for p in self._backbone.parameters():
            p.requires_grad = True

    @property
    def n_params(self) -> int:
        return sum(p.numel() for p in self.parameters())
