"""
StreetWatch AI — Trainer
=========================
Two-phase training strategy:

  Phase 1 (epochs 0..freeze_backbone_epochs)
    Backbone frozen. Only detection head trains.
    High LR — quickly adapts head to road damage domain.

  Phase 2 (epochs freeze_backbone_epochs..end)
    All layers unfrozen. End-to-end fine-tuning.
    Cosine annealing LR schedule.

Includes:
  - Periodic checkpoint saving
  - Early stopping on validation loss
  - Per-epoch loss logging (console + CSV)
  - mAP evaluation hook (pluggable)
"""

import csv
import time
import random
import shutil
from pathlib import Path

import torch
import torch.optim as optim
from torch.optim.lr_scheduler import CosineAnnealingLR

from config import Config
from models.streetwatch_model import StreetWatchModel
from training.losses import MultiTaskDetectionLoss
from training.anchor_utils import match_batch
from data.dataset import build_dataloaders


# ─────────────────────────────────────────────
#  METRIC TRACKER
# ─────────────────────────────────────────────

class AverageMeter:
    def __init__(self):
        self.reset()

    def reset(self):
        self.val = self.avg = self.sum = self.count = 0.0

    def update(self, val, n=1):
        self.val   = val
        self.sum  += val * n
        self.count += n
        self.avg   = self.sum / self.count


# ─────────────────────────────────────────────
#  SEED
# ─────────────────────────────────────────────

def set_seed(seed: int):
    random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


# ─────────────────────────────────────────────
#  TRAINER
# ─────────────────────────────────────────────

