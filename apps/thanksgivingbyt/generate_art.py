#!/usr/bin/env python3
"""
Generate pixel-art animation assets for ThanksgivingByt (64x32).

Creates 8-frame seamless animated WebP loops for:
- 'both': Pilgrim hat + Native American beaded feather
- 'pilgrim': Pilgrim hat with gold buckle
- 'feather': Native American feather headband
- 'none': Classic heritage wild turkey
"""

import base64
import os
from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
FRAME_COUNT = 8
FRAME_MS = 180

# ── Color Palette ─────────────────────────────────────────────────────────────
BG_NIGHT     = (18, 12, 26, 255)
TURQUOISE    = (26, 188, 156)
RUST_RED     = (198, 40, 40)
DARK_RED     = (142, 20, 20)
GOLD         = (245, 176, 65)
AMBER        = (235, 130, 40)
CHESTNUT     = (109, 76, 65)
DARK_BROWN   = (62, 39, 35)
LIGHT_BROWN  = (141, 110, 99)
BEAK_YELLOW  = (255, 202, 40)
FEET_ORANGE  = (245, 124, 0)
WHITE        = (248, 248, 248)
BLACK        = (24, 24, 24)
HAT_BLACK    = (20, 20, 20)
HAT_SHINE    = (55, 55, 55)
PUMPKIN_ORG  = (230, 81, 0)
PUMPKIN_LT   = (255, 140, 0)
STEM_GREEN   = (46, 125, 50)
LEAF_RED     = (211, 47, 47)
LEAF_GOLD    = (255, 193, 7)
LEAF_ORANGE  = (239, 108, 0)

SOIL_1       = (45, 28, 20)
SOIL_2       = (32, 20, 14)
SOIL_3       = (22, 14, 10)

