#!/usr/bin/env python3
"""Render checks for the summit parallax backdrop.

Requires Godot 4.7 on PATH (or GODOT=/path/to/godot) and Pillow + numpy.
The wrap periods below are exact multiples of every layer's texture period at
the scene's current zooms/speeds (sky 0.02/1.0, mid 0.25/2.0, front 0.55/1.0).
Update them if those uniforms change.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT", "godot")
WRAP_PANS = ["384000,0", "0,216000", "384000,216000"]
MOTION_PAN = "800,450"


def capture(out_dir: Path, pans: list[str]) -> None:
    cmd = [GODOT, "--path", str(ROOT), "-s", "tests/capture.gd", "--", "--out-dir", str(out_dir)]
    for pan in pans:
        cmd += ["--pan", pan]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"capture failed\n{result.stdout}\n{result.stderr}")


def load(out_dir: Path, pan: str) -> np.ndarray:
    path = out_dir / f"pan_{pan.replace(',', '_')}.png"
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def main() -> None:
    out_dir = Path(tempfile.mkdtemp())
    capture(out_dir, ["0,0", MOTION_PAN, *WRAP_PANS])

    base = load(out_dir, "0,0")
    assert base.shape == (1080, 1920, 3), base.shape

    for pan in ["0,0", MOTION_PAN, *WRAP_PANS]:
        frame = load(out_dir, pan)
        uncovered = int((frame.max(axis=2) <= 16).sum())
        assert uncovered == 0, f"{uncovered} uncovered pixels at pan {pan}"

    for pan in WRAP_PANS:
        delta = np.abs(load(out_dir, pan) - base)
        assert delta.mean() < 0.1, f"pan {pan} mean delta {delta.mean():.3f}"
        changed = float((delta.max(axis=2) > 10).mean())
        assert changed < 0.005, f"pan {pan} changed {changed:.3%} of pixels"

    motion = np.abs(load(out_dir, MOTION_PAN) - base).mean()
    assert motion > 5.0, f"pan {MOTION_PAN} barely moved ({motion:.2f})"

    r, g, b = base[..., 0], base[..., 1], base[..., 2]
    hard_red = float(((r > 200) & (g < 110) & (b < 50)).mean())
    sky = float(((r > 200) & (g > 120) & (b < 130)).mean())
    dark = float(((r < 120) & (g < 90)).mean())
    plum = float(((r > 80) & (r < 200) & (g < 110) & (b > 55) & (b > g + 20)).mean())

    assert hard_red < 0.002, f"{hard_red:.3%} hard red/orange left"
    assert sky > 0.25, f"only {sky:.1%} gold sky"
    assert 0.2 < dark < 0.8, f"{dark:.1%} dark layer coverage"
    assert plum > 0.0005, f"only {plum:.3%} plum highlights"

    print(f"ok  sky={sky:.1%} dark={dark:.1%} plum={plum:.3%} hard_red={hard_red:.3%}")


if __name__ == "__main__":
    main()
