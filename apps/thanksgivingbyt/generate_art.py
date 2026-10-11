#!/usr/bin/env python3
"""
Generate pixel-art animation assets for ThanksgivingByt (64x32).

Creates 8-frame seamless animated WebP loops for:
- 'both': Pilgrim hat + Native American beaded feather
- 'pilgrim': Pilgrim hat with gold buckle
- 'feather': Native American feather headband
- 'none': Classic heritage wild turkey

Layout: the turkey scene owns x=0..25; x=27..63 is left empty for the
countdown text drawn by the .star file. A beaded ribbon (y=0) and the soil
strip (y=29..31) span the full width so both halves read as one scene.
"""

import base64
import math
import os
from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
FRAME_COUNT = 8
FRAME_MS = 180

# ── Color Palette ─────────────────────────────────────────────────────────────
BG_NIGHT     = (18, 12, 26)
TURQUOISE    = (26, 188, 156)
RUST_RED     = (198, 40, 40)
DARK_RED     = (142, 20, 20)
GOLD         = (245, 176, 65)
AMBER        = (235, 130, 40)
CREAM        = (255, 224, 178)
CHESTNUT     = (109, 76, 65)
DARK_BROWN   = (62, 39, 35)
DEEP_BROWN   = (44, 27, 24)
LIGHT_BROWN  = (141, 110, 99)
BEAK_YELLOW  = (255, 202, 40)
FEET_ORANGE  = (245, 124, 0)
WHITE        = (248, 248, 248)
BLACK        = (24, 24, 24)
HAT_BLACK    = (28, 26, 30)
HAT_SHINE    = (70, 68, 76)
PUMPKIN_ORG  = (230, 81, 0)
PUMPKIN_DK   = (180, 60, 0)
PUMPKIN_LT   = (255, 140, 0)
STEM_GREEN   = (46, 125, 50)
LEAF_RED     = (211, 47, 47)
LEAF_GOLD    = (255, 193, 7)
LEAF_ORANGE  = (239, 108, 0)

SOIL_1       = (58, 36, 24)
SOIL_2       = (40, 25, 17)
SOIL_3       = (26, 16, 11)

GROUND_Y = 29  # first soil row; feet stand on y=28

# Tail feathers alternate colors across the fan, left to right.
FEATHER_COLORS = [RUST_RED, AMBER, GOLD, RUST_RED, AMBER, GOLD, AMBER, RUST_RED]

# Hand-drawn sprites: '.' is transparent.
SPRITE_PALETTE = {
    "C": CHESTNUT, "D": DARK_BROWN, "E": DEEP_BROWN, "L": LIGHT_BROWN,
    "G": GOLD, "R": RUST_RED, "d": DARK_RED, "W": WHITE, "K": BLACK,
    "Y": BEAK_YELLOW, "y": GOLD, "O": FEET_ORANGE,
    "H": HAT_BLACK, "h": HAT_SHINE, "b": DARK_BROWN, "g": GOLD,
    "T": TURQUOISE, "c": CREAM,
}

# Body + wing, anchored at (3, 16).
BODY = [
    "....DDDDDDDD.....",
    "..DDCCCCCCCCDD...",
    ".DCCLLLLCCCCCCD..",
    "DCCLcLLLLLCCCCCD.",
    "DCLLLGLLLLLCCCCD.",
    "DCLLLLLGLLLLCCCD.",
    "DCCLLLLLLLLCCCCD.",
    ".DCCLLLLLLCCCCD..",
    "..DCCCCCCCCCCD...",
    "....DDDDDDDD.....",
]

# Neck + head facing right, anchored at (13, 7). Eye pixel is 'K'.
HEAD = [
    "..dRRR...",
    ".dRRRRR..",
    ".dRWKRRYY",
    ".dRRRRRy.",
    "..dRRRd..",
    "..dRRd...",
    "..dRR....",
    ".dRRR....",
    ".dRRR....",
    "dRRR.....",
]

PILGRIM_HAT = [  # anchored at (13, 2): crown on the head, brim at y=6
    "..HHHH..",
    "..HhHH..",
    "..HhHH..",
    "..bgbb..",
    "HHHHHHH.",
]

LEGS = [  # anchored at (7, 26)
    "..O....O...",
    "..O....O...",
    ".OOO..OOO..",
]

PUMPKIN = [  # anchored at (19, 24)
    "...TT.",
    ".DOOOD",
    "OOLOOO",
    "OOLOOO",
    ".OOOO.",
]
PUMPKIN_PALETTE = {"T": STEM_GREEN, "O": PUMPKIN_ORG, "D": PUMPKIN_DK, "L": PUMPKIN_LT}


def blit(im, sprite, ox, oy, palette=SPRITE_PALETTE):
    for y, row in enumerate(sprite):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            px, py = ox + x, oy + y
            if 0 <= px < 64 and 0 <= py < 32:
                im.putpixel((px, py), palette[ch])


