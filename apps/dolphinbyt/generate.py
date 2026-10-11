#!/usr/bin/env python3
"""
DolphinByt - a bright bubblegum-pink dolphin arcing through the deep (64x32).

The scene is underwater: a teal-to-deep-blue gradient lit by slow drifting god
rays, with bubbles rising and seaweed swaying along the seabed. A single pink
dolphin porpoises across the screen in a graceful leaping arc, tilting to follow
its path, then slips off the edge so the loop is seamless.

Every animated quantity is periodic over FRAMES (sine waves and integer wraps),
so frame N tiles cleanly back into frame 0.

Sprite source (checked in this order, all optional):
  sprites/dolphin_frames/*.png  -> animated swim cycle (one PNG per frame)
  sprites/dolphin.png           -> single still sprite
  (neither present)             -> a built-in procedural placeholder is drawn,
                                   so you can preview the motion before the real
                                   PixelLab art exists.

Outputs:
  out/dolphin.webp  -> push this to the Tidbyt (animated WebP, 64x32)
  out/dolphin.gif   -> quick preview
  out/preview.png   -> single still (6x upscale) for eyeballing
"""

import glob
import math
import os

from PIL import Image, ImageDraw

W, H = 64, 32
FRAMES = 75            # 75 frames
FRAME_MS = 90          # ~6.75s loop. Also drives the .star playback delay.
OUT = os.path.join(os.path.dirname(__file__), "out")
SPRITES = os.path.join(os.path.dirname(__file__), "sprites")

# Target on-screen height of the dolphin in pixels. The sprite is scaled to this
# (preserving aspect) with NEAREST so it stays crisply pixel-art.
DOLPHIN_H = 16

# ---------------------------------------------------------------- palette ----
# Deep, cool water so a hot-pink dolphin pops hard against it.
WATER_TOP = (38, 150, 168)    # sunlit teal near the surface
WATER_MID = (24, 96, 150)     # mid-water blue
WATER_LOW = (12, 46, 96)      # deep blue at the bottom
RAY = (150, 230, 235)         # pale god-ray light (blended translucently)
BUBBLE = (200, 240, 248)
BUBBLE_HI = (240, 252, 255)
SEABED = (18, 60, 78)         # darker silhouette band along the floor
WEED = (28, 120, 96)          # seaweed
WEED_DK = (18, 92, 74)

# Placeholder dolphin colors (only used if no sprite PNG is supplied).
PINK = (255, 105, 180)        # bright bubblegum pink
PINK_DK = (224, 72, 148)      # shaded underside
PINK_LT = (255, 170, 210)     # highlight
BELLY = (255, 214, 232)       # pale pink belly
EYE = (40, 20, 40)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def blend(base, over, alpha):
    """Alpha-composite an RGB `over` onto an RGB `base`."""
    return tuple(int(round(base[i] + (over[i] - base[i]) * alpha)) for i in range(3))


# ------------------------------------------------------------- background ----
def water_gradient():
    """Static vertical water gradient as a list of per-row RGB colors."""
    rows = []
    for y in range(H):
        t = y / (H - 1)
        if t < 0.5:
            c = lerp(WATER_TOP, WATER_MID, t / 0.5)
        else:
            c = lerp(WATER_MID, WATER_LOW, (t - 0.5) / 0.5)
        rows.append(c)
    return rows


GRADIENT = water_gradient()


