#!/usr/bin/env python3
"""
TropicByt — animated tropical sunset beach loop for a Tidbyt (64x32).

Hand-authored pixel art with a mathematically seamless loop: every animated
quantity is periodic over FRAMES (sine waves and integer wraps), so frame N
tiles cleanly back into frame 0.

Two render profiles share this one scene (see PROFILES):

  tidbyt — 64x32, 96 frames @ 200ms. The Tidbyt panel is physically 64x32, so
           these numbers are fixed by hardware. build_star.py imports this
           module and reads FRAME_MS, so the defaults must stay tidbyt's.
  tv     — 64x36 (native 16:9), 576 frames @ 33ms (30fps) for an Android TV
           screensaver. Same 19.2s loop, just sampled 6x finer.

Because every animated quantity is a function of `phase` rather than a baked
keyframe, re-rendering at a higher frame count costs nothing but time — the
motion simply gets smoother.

Outputs:
  out/beach.webp  -> push this to the Tidbyt (animated WebP, 64x32)
  out/beach.gif   -> quick preview
  out/preview.png -> single still (4x upscale) for eyeballing
  out/tropicbyt-4k.mp4 -> 3840x2160 screensaver loop (64x36 scaled 60x)
  out/tropicbyt-wallpaper-2560x1600.png -> native 16:10 desktop wallpaper
  out/tropicbyt-wallpaper-4k.png         -> 16:9 4K desktop wallpaper
"""

import argparse
import math
import os
import shutil
import subprocess

from PIL import Image

# Canvas + timing. These are module globals because the drawing routines read
# them directly; apply_profile() rebinds the whole set. Defaults are tidbyt's
# so `import generate` (as build_star.py does) always sees panel values.
W, H = 64, 32
FRAMES = 96  # 96 frames
FRAME_MS = 200  # ~19.2s loop — long loop so the constant-speed boat drifts
# lazily across; other motions run 2 cycles/loop to keep
# their pace. FRAME_MS also drives the .star playback delay.

PROFILES = {
    # h, horizon and sand_top are the only geometry that differs; everything
    # else is derived so the composition holds its proportions on both canvases.
    "tidbyt": dict(h=32, frames=96, frame_ms=200, horizon=15, sand_top=26),
    "tv": dict(h=36, frames=576, frame_ms=33, horizon=17, sand_top=29),
    "wallpaper": dict(h=40, frames=576, frame_ms=33, horizon=19, sand_top=32),
}

# 64x36 scaled 60x lands exactly on 3840x2160 — a clean integer upscale, so
# every source pixel becomes a perfect 60x60 block with no resampling blur.
TV_SCALE = 60

OUT = os.path.join(os.path.dirname(__file__), "out")