class Trainer:
    def __init__(self, cfg: Config):
        self.cfg = cfg
        self.tcfg = cfg.training
        self.mcfg = cfg.model
        set_seed(self.tcfg.seed)

        # ── Device ──────────────────────────────
        self.device = torch.device(
            "cuda" if torch.cuda.is_available() else
            "mps"  if torch.backends.mps.is_available() else
            "cpu"
        )
        print(f"[Trainer] Using device: {self.device}")

        # ── Output directory ────────────────────
        self.out_dir = Path(self.tcfg.checkpoint_dir)
        self.out_dir.mkdir(parents=True, exist_ok=True)

        # ── Model (Phase 1: backbone frozen) ────
        self.model = StreetWatchModel(self.mcfg).to(self.device)
        self.model.freeze_backbone()
        print(f"[Trainer] Parameters: {self.model.n_params:,} total, "
              f"{self.model.n_trainable:,} trainable (backbone frozen)")

        # ── Loss function ────────────────────────
        self.loss_fn = MultiTaskDetectionLoss(self.tcfg, num_classes=self.mcfg.num_classes)

        # ── Optimiser (SGD with momentum — better for detection than Adam) ─
        self.optimizer = optim.SGD(
            filter(lambda p: p.requires_grad, self.model.parameters()),
            lr=self.tcfg.phase1_lr,
            momentum=self.tcfg.momentum,
            weight_decay=self.tcfg.weight_decay,
            nesterov=True,
        )

        # ── LR Scheduler (cosine from epoch 0 → end) ─
        self.scheduler = CosineAnnealingLR(
            self.optimizer,
            T_max=max(self.tcfg.phase1_epochs, 1),
            eta_min=self.tcfg.phase1_lr * 0.01,
        )

        # ── Data ─────────────────────────────────
        print("[Trainer] Building dataloaders...")
        self.train_loader, self.val_loader = build_dataloaders(cfg)

        # ── State ────────────────────────────────
        self.best_val_loss  = float("inf")
        self.epochs_no_improve = 0
        self.start_epoch    = 0

        # ── CSV log ──────────────────────────────
        self.log_path = self.out_dir / "train_log.csv"
        self._init_csv_log()

    # ─────────────────────────────────────────
    #  CSV LOGGING
    # ─────────────────────────────────────────

    def _init_csv_log(self):
        if not self.log_path.exists():
            with open(self.log_path, "w", newline="") as f:
                writer = csv.writer(f)
                writer.writerow(["epoch", "phase", "lr",
                                 "train_total", "train_bbox", "train_cls", "train_sev",
                                 "val_total",   "val_bbox",   "val_cls",   "val_sev"])

    def _log_csv(self, epoch, phase, lr, train_d, val_d):
        with open(self.log_path, "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                epoch, phase, f"{lr:.6f}",
                f"{train_d['total']:.4f}", f"{train_d['bbox']:.4f}",
                f"{train_d['cls']:.4f}",   f"{train_d['severity']:.4f}",
                f"{val_d['total']:.4f}",   f"{val_d['bbox']:.4f}",
                f"{val_d['cls']:.4f}",     f"{val_d['severity']:.4f}",
            ])

    # ─────────────────────────────────────────
    #  WARMUP LR
    # ─────────────────────────────────────────

    def _warmup_lr(self, epoch: int, step: int, steps_per_epoch: int):
        """Linear LR warmup for first `warmup_epochs` epochs."""
        if epoch >= self.tcfg.warmup_epochs:
            return
        total_warmup_steps = self.tcfg.warmup_epochs * steps_per_epoch
        current_step = epoch * steps_per_epoch + step
        factor = current_step / max(total_warmup_steps, 1)
        for pg in self.optimizer.param_groups:
            pg["lr"] = self.tcfg.phase1_lr * factor

    # ─────────────────────────────────────────
    #  PHASE TRANSITION
    # ─────────────────────────────────────────

    def _enter_phase2(self):
        """
        Unfreeze backbone and reset optimiser with all parameters.
        Called once when epoch reaches freeze_backbone_epochs.
        """
        print("\n" + "="*60)
        print("  PHASE 2: Unfreezing backbone — end-to-end training")
        print("="*60 + "\n")

        self.model.unfreeze_backbone()

        # Re-create optimiser with all parameters + lower LR for backbone
        self.optimizer = optim.SGD(
            self.model.get_param_groups(
                base_lr=self.tcfg.phase2_lr,
                backbone_lr_factor=self.tcfg.backbone_lr_factor,
                weight_decay=self.tcfg.weight_decay,
            ),
            momentum=self.tcfg.momentum,
            weight_decay=self.tcfg.weight_decay,
            nesterov=True,
        )
        self.scheduler = CosineAnnealingLR(
            self.optimizer,
            T_max=max(self.tcfg.phase2_epochs, 1),
            eta_min=self.tcfg.phase2_lr * 0.01,
        )
        print(f"[Trainer] Trainable parameters now: {self.model.n_trainable:,}")

    # ─────────────────────────────────────────
    #  ONE EPOCH
    # ─────────────────────────────────────────

    def _run_epoch(self, loader, train: bool) -> dict:
        if train:
            self.model.train()
        else:
            self.model.eval()

        meters = {k: AverageMeter() for k in ["total", "bbox", "cls", "severity"]}
        epoch_start = time.time()

        ctx = torch.enable_grad() if train else torch.no_grad()
        with ctx:
            for step, (images, gt_boxes, gt_labels, gt_sev) in enumerate(loader):
                images = images.to(self.device, non_blocking=True)

                if train:
                    self._warmup_lr(
                        self._current_epoch, step, len(loader)
                    )

                out = self.model(images)
                bbox_t, cls_t, sev_t, pos_mask = match_batch(
                    anchors=out["anchors"],
                    gt_boxes_list=gt_boxes,
                    gt_labels_list=gt_labels,
                    gt_severity_list=gt_sev,
                    iou_threshold=self.mcfg.iou_threshold_pos,
                    variance=self.mcfg.anchor_variance,
                    num_classes=self.mcfg.num_classes,
                )
                loss_dict = self.loss_fn(
                    out["bbox_preds"], out["cls_logits"], out["sev_logits"],
                    bbox_t, cls_t, sev_t, pos_mask,
                )
                loss = loss_dict["total"]

                if train:
                    self.optimizer.zero_grad(set_to_none=True)
                    loss.backward()
                    # Gradient clipping — prevents exploding gradients with focal loss
                    torch.nn.utils.clip_grad_norm_(self.model.parameters(), max_norm=10.0)
                    self.optimizer.step()

                for k in meters:
                    meters[k].update(float(loss_dict[k].detach().item()), images.shape[0])

                if train and step % self.tcfg.log_interval == 0:
                    elapsed = time.time() - epoch_start
                    lr_now = self.optimizer.param_groups[0]["lr"]
                    print(
                        f"  step {step:4d}/{len(loader)}  "
                        f"loss={meters['total'].avg:.3f}  "
                        f"bbox={meters['bbox'].avg:.3f}  "
                        f"cls={meters['cls'].avg:.3f}  "
                        f"sev={meters['severity'].avg:.3f}  "
                        f"lr={lr_now:.5f}  "
                        f"t={elapsed:.0f}s"
                    )

        return {k: m.avg for k, m in meters.items()}

    # ─────────────────────────────────────────
    #  CHECKPOINT
    # ─────────────────────────────────────────

    def _save_checkpoint(self, epoch: int, val_loss: float, is_best: bool):
        state = {
            "epoch":            epoch,
            "model_state_dict": self.model.state_dict(),
            "optimizer":        self.optimizer.state_dict(),
            "val_loss":         val_loss,
            "cfg":              self.cfg,
        }
        ckpt_path = self.out_dir / f"checkpoint_epoch{epoch:03d}.pt"
        torch.save(state, ckpt_path)

        if is_best:
            best_path = self.out_dir / "best.pt"
            shutil.copyfile(ckpt_path, best_path)
            print(f"  ✓ Best model saved → {best_path}  (val_loss={val_loss:.4f})")

        # Clean up old checkpoints (keep last 2 + best)
        all_ckpts = sorted(self.out_dir.glob("checkpoint_epoch*.pt"))
        for old in all_ckpts[:-2]:
            old.unlink()

    def load_checkpoint(self, path: str):
        """Resume training from a saved checkpoint."""
        state = torch.load(path, map_location=self.device)
        self.model.load_state_dict(state["model_state_dict"])
        self.optimizer.load_state_dict(state["optimizer"])
        self.start_epoch    = state["epoch"] + 1
        self.best_val_loss  = state["val_loss"]
        print(f"[Trainer] Resumed from epoch {state['epoch']} "
              f"(val_loss={state['val_loss']:.4f})")

    # ─────────────────────────────────────────
    #  MAIN TRAIN LOOP
    # ─────────────────────────────────────────

    def train(self):
        total_epochs = self.tcfg.phase1_epochs + self.tcfg.phase2_epochs
        phase = 1

        print(f"\n{'='*60}")
        print(f"  StreetWatch Training  —  {total_epochs} epochs")
        print(f"  Phase 1: frozen backbone for {self.tcfg.phase1_epochs} epochs")
        print(f"{'='*60}\n")

        for epoch in range(self.start_epoch, total_epochs):
            self._current_epoch = epoch

            # ── Phase transition ───────────────
            if epoch == self.tcfg.phase1_epochs and phase == 1:
                self._enter_phase2()
                phase = 2

            lr_now = self.optimizer.param_groups[0]["lr"]
            print(f"\nEpoch [{epoch+1:3d}/{total_epochs}]  phase={phase}  lr={lr_now:.5f}")

            # ── Train ──────────────────────────
            train_losses = self._run_epoch(self.train_loader, train=True)

            # ── Validate ───────────────────────
            val_losses = self._run_epoch(self.val_loader, train=False)

            # ── Scheduler step (after warmup) ──
            if epoch >= self.tcfg.warmup_epochs:
                self.scheduler.step()

            # ── Logging ────────────────────────
            self._log_csv(epoch+1, phase, lr_now, train_losses, val_losses)

            print(
                f"  Train  total={train_losses['total']:.3f}  "
                f"bbox={train_losses['bbox']:.3f}  "
                f"cls={train_losses['cls']:.3f}  "
                f"sev={train_losses['severity']:.3f}"
            )
            print(
                f"  Val    total={val_losses['total']:.3f}  "
                f"bbox={val_losses['bbox']:.3f}  "
                f"cls={val_losses['cls']:.3f}  "
                f"sev={val_losses['severity']:.3f}"
            )

            # ── Checkpointing ──────────────────
            val_total = val_losses["total"]
            is_best   = val_total < self.best_val_loss

            if is_best:
                self.best_val_loss     = val_total
                self.epochs_no_improve = 0
            else:
                self.epochs_no_improve += 1

            if (epoch + 1) % self.tcfg.save_every_n_epochs == 0 or is_best:
                self._save_checkpoint(epoch, val_total, is_best)

            # ── Early stopping ─────────────────
            if self.epochs_no_improve >= self.tcfg.early_stop_patience:
                print(f"\n[Trainer] Early stopping at epoch {epoch+1} "
                      f"(no improvement for {self.tcfg.early_stop_patience} epochs)")
                break

        print(f"\n[Trainer] Training complete. Best val loss: {self.best_val_loss:.4f}")
        print(f"[Trainer] Checkpoints saved to: {self.out_dir}")


# ─────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────

if __name__ == "__main__":
    cfg = Config.from_env()
    trainer = Trainer(cfg)
    trainer.train()
