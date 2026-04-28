"""
StreetWatch AI — Multi-Task Detection Losses
=============================================
Three losses combined into one module:

  1. Focal Loss (classification)
     -- Addresses severe background/foreground imbalance in SSD
     -- Focuses gradient on hard examples (ambiguous or small damage)

  2. Smooth L1  (bounding box regression)
     -- Less sensitive to outlier box predictions than L2
     -- Computed only on positive (matched) anchors

  3. Cross-Entropy  (severity prediction)
     -- 3-class CE on proxy-labelled severity
     -- Lower lambda because proxy labels are inherently noisier
     -- Computed only on positive anchors

Total loss:
  L = lambda_cls * L_focal + lambda_bbox * L_smooth_l1 + lambda_sev * L_ce
"""

import torch
import torch.nn as nn
import torch.nn.functional as F

from config import TrainingConfig


class FocalLoss(nn.Module):
    """
    Focal Loss (Lin et al., RetinaNet 2017).

    FL(p_t) = -alpha_t * (1 - p_t)^gamma * log(p_t)

    Key properties:
    - gamma > 0 down-weights easy negatives exponentially
    - alpha balances fg/bg contribution
    - Equivalent to cross-entropy when gamma=0, alpha=0.5
    """

    def __init__(self, alpha: float = 0.25, gamma: float = 2.0):
        super().__init__()
        self.alpha = alpha
        self.gamma = gamma

    def forward(self, logits: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        """
        Args:
            logits:  [N, C]  raw class scores (not softmaxed)
            targets: [N]     ground truth class index (0 = background)
        Returns:
            scalar mean loss
        """
        # Standard CE gives us log(p_t) implicitly
        ce = F.cross_entropy(logits, targets, reduction="none")   # [N]
        p_t = torch.exp(-ce)                                       # [N]  = prob of correct class

        # Focal down-weighting term
        focal_weight = (1.0 - p_t) ** self.gamma

        # Alpha weighting: foreground gets alpha, background gets (1-alpha)
        alpha_t = torch.where(
            targets > 0,
            torch.full_like(ce, self.alpha),
            torch.full_like(ce, 1.0 - self.alpha),
        )

        loss = alpha_t * focal_weight * ce
        return loss.mean()


class MultiTaskDetectionLoss(nn.Module):
    """
    Combined SSD multi-task loss for StreetWatch.

    Anchors are partitioned into:
      Positives (pos_mask=True):  matched to a GT box — all 3 losses apply
      Negatives (pos_mask=False): background         — only cls loss applies

    Args:
        cfg:         TrainingConfig (lambda weights, focal params)
        num_classes: int  number of damage classes (not including background)
    """

    def __init__(self, cfg: TrainingConfig, num_classes: int = 4):
        super().__init__()
        self.lambda_cls      = cfg.lambda_cls
        self.lambda_bbox     = cfg.lambda_bbox
        self.lambda_severity = cfg.lambda_severity
        self.num_classes     = num_classes

        self.focal = FocalLoss(alpha=cfg.focal_alpha, gamma=cfg.focal_gamma)

    def forward(
        self,
        bbox_preds: torch.Tensor,         # [B, A, 4]
        cls_logits: torch.Tensor,         # [B, A, C+1]
        sev_logits: torch.Tensor,         # [B, A, 3]
        matched_bbox_targets: torch.Tensor,   # [B, A, 4]
        matched_cls_targets: torch.Tensor,    # [B, A]     0=bg
        matched_sev_targets: torch.Tensor,    # [B, A]    -1=bg (ignore)
        pos_mask: torch.Tensor,               # [B, A]    bool
    ) -> dict:
        """
        Returns:
            dict with keys: total, cls, bbox, severity, num_pos
        """
        B, A, _ = bbox_preds.shape
        num_pos  = pos_mask.sum().clamp(min=1).float()

        # ── 1. Classification (Focal, ALL anchors) ────────────────────────
        # Flatten for focal loss computation
        cls_flat  = cls_logits.view(B * A, -1)           # [B*A, C+1]
        cls_tgt   = matched_cls_targets.view(B * A)      # [B*A]
        loss_cls  = self.focal(cls_flat, cls_tgt)

        # ── 2. BBox Regression (Smooth L1, POSITIVE anchors only) ─────────
        bbox_pos = bbox_preds[pos_mask]              # [P, 4]
        tgt_pos  = matched_bbox_targets[pos_mask]   # [P, 4]

        if bbox_pos.numel() > 0:
            loss_bbox = F.smooth_l1_loss(
                bbox_pos, tgt_pos, beta=1.0, reduction="sum"
            ) / num_pos
        else:
            loss_bbox = bbox_preds.sum() * 0.0   # keep graph alive

        # ── 3. Severity (CE, POSITIVE anchors with valid label) ───────────
        sev_mask = pos_mask & (matched_sev_targets >= 0)
        sev_pos  = sev_logits[sev_mask]             # [P', 3]
        sev_tgt  = matched_sev_targets[sev_mask]    # [P']

        if sev_pos.numel() > 0:
            loss_sev = F.cross_entropy(sev_pos, sev_tgt, reduction="mean")
        else:
            loss_sev = sev_logits.sum() * 0.0

        # ── Total ─────────────────────────────────────────────────────────
        total = (
            self.lambda_cls      * loss_cls
            + self.lambda_bbox     * loss_bbox
            + self.lambda_severity * loss_sev
        )

        return {
            "total":    total,
            "cls":      loss_cls.detach(),
            "bbox":     loss_bbox.detach(),
            "severity": loss_sev.detach(),
            "num_pos":  num_pos.detach(),
        }