# ---------------------------------------------------------------- palette ----
# Golden-hour sunset, few bold colors so it reads from across a room.
SKY_TOP = (74, 42, 92)  # dusky violet
SKY_MID = (196, 78, 92)  # rose
SKY_LOW = (244, 150, 92)  # warm orange
SKY_HORIZ = (255, 209, 128)  # pale gold at the horizon
SUN_CORE = (255, 245, 200)
SUN_BODY = (255, 214, 110)
SUN_EDGE = (255, 170, 80)
SEA_FAR = (70, 120, 150)  # cooler far water
SEA_NEAR = (38, 96, 132)
SEA_DARK = (28, 74, 110)
GLINT = (255, 224, 150)  # sun reflection on water
GLINT_HOT = (255, 246, 214)
SAND_LIGHT = (240, 206, 140)
SAND_DARK = (214, 170, 104)
FOAM = (240, 244, 238)
FOAM_SOFT = (212, 226, 222)  # thinner, draining foam
SHALLOW = (96, 174, 180)  # thin sheet of water washed over the sand
SHALLOW_LT = (140, 200, 200)  # sun-caught shallow water
WET_SAND = (196, 150, 92)  # sand the water just left behind
TRUNK = (120, 78, 48)
TRUNK_DK = (92, 58, 36)
FROND = (38, 132, 86)
FROND_DK = (26, 100, 64)
FROND_LT = (96, 190, 120)  # sun-caught highlight on the upper fronds
COCONUT = (150, 104, 58)
CLOUD = (255, 198, 168)
# --- pirate ship sprite (PixelLab generated) -----------------------------
# 14x14 RGBA, downscaled with NEAREST from 48x48 original.
PIRATE_SPRITE = [
    (6, 0, (5, 9, 9)),
    (6, 1, (19, 21, 18)),
    (6, 2, (80, 65, 48)),
    (7, 2, (0, 6, 6)),
    (4, 3, (0, 6, 6)),
    (5, 3, (18, 26, 25)),
    (6, 3, (18, 26, 25)),
    (7, 3, (27, 29, 29)),
    (8, 3, (0, 6, 1)),
    (4, 4, (5, 9, 9)),
    (5, 4, (41, 42, 46)),
    (6, 4, (50, 50, 45)),
    (7, 4, (148, 136, 113)),
    (8, 4, (41, 42, 46)),
    (9, 4, (0, 6, 6)),
    (3, 5, (24, 37, 41)),
    (5, 5, (41, 42, 46)),
    (6, 5, (139, 125, 108)),
    (7, 5, (148, 136, 113)),
    (8, 5, (33, 37, 45)),
    (9, 5, (0, 6, 6)),
    (4, 6, (1, 9, 5)),
    (5, 6, (41, 42, 46)),
    (6, 6, (41, 42, 46)),
    (7, 6, (41, 42, 46)),
    (8, 6, (33, 37, 45)),
    (9, 6, (34, 33, 37)),
    (10, 6, (33, 37, 45)),
    (2, 7, (0, 6, 1)),
    (4, 7, (27, 29, 29)),
    (5, 7, (13, 18, 21)),
    (6, 7, (41, 42, 46)),
    (7, 7, (41, 42, 46)),
    (8, 7, (50, 50, 45)),
    (9, 7, (34, 33, 37)),
    (10, 7, (33, 37, 45)),
    (11, 7, (33, 37, 45)),
    (1, 8, (1, 9, 5)),
    (2, 8, (5, 9, 9)),
    (6, 8, (39, 40, 24)),
    (12, 8, (5, 9, 9)),
    (1, 9, (30, 30, 19)),
    (2, 9, (63, 50, 40)),
    (3, 9, (5, 9, 9)),
    (4, 9, (0, 6, 1)),
    (6, 9, (39, 40, 24)),
    (10, 9, (0, 6, 6)),
    (11, 9, (35, 31, 26)),
    (2, 10, (24, 24, 20)),
    (3, 10, (0, 6, 1)),
    (4, 10, (63, 50, 40)),
    (5, 10, (0, 6, 6)),
    (6, 10, (0, 6, 1)),
    (7, 10, (1, 9, 5)),
    (8, 10, (53, 42, 33)),
    (9, 10, (70, 54, 46)),
    (10, 10, (5, 9, 9)),
    (2, 11, (46, 39, 32)),
    (3, 11, (94, 68, 55)),
    (4, 11, (94, 68, 55)),
    (5, 11, (94, 68, 55)),
    (6, 11, (83, 60, 48)),
    (7, 11, (83, 60, 48)),
    (8, 11, (83, 60, 48)),
    (9, 11, (94, 68, 55)),
    (10, 11, (5, 9, 9)),
    (2, 12, (35, 31, 26)),
    (3, 12, (35, 31, 26)),
    (4, 12, (30, 21, 17)),
    (5, 12, (30, 21, 17)),
    (6, 12, (30, 21, 17)),
    (7, 12, (30, 21, 17)),
    (8, 12, (30, 21, 17)),
    (9, 12, (1, 9, 5)),
]

HORIZON = 15  # last sky row; sea starts at HORIZON + 1
SAND_TOP = 26  # sand starts here -> 6 rows of beach

SUN_CX, SUN_R = 22, 5  # sun low on the horizon, left-of-centre
SUN_CY = 13  # derived: HORIZON - 2
CLOUD_Y = 4  # derived: high in the sky band
BOAT_Y = 5  # derived: hull waterline lands just below the horizon