def draw_background(frame_idx):
    """Build the looping underwater backdrop for a given frame."""
    img = Image.new("RGB", (W, H))
    px = img.load()

    phase = frame_idx / FRAMES  # 0..1 over the loop

    # Base gradient.
    for y in range(H):
        c = GRADIENT[y]
        for x in range(W):
            px[x, y] = c

    # God rays: soft diagonal light bands that drift slowly sideways. Brightest
    # near the surface, fading with depth. Drift is a full integer wrap over the
    # loop so it tiles seamlessly.
    drift = phase * W
    for x in range(W):
        for y in range(H):
            # Diagonal coordinate; rays slope down-right.
            d = (x + drift - y * 0.6) % 22
            band = max(0.0, 1.0 - abs(d - 11) / 6.0)  # triangular falloff
            if band <= 0:
                continue
            depth_fade = max(0.0, 1.0 - y / (H * 0.9))
            a = 0.16 * band * depth_fade
            if a > 0.002:
                px[x, y] = blend(px[x, y], RAY, a)

    def setpx(x, y, col, a=0.9):
        if 0 <= x < W and 0 <= y < H:
            px[x, y] = blend(px[x, y], col, a)

    # Seabed silhouette + swaying seaweed along the bottom.
    bed_y = H - 3
    for x in range(W):
        for y in range(bed_y, H):
            px[x, y] = blend(px[x, y], SEABED, 0.7)

    sway = math.sin(phase * 2 * math.pi)
    for base_x, height, ph in ((8, 9, 0.0), (24, 6, 1.4), (52, 8, 2.7), (40, 5, 4.0)):
        for i in range(height):
            yy = H - 1 - i
            bend = sway * (i / height) * 2.5
            xx = int(round(base_x + bend + math.sin(ph + i * 0.5) * 0.6))
            col = WEED if i % 2 == 0 else WEED_DK
            if 0 <= xx < W and 0 <= yy < H:
                px[xx, yy] = col
                if xx + 1 < W:
                    px[xx + 1, yy] = blend(px[xx + 1, yy], col, 0.5)

    # Rising bubbles. Each bubble rises and wraps vertically once per loop, so
    # the field is seamless. Horizontal wobble keeps them lively.
    bubbles = [
        (10, 0.00, 1), (18, 0.35, 1), (30, 0.65, 2),
        (44, 0.15, 1), (50, 0.80, 1), (58, 0.45, 2), (6, 0.55, 1),
    ]
    for bx, off, r in bubbles:
        prog = (phase + off) % 1.0
        by = int((H + 4) * (1.0 - prog)) - 2  # rise from bottom to top
        wob = int(round(math.sin((phase + off) * 4 * math.pi) * 1.5))
        cx = bx + wob
        if r <= 1:
            # Small bubble: a single soft dot with a tiny glint above it.
            setpx(cx, by, BUBBLE, 0.85)
            setpx(cx, by - 1, BUBBLE_HI, 0.35)
        else:
            # Big bubble: a compact 2x2 cluster reads as a round droplet on the
            # LED matrix (a 3x3 outline would render as a + / crosshair).
            setpx(cx, by, BUBBLE, 0.85)
            setpx(cx - 1, by, BUBBLE, 0.85)
            setpx(cx - 1, by - 1, BUBBLE, 0.7)
            setpx(cx, by - 1, BUBBLE_HI, 0.85)  # top-right glint

    return img


# ------------------------------------------------------- dolphin sprite -------
def _placeholder_dolphin():
    """A simple right-facing pink dolphin drawn procedurally (RGBA).

    Only used until real PixelLab art is dropped into sprites/. Good enough to
    judge the arc motion and composition.
    """
    s = 32
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body: a tapering crescent. Drawn as an ellipse plus a tail.
    d.ellipse([4, 10, 26, 22], fill=PINK)
    d.ellipse([3, 11, 20, 21], fill=PINK)          # belly bulge toward the head
    # Snout
    d.polygon([(24, 14), (31, 13), (24, 18)], fill=PINK)
    # Belly highlight
    d.ellipse([6, 15, 20, 21], fill=BELLY)
    # Dorsal fin
    d.polygon([(13, 10), (17, 3), (18, 10)], fill=PINK_DK)
    # Tail flukes
    d.polygon([(2, 12), (6, 16), (2, 20), (5, 16)], fill=PINK_DK)
    d.polygon([(4, 16), (0, 11), (1, 16), (0, 21)], fill=PINK)
    # Pectoral fin
    d.polygon([(14, 19), (12, 24), (18, 20)], fill=PINK_DK)
    # Top highlight
    d.line([(8, 11), (22, 12)], fill=PINK_LT)
    # Eye
    d.point((23, 14), fill=EYE)
    d.point((22, 14), fill=EYE)
    return img


