#!/usr/bin/env python3
"""Assemble Globemaster/Resources/Globemaster.icon from design/icon/src.

Run scripts/generate-icon-layers.py first. Usage: scripts/build-icon-bundle.py
"""
import json
import shutil
from pathlib import Path

SRC = Path("design/icon/src")
BUNDLE = Path("Globemaster/Resources/Globemaster.icon")
ASSETS = BUNDLE / "Assets"


def layer(name, stem, glass=False):
    """Return (light, dark) layers; each is hidden in the other appearance."""
    pair = []
    for variant in ("light", "dark"):
        f = f"{stem}-{variant}.svg"
        shutil.copy(SRC / f, ASSETS / f)
        pair.append({
            "glass": glass,
            "hidden-specializations": [
                {"value": variant == "dark"},
                {"appearance": "dark", "value": variant == "light"},
            ],
            "image-name": f,
            "name": f"{name} ({variant})",
            "position": {"scale": 1, "translation-in-points": [0, 0]},
        })
    return pair


def srgb(h):
    h = h.lstrip("#")
    return "srgb:" + ",".join(f"{int(h[i:i + 2], 16) / 255:.5f}" for i in (0, 2, 4)) + ",1.00000"


def gradient(top, bottom):
    return {
        "linear-gradient": [srgb(top), srgb(bottom)],
        "orientation": {"start": {"x": 0.37, "y": 0}, "stop": {"x": 0.63, "y": 1}},
    }


if BUNDLE.exists():
    shutil.rmtree(BUNDLE)
ASSETS.mkdir(parents=True)

# Front to back. Only the lens (and, lightly, the foreground) uses Liquid Glass.
groups = [
    {
        "name": "Foreground",
        "layers": [*layer("Lamp", "07-lamp"), *layer("Command", "06-command")],
        "lighting": "individual",
        "shadow": {"kind": "none", "opacity": 0},
        "translucency": {"enabled": False, "value": 0},
    },
    {
        "name": "Lens",
        "layers": [*layer("Marks", "05-marks"), *layer("Lens", "04-lens", glass=True)],
        "lighting": "combined",
        "shadow": {"kind": "neutral", "opacity": 0.3},
        "translucency": {"enabled": True, "value": 0.35},
    },
    {
        "name": "Bezel",
        "layers": layer("Bezel", "03-bezel"),
        "shadow": {"kind": "layer-color", "opacity": 0.4},
        "translucency": {"enabled": False, "value": 0},
    },
    {
        "name": "Grid",
        "layers": [*layer("Grid", "02-grid"), *layer("Brushed", "01-background")],
        "shadow": {"kind": "none", "opacity": 0},
        "translucency": {"enabled": False, "value": 0},
    },
]

doc = {
    "fill-specializations": [
        {"value": gradient("#ECEEF0", "#B4B9C0")},
        {"appearance": "dark", "value": gradient("#474B52", "#18191C")},
    ],
    "groups": groups,
    "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
}
(BUNDLE / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")
print(f"wrote {BUNDLE}")