def blit_outline(im, sprite, ox, oy, color=DEEP_BROWN):
    """Paint a 1px silhouette ring so a sprite separates from what is behind it."""
    for y, row in enumerate(sprite):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                px, py = ox + nx, oy + ny
                if 0 <= px < 64 and 2 <= py < GROUND_Y and im.getpixel((px, py)) != BG_NIGHT:
                    im.putpixel((px, py), color)


def draw_fan(im, lift):
    """Fanned tail: alternating colored feathers with rounded tips and a dark core."""
    cx, cy = 10.5, 18.0 - lift
    outer = 12.5
    n = len(FEATHER_COLORS)
    for y in range(2, 22):
        for x in range(0, 24):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            if dy > 0.5:
                continue
            r = math.hypot(dx, dy)
            ang = math.atan2(-dy, dx)  # 0 = right, pi = left
            ang = min(max(ang, 0.0), math.pi)
            idx = min(int((math.pi - ang) / math.pi * n), n - 1)
            # Position within the feather wedge, 0 at seam .. 1 at center.
            frac = ((math.pi - ang) / math.pi * n) % 1.0
            edge = 1.0 - abs(frac - 0.5) * 2
            tip = outer - 1.6 * (1 - edge) ** 2
            if r > tip:
                continue
            if r < 4.0:
                col = DEEP_BROWN
            elif r < 5.5:
                col = DARK_BROWN
            elif r > tip - 1.3:
                col = CREAM if FEATHER_COLORS[idx] == GOLD else GOLD
            elif r > tip - 2.3:
                col = DARK_BROWN  # dark band below the light tip
            else:
                col = FEATHER_COLORS[idx]
            im.putpixel((x, y), col)


def draw_frame(frame_idx, hat_style="both"):
    im = Image.new("RGB", (64, 32), BG_NIGHT)

    # 1. Beaded ribbon across the full top edge.
    beads = [TURQUOISE, RUST_RED, GOLD, CREAM, GOLD, RUST_RED, TURQUOISE, BG_NIGHT]
    for x in range(64):
        im.putpixel((x, 0), beads[x % len(beads)])

    # 2. Soil strip across the full width.
    for x in range(64):
        im.putpixel((x, GROUND_Y), SOIL_1)
        im.putpixel((x, GROUND_Y + 1), SOIL_2)
        im.putpixel((x, GROUND_Y + 2), SOIL_3)
    for lx, col in ((1, LEAF_GOLD), (25, LEAF_RED), (40, LEAF_ORANGE), (57, LEAF_GOLD)):
        im.putpixel((lx, GROUND_Y), col)

    # 3. Leaves drifting down behind the turkey (seamless 8-frame loop).
    for x0, y0, sway, col in ((2, 3, 0, LEAF_GOLD), (22, 13, 4, LEAF_ORANGE)):
        ly = 2 + (y0 + frame_idx * 3) % 24
        lx = x0 + (1 if (frame_idx + sway) % 8 < 4 else 0)
        im.putpixel((lx, ly), col)

    # 4. Breathing: tail and body lift together; head bobs on its own beat.
    lift = 1 if frame_idx in (2, 3, 4, 5) else 0
    bob = 1 if frame_idx in (3, 4) else 0

    draw_fan(im, lift)
    blit(im, LEGS, 7, 26)
    blit(im, BODY, 3, 16 - lift)
    blit_outline(im, HEAD, 13 + bob, 7 - lift)
    blit(im, HEAD, 13 + bob, 7 - lift)

    # Blink on frame 6.
    if frame_idx == 6:
        im.putpixel((13 + bob + 4, 9 - lift), RUST_RED)

    # Wattle wobble.
    wob = 1 if frame_idx in (1, 2, 5, 6) else 0
    im.putpixel((13 + bob + 6 + wob, 13 - lift), DARK_RED)

    # 5. Hats / accessories (move with the head).
    hx, hy = 13 + bob, 7 - lift
    if hat_style in ("both", "pilgrim"):
        blit(im, PILGRIM_HAT, hx, hy - 5)
    if hat_style in ("both", "feather"):
        if hat_style == "feather":
            for i, fx in enumerate(range(hx + 1, hx + 7)):
                im.putpixel((fx, hy + 1), TURQUOISE if i % 2 == 0 else GOLD)
            fx, top = hx + 2, hy - 3
        else:
            # Tucked into the hat band, behind the crown.
            fx, top = hx + 1, hy - 6
        im.putpixel((fx, top), BLACK)
        im.putpixel((fx, top + 1), WHITE)
        im.putpixel((fx, top + 2), WHITE)
        im.putpixel((fx, top + 3), RUST_RED)

    # 6. Harvest pumpkin at the turkey's feet.
    blit(im, PUMPKIN, 19, 24, PUMPKIN_PALETTE)

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
