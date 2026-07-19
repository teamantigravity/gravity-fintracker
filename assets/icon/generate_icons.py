#!/usr/bin/env python3
"""
Gravity Fintracker icon generator.

Design: four ascending bars (Red -> Yellow -> Green -> Blue) on a deep navy
background — an unmistakable "financial growth / tracking" glyph rendered in
Google's brand palette. Regenerate all platform assets from one source of
truth whenever the design changes.

Usage: python3 assets/icon/generate_icons.py
Requires: pip install cairosvg pillow
"""
import os
import cairosvg
from PIL import Image
import io

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BLUE = "#4285F4"
RED = "#EA4335"
YELLOW = "#FBBC05"
GREEN = "#34A853"
BG_TOP = "#1B2044"
BG_BOTTOM = "#0A0C1B"

# ---------------------------------------------------------------------------
# Master flat icon (full-bleed square, 1024x1024). Used for iOS / macOS /
# Windows / Web / legacy Android raster fallbacks. Platform OS applies its
# own corner mask, so we keep generous margins (bars occupy ~60% width).
# ---------------------------------------------------------------------------
def master_svg(size=1024, rounded=False, corner_radius=0):
    bars = [
        (202, 600, 790, RED),
        (372, 480, 790, YELLOW),
        (542, 360, 790, GREEN),
        (712, 240, 790, BLUE),
    ]
    bar_paths = []
    w = 110
    r = 28
    for x, top, bottom, color in bars:
        x2 = x + w
        path = (
            f"M{x},{bottom} L{x},{top+r} A{r},{r} 0 0 1 {x+r},{top} "
            f"L{x2-r},{top} A{r},{r} 0 0 1 {x2},{top+r} L{x2},{bottom} Z"
        )
        bar_paths.append(f'<path d="{path}" fill="{color}"/>')

    bg_shape = (
        f'<rect width="1024" height="1024" rx="{corner_radius}" ry="{corner_radius}" fill="url(#bg)"/>'
        if rounded else
        '<rect width="1024" height="1024" fill="url(#bg)"/>'
    )

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{BG_TOP}"/>
      <stop offset="1" stop-color="{BG_BOTTOM}"/>
    </linearGradient>
  </defs>
  {bg_shape}
  {"".join(bar_paths)}
