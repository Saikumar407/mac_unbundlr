#!/usr/bin/env python3
"""
generate_icons.py — build every AppIcon asset from AppIcon.svg.

Outputs:
  Sources/ProfilePilot/Resources/Assets.xcassets/AppIcon.appiconset/
      icon_16x16.png            (16)
      icon_16x16@2x.png         (32)
      icon_32x32.png            (32)
      icon_32x32@2x.png         (64)
      icon_128x128.png          (128)
      icon_128x128@2x.png       (256)
      icon_256x256.png          (256)
      icon_256x256@2x.png       (512)
      icon_512x512.png          (512)
      icon_512x512@2x.png       (1024)
  dmg-assets/AppIcon.png        (1024)
  dmg-assets/AppIcon.icns       (multi-size ICNS)
  dmg-assets/VolumeIcon.icns    (mirrors AppIcon for the DMG volume)

Runs on Linux (Emergent CI container) and on macOS.
"""

from __future__ import annotations
import io
import os
import sys
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC_SVG = ROOT / "dmg-assets" / "AppIcon.svg"
ICONSET_DIR = ROOT / "Sources" / "ProfilePilot" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
DMG_ASSETS = ROOT / "dmg-assets"

APPICONSET = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",     128),
    ("icon_128x128@2x.png",  256),
    ("icon_256x256.png",     256),
    ("icon_256x256@2x.png",  512),
    ("icon_512x512.png",     512),
    ("icon_512x512@2x.png",  1024),
]


def render_master(size: int = 1024) -> Image.Image:
    """Render the master SVG once at high res, return as PIL RGBA."""
    png_bytes = cairosvg.svg2png(url=str(SRC_SVG),
                                 output_width=size,
                                 output_height=size)
    return Image.open(io.BytesIO(png_bytes)).convert("RGBA")


def main() -> int:
    if not SRC_SVG.exists():
        print(f"✗ Source SVG missing: {SRC_SVG}", file=sys.stderr)
        return 1

    ICONSET_DIR.mkdir(parents=True, exist_ok=True)
    DMG_ASSETS.mkdir(parents=True, exist_ok=True)

    master = render_master(1024)
    master.save(DMG_ASSETS / "AppIcon.png", format="PNG", optimize=True)
    print(f"✓ Master 1024×1024 → dmg-assets/AppIcon.png")

    for filename, size in APPICONSET:
        img = master.resize((size, size), Image.Resampling.LANCZOS)
        out = ICONSET_DIR / filename
        img.save(out, format="PNG", optimize=True)
        print(f"  ✓ {filename} ({size}×{size})")

    # Emit an .icns bundle. Pillow supports writing ICNS on all platforms.
    icns_sizes = [16, 32, 64, 128, 256, 512, 1024]
    icns_images = [master.resize((s, s), Image.Resampling.LANCZOS) for s in icns_sizes]
    icns_target = DMG_ASSETS / "AppIcon.icns"
    icns_images[0].save(icns_target, format="ICNS", append_images=icns_images[1:])
    print(f"✓ ICNS → {icns_target}")

    # Volume icon = same design (small mark identity so the mounted DMG matches).
    volume_target = DMG_ASSETS / "VolumeIcon.icns"
    icns_images[0].save(volume_target, format="ICNS", append_images=icns_images[1:])
    print(f"✓ Volume ICNS → {volume_target}")

    # Refresh Contents.json to reference the generated PNGs. This is idempotent.
    contents_json = ICONSET_DIR / "Contents.json"
    contents_json.write_text('''{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16",  "filename" : "icon_16x16.png"       },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16",  "filename" : "icon_16x16@2x.png"    },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32",  "filename" : "icon_32x32.png"       },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32",  "filename" : "icon_32x32@2x.png"    },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128","filename" : "icon_128x128.png"    },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128","filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256","filename" : "icon_256x256.png"    },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256","filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512","filename" : "icon_512x512.png"    },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512","filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')
    print("✓ Contents.json refreshed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
