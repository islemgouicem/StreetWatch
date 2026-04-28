"""
StreetWatch AI — Training Entry Point
======================================
Usage:
  python train.py
  python train.py --resume runs/streetwatch/checkpoint_epoch020.pt
  python train.py --batch_size 8 --epochs 60
"""

import argparse
from config import Config
from training.trainer import Trainer


def parse_args():
    parser = argparse.ArgumentParser(description="Train StreetWatch damage detector")
    parser.add_argument("--data_root", default="data/rdd2022")
    parser.add_argument("--output_dir", default="runs/streetwatch")
    parser.add_argument("--epochs",     type=int,   default=80)
    parser.add_argument("--batch_size", type=int,   default=16)
    parser.add_argument("--lr",         type=float, default=5e-3)
    parser.add_argument("--resume",     type=str,   default=None,
                        help="Path to checkpoint to resume from")
    return parser.parse_args()


def main():
    args = parse_args()
    cfg = Config.from_env()
    cfg.data.data_root = args.data_root
    cfg.data.train_images = f"{args.data_root}/images/train"
    cfg.data.val_images = f"{args.data_root}/images/val"
    cfg.data.train_json = f"{args.data_root}/annotations/instances_train.json"
    cfg.data.val_json = f"{args.data_root}/annotations/instances_val.json"
    cfg.training.batch_size = args.batch_size
    cfg.training.phase1_lr = args.lr
    cfg.training.phase2_lr = args.lr
    # Keep architecture decision: 20 frozen + 60 unfrozen by default.
    cfg.training.phase1_epochs = min(20, args.epochs)
    cfg.training.phase2_epochs = max(args.epochs - cfg.training.phase1_epochs, 0)
    cfg.training.checkpoint_dir = args.output_dir

    trainer = Trainer(cfg)

    if args.resume:
        trainer.load_checkpoint(args.resume)

    trainer.train()


if __name__ == "__main__":
    main()