</svg>'''
    return svg


def render_png(svg_string, out_path, size, strip_alpha=False, bg_fallback="#0A0C1B"):
    png_bytes = cairosvg.svg2png(bytestring=svg_string.encode("utf-8"), output_width=size, output_height=size)
    img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    if strip_alpha:
        flat = Image.new("RGB", img.size, bg_fallback)
        flat.paste(img, mask=img.split()[3])
        flat.save(out_path, "PNG")
    else:
        img.save(out_path, "PNG")
    print(f"  {out_path}  ({size}x{size})")


# ---------------------------------------------------------------------------
# iOS — sizes derived from Contents.json (point-size @ scale = pixels)
# ---------------------------------------------------------------------------
IOS_DIR = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
IOS_ICONS = {
    "AppIcon@2x.png": 120, "AppIcon@3x.png": 180,
    "AppIcon~ipad.png": 76, "AppIcon@2x~ipad.png": 152,
    "AppIcon-83.5@2x~ipad.png": 167,
    "AppIcon-40@2x.png": 80, "AppIcon-40@3x.png": 120,
    "AppIcon-40~ipad.png": 40, "AppIcon-40@2x~ipad.png": 80,
    "AppIcon-20@2x.png": 40, "AppIcon-20@3x.png": 60,
    "AppIcon-20~ipad.png": 20, "AppIcon-20@2x~ipad.png": 40,
    "AppIcon-29.png": 29, "AppIcon-29@2x.png": 58, "AppIcon-29@3x.png": 87,
    "AppIcon-29~ipad.png": 29, "AppIcon-29@2x~ipad.png": 58,
    "AppIcon-60@2x~car.png": 120, "AppIcon-60@3x~car.png": 180,
    "AppIcon~ios-marketing.png": 1024,
}

# ---------------------------------------------------------------------------
# macOS — proper `mac` idiom set (the previous Contents.json incorrectly
# reused iOS iphone/ipad/car idioms and had NO valid mac icon at all).
# ---------------------------------------------------------------------------
MACOS_DIR = os.path.join(ROOT, "macos/Runner/Assets.xcassets/AppIcon.appiconset")
MACOS_ICONS = {
    "app_icon_16.png": 16, "app_icon_32.png": 32,
    "app_icon_64.png": 64, "app_icon_128.png": 128,
    "app_icon_256.png": 256, "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}
MACOS_CONTENTS_JSON = '''{
  "images" : [
    { "filename" : "app_icon_16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "app_icon_32.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "app_icon_32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "app_icon_64.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "app_icon_128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "app_icon_256.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "app_icon_256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "app_icon_512.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "app_icon_512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "app_icon_1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "gravity-fintracker", "version" : 1 }
}
'''

# ---------------------------------------------------------------------------
# Android legacy raster fallback (API < 26 has no adaptive icon support)
# ---------------------------------------------------------------------------
ANDROID_DIR = os.path.join(ROOT, "android/app/src/main/res")
ANDROID_LEGACY = {
    "mipmap-mdpi": 48, "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96, "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192,
}

# ---------------------------------------------------------------------------
# Web
# ---------------------------------------------------------------------------
WEB_DIR = os.path.join(ROOT, "web")

# ---------------------------------------------------------------------------
# Windows ICO (multi-resolution)
# ---------------------------------------------------------------------------
WINDOWS_ICO = os.path.join(ROOT, "windows/runner/resources/app_icon.ico")


def main():
    flat_svg = master_svg()

    print("iOS icons:")
    os.makedirs(IOS_DIR, exist_ok=True)
    for fname, px in IOS_ICONS.items():
        render_png(flat_svg, os.path.join(IOS_DIR, fname), px, strip_alpha=True)

    print("macOS icons:")
    os.makedirs(MACOS_DIR, exist_ok=True)
    # Clear stale iOS-shaped files from the old (incorrect) iconset
    for stale in os.listdir(MACOS_DIR):
        if stale != "Contents.json":
            os.remove(os.path.join(MACOS_DIR, stale))
    for fname, px in MACOS_ICONS.items():
        render_png(flat_svg, os.path.join(MACOS_DIR, fname), px, strip_alpha=False)
    with open(os.path.join(MACOS_DIR, "Contents.json"), "w") as f:
        f.write(MACOS_CONTENTS_JSON)
    print(f"  Contents.json rewritten with correct 'mac' idiom entries")

    print("Android legacy raster icons:")
    for folder, px in ANDROID_LEGACY.items():
        d = os.path.join(ANDROID_DIR, folder)
        os.makedirs(d, exist_ok=True)
        render_png(flat_svg, os.path.join(d, "ic_launcher.png"), px, strip_alpha=False)
        render_png(flat_svg, os.path.join(d, "ic_launcher_round.png"), px, strip_alpha=False)

    print("Web icons:")
    os.makedirs(os.path.join(WEB_DIR, "icons"), exist_ok=True)
    render_png(flat_svg, os.path.join(WEB_DIR, "favicon.png"), 64, strip_alpha=False)
    render_png(flat_svg, os.path.join(WEB_DIR, "icons/Icon-192.png"), 192, strip_alpha=False)
    render_png(flat_svg, os.path.join(WEB_DIR, "icons/Icon-512.png"), 512, strip_alpha=False)
    # Maskable icons need extra safe-zone padding (~20%) since OS may crop to a circle
    maskable_svg = master_svg()
    render_png(maskable_svg, os.path.join(WEB_DIR, "icons/Icon-maskable-192.png"), 192, strip_alpha=False)
    render_png(maskable_svg, os.path.join(WEB_DIR, "icons/Icon-maskable-512.png"), 512, strip_alpha=False)

    print("Windows ICO:")
    os.makedirs(os.path.dirname(WINDOWS_ICO), exist_ok=True)
    sizes = [16, 32, 48, 64, 128, 256]
    imgs = []
    for s in sizes:
        png_bytes = cairosvg.svg2png(bytestring=flat_svg.encode("utf-8"), output_width=s, output_height=s)
        imgs.append(Image.open(io.BytesIO(png_bytes)).convert("RGBA"))
    imgs[0].save(WINDOWS_ICO, format="ICO", sizes=[(s, s) for s in sizes], append_images=imgs[1:])
    print(f"  {WINDOWS_ICO}  ({sizes})")

    # Master source SVG + a 1024 PNG for docs / Play Store listing / press kit
    os.makedirs(os.path.join(ROOT, "assets/icon"), exist_ok=True)
    with open(os.path.join(ROOT, "assets/icon/icon_master.svg"), "w") as f:
        f.write(flat_svg)
    render_png(flat_svg, os.path.join(ROOT, "assets/icon/icon_1024.png"), 1024, strip_alpha=False)

    print("\nDone.")


if __name__ == "__main__":
    main()