def load_dolphin_frames():
    """Return a list of RGBA dolphin frames scaled to DOLPHIN_H, facing right."""
    paths = sorted(glob.glob(os.path.join(SPRITES, "dolphin_frames", "*.png")))
    if not paths:
        single = os.path.join(SPRITES, "dolphin.png")
        if os.path.exists(single):
            paths = [single]

    if paths:
        raw = [Image.open(p).convert("RGBA") for p in paths]
    else:
        print("  (no sprite found in sprites/ - using procedural placeholder)")
        raw = [_placeholder_dolphin()]

    # Compute a SHARED bounding box and a SHARED scale across every frame. Doing
    # this per-frame would re-fit each frame's own content to DOLPHIN_H, which
    # cancels the swim cycle's vertical body-flex and makes the sprite jitter in
    # size. A common crop+scale keeps the animation's relative motion intact.
    if all(im.size == raw[0].size for im in raw):
        boxes = [im.getbbox() for im in raw if im.getbbox()]
        if boxes:
            union = (
                min(b[0] for b in boxes), min(b[1] for b in boxes),
                max(b[2] for b in boxes), max(b[3] for b in boxes),
            )
            raw = [im.crop(union) for im in raw]
        scale = DOLPHIN_H / raw[0].height
        new_w = max(1, int(round(raw[0].width * scale)))
        return [im.resize((new_w, DOLPHIN_H), Image.NEAREST) for im in raw]

    # Fallback: differing canvas sizes -> trim and scale each independently.
    frames = []
    for im in raw:
        bbox = im.getbbox()
        if bbox:
            im = im.crop(bbox)
        scale = DOLPHIN_H / im.height
        new_w = max(1, int(round(im.width * scale)))
        frames.append(im.resize((new_w, DOLPHIN_H), Image.NEAREST))
    return frames


# --------------------------------------------------------------- compose ----
def dolphin_pose(phase):
    """Return (cx, cy, angle_deg) for the dolphin center at loop fraction phase.

    The dolphin travels left->right once per loop (off-screen at both ends, so
    the wrap is invisible) and follows a leaping arc: it rises to an apex near
    center then dives back down. The sprite tilts to point along its path.
    """
    margin = DOLPHIN_H + 6
    cx = -margin + (W + 2 * margin) * phase

    # Arc: a single up-and-over bump using a sine half-cycle, biased so the apex
    # sits a bit above mid-water.
    arc = math.sin(phase * math.pi)        # 0 -> 1 -> 0
    baseline = H * 0.62
    apex_rise = 16
    cy = baseline - arc * apex_rise

    # Tilt follows the slope of the path: nose-up on the way up, nose-down on the
    # way down. Derivative of the arc gives the slope sign.
    slope = math.cos(phase * math.pi)      # +1 ascending .. -1 descending
    angle = slope * 24.0                   # degrees, gentle tilt
    return cx, cy, angle


def compose():
    frames_sprite = load_dolphin_frames()
    out_frames = []
    for i in range(FRAMES):
        phase = i / FRAMES
        bg = draw_background(i)

        cx, cy, angle = dolphin_pose(phase)
        sprite = frames_sprite[i % len(frames_sprite)]
        # Rotate to follow the arc. expand=True keeps the whole sprite.
        rot = sprite.rotate(angle, resample=Image.BICUBIC, expand=True)
        # Harden the alpha edge so rotation doesn't leave a soft pink halo.
        r, g, b, a = rot.split()
        a = a.point(lambda v: 255 if v > 110 else 0)
        rot = Image.merge("RGBA", (r, g, b, a))

        px = int(round(cx - rot.width / 2))
        py = int(round(cy - rot.height / 2))
        bg.paste(rot, (px, py), rot)
        out_frames.append(bg)
    return out_frames


# ----------------------------------------------------------------- write ----
def main():
    os.makedirs(OUT, exist_ok=True)
    frames = compose()

    webp_path = os.path.join(OUT, "dolphin.webp")
    frames[0].save(
        webp_path,
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_MS,
        loop=0,
        lossless=True,
        method=6,
    )
    gif_path = os.path.join(OUT, "dolphin.gif")
    frames[0].save(
        gif_path,
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_MS,
        loop=0,
        disposal=2,
    )
    preview = frames[len(frames) // 4].resize((W * 6, H * 6), Image.NEAREST)
    preview.save(os.path.join(OUT, "preview.png"))

    print("Wrote {} ({} frames, {}x{}, {}ms/frame)".format(
        webp_path, len(frames), W, H, FRAME_MS))
    print("Preview: out/dolphin.gif and out/preview.png")


if __name__ == "__main__":
    main()