def apply_profile(name):
    """Rebind canvas + geometry globals for the named render profile.

    The scene is authored against the tidbyt canvas; the tv profile adds rows
    to sky, sea and sand proportionally, and every dependent landmark (sun,
    cloud, boat, palm base) is derived from HORIZON/H rather than hardcoded.
    """
    global H, FRAMES, FRAME_MS, HORIZON, SAND_TOP, SUN_CY, CLOUD_Y, BOAT_Y
    p = PROFILES[name]
    H = p["h"]
    FRAMES = p["frames"]
    FRAME_MS = p["frame_ms"]
    HORIZON = p["horizon"]
    SAND_TOP = p["sand_top"]
    SUN_CY = HORIZON - 2  # sun sits just above the waterline
    CLOUD_Y = round(HORIZON * 0.28)  # high in the sky band
    BOAT_Y = HORIZON - 10  # sprite is 13 tall; waterline clears the horizon


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky_color(y):
    """Vertical gradient through the sky band."""
    t = y / HORIZON
    if t < 0.45:
        return lerp(SKY_TOP, SKY_MID, t / 0.45)
    if t < 0.80:
        return lerp(SKY_MID, SKY_LOW, (t - 0.45) / 0.35)
    return lerp(SKY_LOW, SKY_HORIZ, (t - 0.80) / 0.20)


def sea_color(y):
    top = HORIZON + 1
    t = (y - top) / (SAND_TOP - 1 - top)
    return lerp(SEA_FAR, SEA_NEAR, t)