def draw_frame(frame_idx, hat_style="both"):
    im = Image.new("RGBA", (64, 32), BG_NIGHT)
    
    # 1. Native American top ribbon pattern above turkey (x=0..26, y=0..1)
    ribbon = [TURQUOISE, RUST_RED, GOLD, WHITE, GOLD, RUST_RED, TURQUOISE, (18, 12, 26)]
    for x in range(27):
        im.putpixel((x, 0), ribbon[x % len(ribbon)])
        if (x % len(ribbon)) in (1, 2, 3, 4, 5):
            im.putpixel((x, 1), ribbon[(x + 4) % len(ribbon)])

    # 2. Autumn soil & grass line (y=28..31)
    for x in range(64):
        im.putpixel((x, 28), SOIL_1)
        im.putpixel((x, 29), SOIL_2)
        im.putpixel((x, 30), SOIL_3)
        im.putpixel((x, 31), (15, 10, 7))

    # Ground foliage & leaves
    im.putpixel((5, 28), LEAF_GOLD)
    im.putpixel((18, 28), LEAF_RED)
    im.putpixel((32, 28), (55, 80, 35))
    im.putpixel((49, 28), LEAF_ORANGE)

    # 3. Falling autumn leaves in the background (x=28..63)
    leaf_drifts = [
        (25 + (frame_idx * 2) % 6, 3 + (frame_idx * 3) % 22, LEAF_GOLD),
        (28 + (frame_idx * 1) % 4, 10 + (frame_idx * 3) % 15, LEAF_RED),
        (61 + (frame_idx * 1) % 2, 8 + (frame_idx * 2) % 16, LEAF_ORANGE),
    ]
    for lx, ly, col in leaf_drifts:
        if 27 <= lx < 63 and 2 <= ly < 28:
            im.putpixel((lx, ly), col)
            if ly + 1 < 28:
                im.putpixel((lx + 1, ly), col)

    # 4. Turkey Bob / Breathing Animation
    breathe = 1 if frame_idx in (1, 2, 5, 6) else 0

    # 5. Tail plumage (fanned out behind the body)
    fan_gold = [
        (2, 14), (3, 12), (4, 10), (6, 8), (8, 7), (10, 7), (12, 7), (14, 8), (16, 10), (17, 12), (18, 14)
    ]
    for fx, fy in fan_gold:
        im.putpixel((fx, fy - breathe), GOLD)

    fan_amber = [
        (3, 14), (4, 12), (5, 11), (5, 10), (7, 9), (9, 8), (11, 8), (13, 9), (15, 10), (15, 11), (16, 12), (17, 14)
    ]
    for fx, fy in fan_amber:
        im.putpixel((fx, fy - breathe), AMBER)

    fan_rust = [
        (4, 14), (5, 13), (6, 12), (6, 11), (8, 10), (10, 9), (12, 10), (14, 11), (14, 12), (15, 13), (16, 14)
    ]
    for fx, fy in fan_rust:
        im.putpixel((fx, fy - breathe), RUST_RED)

    # Dark base of tail
    for fy in range(12, 17):
        for fx in range(5, 16):
            dx = (fx - 10) / 5.5
            dy = (fy - 18) / 6.0
            if dx*dx + dy*dy <= 1.0 and im.getpixel((fx, fy - breathe)) == BG_NIGHT:
                im.putpixel((fx, fy - breathe), DARK_BROWN)

    # 6. Turkey Plump Body
    for fy in range(16, 26):
        for fx in range(7, 19):
            dx = (fx - 13) / 5.0
            dy = (fy - 21) / 4.5
            if dx*dx + dy*dy <= 1.0:
                im.putpixel((fx, fy), CHESTNUT)

    # Wing plumage
    for fy in range(18, 24):
        for fx in range(8, 14):
            dx = (fx - 11) / 2.8
            dy = (fy - 21) / 2.5
            if dx*dx + dy*dy <= 0.8:
                im.putpixel((fx, fy), LIGHT_BROWN)
    im.putpixel((10, 20), GOLD)
    im.putpixel((11, 21), GOLD)

    # 7. Neck & Breast
    for fy in range(14, 20):
        for fx in range(16, 20):
            im.putpixel((fx, fy), RUST_RED)

    # 8. Head
    for fy in range(10, 14):
        for fx in range(17, 22):
            im.putpixel((fx, fy), RUST_RED)

    # Eye: blinks on frame 6
    im.putpixel((19, 11), WHITE)
    im.putpixel((20, 11), BLACK if frame_idx != 6 else RUST_RED)

    # Beak: golden yellow
    im.putpixel((22, 11), BEAK_YELLOW)
    im.putpixel((23, 11), BEAK_YELLOW)
    im.putpixel((24, 11), GOLD)
    im.putpixel((22, 12), GOLD)

    # Snood / Wattle: wobbles!
    wobble = 1 if frame_idx in (2, 3, 6, 7) else 0
    im.putpixel((22, 13), DARK_RED)
    im.putpixel((22 + wobble, 14), RUST_RED)
    im.putpixel((21 + wobble, 15), DARK_RED)

    # 9. Hats / Accessories
    if hat_style in ("both", "pilgrim"):
        for fx in range(15, 23):
            im.putpixel((fx, 9), HAT_BLACK)
        for fy in range(5, 9):
            for fx in range(16, 22):
                im.putpixel((fx, fy), HAT_BLACK)
        im.putpixel((17, 6), HAT_SHINE)
        im.putpixel((17, 7), HAT_SHINE)
        for fx in range(16, 22):
            im.putpixel((fx, 8), DARK_BROWN)
        im.putpixel((19, 8), GOLD)
        im.putpixel((19, 7), GOLD)

    if hat_style in ("both", "feather"):
        if hat_style == "both":
            im.putpixel((15, 8), TURQUOISE)
            im.putpixel((14, 7), RUST_RED)
            im.putpixel((14, 6), WHITE)
            im.putpixel((13, 5), WHITE)
            im.putpixel((13, 4), BLACK)
        else:
            for fx in range(17, 22):
                im.putpixel((fx, 10), TURQUOISE if fx % 2 == 0 else RUST_RED)
            im.putpixel((18, 9), GOLD)
            im.putpixel((18, 8), WHITE)
            im.putpixel((18, 7), WHITE)
            im.putpixel((18, 6), BLACK)

    # 10. Turkey Feet
    im.putpixel((11, 25), FEET_ORANGE)
    im.putpixel((11, 26), FEET_ORANGE)
    im.putpixel((10, 27), FEET_ORANGE)
    im.putpixel((11, 27), FEET_ORANGE)
    im.putpixel((12, 27), FEET_ORANGE)

    im.putpixel((15, 25), FEET_ORANGE)
    im.putpixel((15, 26), FEET_ORANGE)
    im.putpixel((14, 27), FEET_ORANGE)
    im.putpixel((15, 27), FEET_ORANGE)
    im.putpixel((16, 27), FEET_ORANGE)

    # 11. Harvest Pumpkin near turkey
    im.putpixel((25, 24), STEM_GREEN)
    for py in range(25, 28):
        for px in range(23, 27):
            im.putpixel((px, py), PUMPKIN_ORG)
    im.putpixel((24, 26), PUMPKIN_LT)

    return im

def build_all():
    styles = ["both", "pilgrim", "feather", "none"]
    webp_b64 = {}
    for style in styles:
        frames = [draw_frame(i, style) for i in range(FRAME_COUNT)]
        out_path = os.path.join(ROOT, f"turkey_{style}.webp")
        frames[0].save(
            out_path,
            save_all=True,
            append_images=frames[1:],
            duration=FRAME_MS,
            loop=0,
            lossless=True,
        )
        data = open(out_path, "rb").read()
        b64 = base64.b64encode(data).decode("ascii")
        webp_b64[style] = b64
        print(f"Generated {out_path} ({len(data)} bytes, {len(b64)} b64 chars)")

    return webp_b64

if __name__ == "__main__":
    build_all()