def put(px, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        px[x, y] = c


def draw_frame(f):
    img = Image.new("RGB", (W, H))
    px = img.load()
    phase = 2 * math.pi * f / FRAMES  # one full turn over the loop

    # --- sky ---------------------------------------------------------------
    for y in range(0, HORIZON + 1):
        c = sky_color(y)
        for x in range(W):
            px[x, y] = c

    # --- sun (sits just above horizon, gentle breathing glow) --------------
    glow = 0.5 + 0.5 * math.sin(phase * 2)  # 0..1 seamless
    for y in range(SUN_CY - SUN_R - 1, SUN_CY + SUN_R + 1):
        for x in range(SUN_CX - SUN_R - 1, SUN_CX + SUN_R + 1):
            d = math.hypot(x - SUN_CX, (y - SUN_CY) * 1.05)
            if d <= SUN_R - 2:
                put(px, x, y, SUN_CORE)
            elif d <= SUN_R - 0.5:
                put(px, x, y, SUN_BODY)
            elif d <= SUN_R + 0.6:
                put(px, x, y, lerp(SUN_EDGE, SUN_BODY, glow))

    # --- cloud floating lazily up in the sky --------------------------------
    # Just a slow side-to-side sway (a few px), independent of the boat, so it
    # reads as drifting in place rather than racing across with the sailboat.
    cloud_x = 10 + round(
        5 * math.sin(phase * 2 + 0.7)
    )  # slow sway, 2 cycles/loop -> seamless
    cloud = [
        (0, 0),
        (1, -1),
        (2, -1),
        (3, -1),
        (4, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (5, 0),
        (-1, 0),
    ]
    for dx, dy in cloud:
        put(px, cloud_x + dx, CLOUD_Y + dy, CLOUD)

    # --- sea ---------------------------------------------------------------
    # Horizontal swell bands rolling toward shore (down-screen). Driven by y +
    # time so crests are parallel to the shore; a faint x term only ripples the
    # band edges so they aren't ruler-straight. (No strong x term -> no diagonal.)
    for y in range(HORIZON + 1, SAND_TOP):
        base = sea_color(y)
        for x in range(W):
            ripple = math.sin(y * 1.15 - phase * 4.0 + 0.6 * math.sin(x * 0.30))
            px[x, y] = SEA_DARK if ripple > 0.45 else base

    # --- pirate ship drifting across the horizon ---------------------------
    # Constant velocity across the long loop, fully off-canvas at both ends
    # (sprite is 14px wide) so the wrap-back is invisible -> seamless.
    draw_boat(px, round(-15 + (W + 30) * f / FRAMES), phase)

    # --- beach -------------------------------------------------------------
    for y in range(SAND_TOP, H):
        for x in range(W):
            speck = (x * 7 + y * 13) % 5 == 0
            px[x, y] = SAND_DARK if speck else SAND_LIGHT

    draw_swash(px, phase)

    # --- palm tree leaning in from the right -------------------------------
    draw_palm(px, phase)

    return img


def draw_boat(px, bx, phase):
    """A pirate ship drifting on the horizon — a small dark silhouette accent
    (the palm is the hero), bobbing and rocking with a foamy wake."""
    # Bobbing (vertical) + rocking (shear), both 4 cycles/loop -> seamless.
    bob_y = round(0.55 * math.sin(phase * 4.0 + 1.2))
    byt = BOAT_Y + bob_y
    rock = 0.8 * math.sin(phase * 4.0)

    # Place every sprite pixel (with shear) into a position map.
    drawn = {}
    for dx, dy, c in PIRATE_SPRITE:
        shift_x = round(rock * (11 - dy) / 12.0) if dy < 11 else 0
        drawn[(bx + dx + shift_x, byt + dy)] = c

    # Wake: a foamy trail streaming off the stern (ship sails right, so the wake
    # trails left) — solid churn at the hull, then a shimmering, fading dash.
    # Drawn first so the hull sits on top of it.
    stern_x = bx + 2
    wl = byt + 12                       # waterline under the hull
    for d in range(1, 13):
        wx = stern_x - d
        if not (0 <= wx < W):
            continue
        drift = math.sin(d * 0.9 - phase * 8.0)     # 8 cycles/loop -> seamless
        if d <= 4:                                  # solid churn at the stern
            put(px, wx, wl, FOAM)
            if d >= 2:
                put(px, wx, wl + 1, FOAM_SOFT)      # V widening behind
        elif drift > -0.1:                          # dashed, fading trail
            put(px, wx, wl, FOAM_SOFT)

    # The ship itself, on top of the wake.
    for (fx, fy), c in drawn.items():
        put(px, fx, fy, c)


def _bub(x, y):
    """Cheap deterministic 0..1 noise for foam bubble texture."""
    return ((x * 73 + y * 131 + 17) % 19) / 19.0


def draw_swash(px, phase):
    """Foamy waves breaking at the shore and washing up the sand, then draining.

    The whole foam sheet advances down the beach and retreats once per loop
    (the wash cycle), with a scalloped, laterally-drifting leading edge so it
    reads as churning foam rather than a moving line. Seamless: all motion is
    sin(phase) with integer period over the loop.
    """
    # Breaking-wave crest sitting in the water just above the sand — always
    # foamy, gently undulating, so a wave is forever rolling in.
    for x in range(W):
        if math.sin(x * 0.55 - phase * 2) > -0.15:
            top = SAND_TOP - 1 - (1 if math.sin(x * 0.8 + phase * 2) > 0.35 else 0)
            put(px, x, top, FOAM if _bub(x, top) > 0.3 else FOAM_SOFT)

    # Swash sheet washing up the beach: a SOLID sheet of shallow water slides
    # down onto the sand and back, capped by a white foam crest. The body fills
    # with water colour (not scattered bubbles) so it reads as a wave, not snow.
    wash = math.sin(phase * 2)  # main in/out, 2 washes per loop
    wash2 = 0.35 * math.sin(phase * 4 + 2.0)  # gentle secondary churn
    for x in range(W):
        along = 0.7 * math.sin(x * 0.42 - phase * 2) + 0.3 * math.sin(x * 0.95 + 1.0)
        reach = 2.2 + 1.9 * wash + wash2 + 0.8 * along  # px down the beach
        lead = SAND_TOP - 1 + int(round(reach))
        lead = min(lead, H - 1)
        for y in range(SAND_TOP, lead + 1):
            depth = lead - y  # 0 at the leading foam edge
            if depth == 0:
                px[x, y] = FOAM  # solid white crest
            elif depth == 1:
                px[x, y] = FOAM_SOFT if _bub(x, y) > 0.4 else SHALLOW_LT
            else:
                # solid water sheet, a few foam streaks caught in it
                px[x, y] = SHALLOW_LT if _bub(x, y) > 0.82 else SHALLOW
        # wet-sand margin just ahead of the retreating water
        for y in range(lead + 1, min(lead + 3, H)):
            if _bub(x, y) > 0.3:
                px[x, y] = WET_SAND


def _line(px, x0, y0, x1, y1, c):
    """Draw a 4/8-connected line so fronds never break into floating dots."""
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        put(px, x0, y0, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy


def draw_palm(px, phase):
    """A tall, bushy coconut palm leaning in from the right — the scene's hero.

    Thick ringed trunk curving up from the sand into the sky, a fat cluster of
    coconuts, and a full crown of drooping fronds drawn as connected polylines
    (so they stay solid as they sway).
    """
    # Curving, tapering trunk from the sand (bottom-right) up into the sky.
    # (x, y, thick), ordered base -> crown. Three-stage taper: a 3px flare at
    # the base, 2px through the middle, thinning to 1px under the crown. The
    # crown is deliberately big and bushy, so a uniformly thin trunk read as
    # spindly and top-heavy — the flare gives the tree something to stand on.
    trunk = [
        (58, 31, 3),
        (58, 30, 3),
        (57, 29, 3),
        (57, 28, 3),
        (56, 27, 3),
        (56, 26, 3),
        (55, 25, 2),
        (55, 24, 2),
        (54, 23, 2),
        (54, 22, 2),
        (53, 21, 2),
        (53, 20, 2),
        (52, 19, 2),
        (52, 18, 2),
        (51, 17, 1),
        (51, 16, 1),
        (50, 15, 1),
        (50, 14, 1),
        (50, 13, 1),
        (49, 12, 1),
    ]

    # On the taller (16:9) canvas the sand line drops, so grow the base down to
    # meet it, continuing the curve rather than leaving the tree hovering.
    bx, by, bt = trunk[0]
    trunk = [(bx + (j + 1) // 2, by + j, bt) for j in range(H - 32, 0, -1)] + trunk

    for i, (x, y, t) in enumerate(trunk):
        body = TRUNK if i % 2 == 0 else TRUNK_DK  # bark rings
        for k in range(t):
            # Keep the right-hand column dark so the trunk reads as rounded and
            # lit from the left, matching the sun's position.
            put(px, x + k, y, TRUNK_DK if t > 1 and k == t - 1 else body)
    crown_x, crown_y = 49, 11

    # Dense green core so the crown never looks hollow.
    for dx, dy in [(0, 0), (-1, 0), (1, 0), (0, -1), (-1, -1), (1, -1), (0, 1)]:
        put(px, crown_x + dx, crown_y + dy, FROND)

    # Coconut cluster tucked under the crown.
    for cx, cy in [(50, 13), (48, 13), (49, 14)]:
        put(px, cx, cy, COCONUT)

    # Fronds: each is a polyline radiating from the crown, tips arcing & drooping.
    # "up" fronds lift with the breeze; "down" fronds counter-sway.
    sway = round(1.6 * math.sin(phase * 2))  # -2..2 px at the tips
    fronds = [
        ("up", [(0, -1), (-1, -3), (-2, -4)]),  # top-left spike
        ("up", [(0, -1), (1, -3), (2, -4)]),  # top-right spike
        ("up", [(-1, -1), (-3, -2), (-5, -2), (-6, -1)]),  # arch left
        ("up", [(1, -1), (3, -2), (5, -2), (6, -1)]),  # arch right
        ("down", [(-2, 0), (-4, 0), (-6, 1), (-7, 2)]),  # long left sweep
        ("down", [(2, 0), (4, 0), (6, 1), (7, 2)]),  # long right sweep
        ("down", [(-1, 1), (-3, 2), (-4, 3)]),  # droop left
        ("down", [(1, 1), (3, 2), (4, 3)]),  # droop right
        ("down", [(0, 2), (-1, 3), (1, 3)]),  # short under-frond
    ]
    for kind, path in fronds:
        tipsway = sway if kind == "up" else -sway
        n = len(path)
        # Build absolute points (start at the crown) with progressive tip sway.
        pts = [(crown_x, crown_y)]
        for j, (dx, dy) in enumerate(path):
            s = round(tipsway * (j + 1) / n)
            pts.append((crown_x + dx + s, crown_y + dy))
        for k in range(len(pts) - 1):
            tip = k >= len(pts) - 2
            _line(
                px,
                pts[k][0],
                pts[k][1],
                pts[k + 1][0],
                pts[k + 1][1],
                FROND_DK if tip else FROND,
            )
    # Sun-lit highlight on the crown's heart.
    put(px, crown_x, crown_y - 1, FROND_LT)
    put(px, crown_x, crown_y, FROND_LT)


def render_tidbyt():
    """64x32 animated WebP for the panel, plus GIF/PNG previews."""
    apply_profile("tidbyt")
    frames = [draw_frame(f) for f in range(FRAMES)]

    frames[0].save(
        os.path.join(OUT, "beach.webp"),
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_MS,
        loop=0,
        lossless=True,
        method=6,
    )
    frames[0].save(
        os.path.join(OUT, "beach.gif"),
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_MS,
        loop=0,
        optimize=False,
        disposal=0,
    )
    frames[0].resize((W * 6, H * 6), Image.NEAREST).save(
        os.path.join(OUT, "preview.png")
    )
    print(f"tidbyt: {FRAMES} frames {W}x{H} @{FRAME_MS}ms -> beach.webp, beach.gif")


def render_tv():
    """64x36 loop encoded to a 4K MP4 for the Android TV screensaver."""
    apply_profile("tv")
    fps = round(1000 / FRAME_MS)

    # Dump the frames at native size (a few KB each) and let ffmpeg do the
    # nearest-neighbour upscale — writing 576 4K PNGs would cost ~1GB for no gain.
    tmp = os.path.join(OUT, "tv_frames")
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    for f in range(FRAMES):
        draw_frame(f).save(os.path.join(tmp, f"{f:04d}.png"))

    mp4 = os.path.join(OUT, "tropicbyt-4k.mp4")
    if not shutil.which("ffmpeg"):
        print(f"tv: {FRAMES} frames -> {tmp} (ffmpeg not found, skipping MP4)")
        return

    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-framerate", str(fps),
            "-i", os.path.join(tmp, "%04d.png"),
            # flags=neighbor keeps the pixels hard-edged instead of smearing them
            "-vf", f"scale={W * TV_SCALE}:{H * TV_SCALE}:flags=neighbor",
            "-c:v", "libx264", "-preset", "slow", "-crf", "16",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            mp4,
        ],
        check=True,
    )
    shutil.rmtree(tmp, ignore_errors=True)
    secs = FRAMES / fps
    print(
        f"tv: {FRAMES} frames {W}x{H} @{fps}fps ({secs:.1f}s loop) "
        f"-> tropicbyt-4k.mp4 [{W * TV_SCALE}x{H * TV_SCALE}]"
    )


def render_wallpaper():
    """Pixel-perfect desktop wallpapers: 16:10 (2560x1600) and 16:9 4K (3840x2160)."""
    # 1. Native 16:10 for modern laptop displays (e.g. Zephyrus 2560x1600)
    apply_profile("wallpaper")
    # Frame 280 places the sailboat midway across the sunset between sun & palm
    frame_16_10 = draw_frame(280)
    wp_16_10 = frame_16_10.resize((2560, 1600), Image.NEAREST)
    path_16_10 = os.path.join(OUT, "tropicbyt-wallpaper-2560x1600.png")
    wp_16_10.save(path_16_10)

    # 2. 16:9 4K (3840x2160)
    apply_profile("tv")
    frame_tv = draw_frame(280)
    wp_4k = frame_tv.resize((W * TV_SCALE, H * TV_SCALE), Image.NEAREST)
    path_4k = os.path.join(OUT, "tropicbyt-wallpaper-4k.png")
    wp_4k.save(path_4k)

    print(f"wallpaper: saved {path_16_10} (2560x1600) and {path_4k} (3840x2160)")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--profile",
        choices=["tidbyt", "tv", "wallpaper", "both", "all"],
        default="both",
        help="which target(s) to render (default: both)",
    )
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    if args.profile in ("tidbyt", "both", "all"):
        render_tidbyt()
    if args.profile in ("tv", "both", "all"):
        render_tv()
    if args.profile in ("wallpaper", "all"):
        render_wallpaper()
    apply_profile("tidbyt")  # leave globals on panel defaults


if __name__ == "__main__":
    main()
