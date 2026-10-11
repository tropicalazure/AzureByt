"""
ClockByt — Stardust
A Tidbyt clock whose digits shatter into pixels and reassemble.

Each render produces one seamless loop: the current time HOLDS, the pixels
SHATTER into a scattered field, then REASSEMBLE back into the time. Because the
Tidbyt device re-renders the app periodically, it "rebuilds itself" with the
new time as the clock advances.

Display is 64x32. Time is fixed for the duration of a single render, so we can't
animate a true minute-flip inside one loop — instead the loop is built to be
seamless (it ends exactly where it began) and the device's refresh supplies the
new time.
"""

load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ── Geometry ──────────────────────────────────────────────────────────────────
W = 64
H = 32
CELL = 2  # each logical pixel of a glyph is drawn as a CELL x CELL block

# ── Animation timing (frames). delay below is ms per frame. ───────────────────
FRAME_MS = 70
REASSEMBLE = 22    # ~1.5s pull the pixels in to form the time
HOLD_TAIL = 30     # ~2.1s static settle after the build, so it isn't a tight reloop
# Continuous mode (optional) adds these:
HOLD = 16          # steady hold before a shatter
SHATTER = 14       # break apart

# We only play the build animation right after a minute rolls over. For the rest
# of the minute the app returns a single static frame (no motion). As the device
# re-renders across the minute boundary, the new time "builds itself", then sits.
BUILD_WINDOW_S = 6  # seconds after :00 during which renders show the build
MAX_AGE = 15        # cap server-side cache so renders stay fresh near the boundary

# ── 5x7 pixel font, top→bottom rows. "#" = lit. Colon is 1 wide. ──────────────
GLYPHS = {
    "0": [" ### ", "#   #", "#  ##", "# # #", "##  #", "#   #", " ### "],
    "1": ["  #  ", " ##  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "],
    "2": [" ### ", "#   #", "    #", "   # ", "  #  ", " #   ", "#####"],
    "3": ["#####", "   # ", "  ## ", "    #", "    #", "#   #", " ### "],
    "4": ["   # ", "  ## ", " # # ", "#  # ", "#####", "   # ", "   # "],
    "5": ["#####", "#    ", "#### ", "    #", "    #", "#   #", " ### "],
    "6": [" ### ", "#    ", "#    ", "#### ", "#   #", "#   #", " ### "],
    "7": ["#####", "    #", "   # ", "  #  ", "  #  ", " #   ", " #   "],
    "8": [" ### ", "#   #", "#   #", " ### ", "#   #", "#   #", " ### "],
    "9": [" ### ", "#   #", "#   #", " ####", "    #", "    #", " ### "],
    ":": [" ", " ", "#", " ", "#", " ", " "],
}
GLYPH_H = 7

# ── Color themes: (left_rgb, right_rgb, spark_rgb, spark_prob) ─────────────────
THEMES = {
    "cyan": ((80, 220, 255), (120, 150, 255), (255, 205, 90), 0.06),
    "amber": ((255, 175, 45), (255, 95, 40), (255, 240, 185), 0.05),
    "matrix": ((130, 255, 150), (40, 200, 95), (220, 255, 205), 0.04),
    "magma": ((255, 90, 60), (255, 30, 110), (255, 225, 130), 0.06),
}

# ── Tiny deterministic PRNG (LCG) so a render is stable but varies over time ───
def make_rng(seed):
    state = [seed % 2147483647]
    if state[0] <= 0:
        state[0] += 2147483646

    def nxt():
        state[0] = (state[0] * 16807) % 2147483647
        return state[0] / 2147483647.0

    return nxt

# ── Helpers ───────────────────────────────────────────────────────────────────
def lerp(a, b, t):
    return a + (b - a) * t

def ease(t):  # smoothstep
    return t * t * (3 - 2 * t)

_HEX = "0123456789abcdef"

def _h2(n):
    n = int(n)
    if n < 0:
        n = 0
    if n > 255:
        n = 255
    return _HEX[n // 16] + _HEX[n % 16]

def rgb(r, g, b):
    return "#" + _h2(r) + _h2(g) + _h2(b)

def clampi(v, lo, hi):
    v = int(v)
    if v < lo:
        return lo
    if v > hi:
        return hi
    return v

# ── Build the particle set for a time string ──────────────────────────────────
def build_targets(text, theme, rng):
    left, right, spark, spark_p = theme

    # measure logical width (glyph widths + 1-col gaps)
    widths = [len(GLYPHS[c][0]) for c in text.elems()]
    logical_w = 0
    for w in widths:
        logical_w += w
    logical_w += len(widths) - 1  # gaps

    dev_w = logical_w * CELL
    x0 = (W - dev_w) // 2
    y0 = (H - GLYPH_H * CELL) // 2

    targets = []
    cursor = 0  # logical column
    for ci in range(len(widths)):
        ch = text[ci]
        glyph = GLYPHS[ch]
        for r in range(GLYPH_H):
            row = glyph[r]
            for c in range(len(row)):
                if row[c] != "#":
                    continue
                tx = x0 + (cursor + c) * CELL
                ty = y0 + r * CELL

                # color by horizontal position, with occasional spark
                if rng() < spark_p:
                    col = spark
                else:
                    f = float(tx) / float(W)
                    col = (
                        lerp(left[0], right[0], f),
                        lerp(left[1], right[1], f),
                        lerp(left[2], right[2], f),
                    )

                # scattered "static" position somewhere on screen
                sx = rng() * (W - CELL)
                sy = rng() * (H - CELL)

                targets.append({
                    "tx": tx,
                    "ty": ty,
                    "sx": sx,
                    "sy": sy,
                    "r": col[0],
                    "g": col[1],
                    "b": col[2],
                })
        cursor += widths[ci] + 1

    return targets

# ── Render one frame ──────────────────────────────────────────────────────────
DIM = 0.22  # brightness when fully scattered

def frame(targets, phase, t):
    parts = [render.Box(width=W, height=H, color="#000000")]
    e = ease(t)
    for p in targets:
        if phase == "hold":
            x, y, b = p["tx"], p["ty"], 1.0
        elif phase == "shatter":
            x = lerp(p["tx"], p["sx"], e)
            y = lerp(p["ty"], p["sy"], e)
            b = lerp(1.0, DIM, e)
        else:  # reassemble
            x = lerp(p["sx"], p["tx"], e)
            y = lerp(p["sy"], p["ty"], e)
            b = lerp(DIM, 1.0, e)

        parts.append(
            render.Padding(
                pad = (clampi(x, 0, W - CELL), clampi(y, 0, H - CELL), 0, 0),
                child = render.Box(
                    width = CELL,
                    height = CELL,
                    color = rgb(p["r"] * b, p["g"] * b, p["b"] * b),
                ),
            ),
        )
    return render.Stack(children = parts)

# Build-on-change: pixels materialize into the time, then hold static.
def build_buildup_frames(targets):
    frames = []
    for i in range(REASSEMBLE):
        frames.append(frame(targets, "reassemble", i / float(REASSEMBLE - 1)))
    for _ in range(HOLD_TAIL):
        frames.append(frame(targets, "hold", 0))
    return frames

# Continuous: hold, shatter, reassemble — loops forever (opt-in).
def build_continuous_frames(targets):
    frames = []
    for _ in range(HOLD):
        frames.append(frame(targets, "hold", 0))
    for i in range(SHATTER):
        frames.append(frame(targets, "shatter", i / float(SHATTER - 1)))
    for i in range(REASSEMBLE):
        frames.append(frame(targets, "reassemble", i / float(REASSEMBLE - 1)))
    return frames

# ── Entry ─────────────────────────────────────────────────────────────────────
def main(config):
    tz = config.get("timezone") or config.get("$tz") or "America/New_York"
    now = time.now().in_location(tz)

    military = config.bool("military", False)
    text = now.format("15:04") if military else now.format("3:04")

    theme = THEMES.get(config.get("theme", "cyan"), THEMES["cyan"])

    # seed varies per minute, so each minute's scatter pattern differs
    seed = now.hour * 97 + now.minute * 31 + now.day * 7 + 1
    rng = make_rng(seed)
    targets = build_targets(text, theme, rng)

    continuous = config.bool("continuous", False)

    if continuous:
        child = render.Animation(children = build_continuous_frames(targets))
    elif now.second < BUILD_WINDOW_S:
        # the minute just changed: play the build, then hold
        child = render.Animation(children = build_buildup_frames(targets))
    else:
        # steady state: a single static frame, no animation
        child = frame(targets, "hold", 0)

    return render.Root(
        delay = FRAME_MS,
        show_full_animation = True,
        max_age = MAX_AGE,
        child = child,
    )

# ── Schema (Tidbyt mobile-app config) ─────────────────────────────────────────
def get_schema():
    theme_options = [
        schema.Option(display = "Stardust (cyan)", value = "cyan"),
        schema.Option(display = "Ember (amber)", value = "amber"),
        schema.Option(display = "Matrix (green)", value = "matrix"),
        schema.Option(display = "Magma (pink)", value = "magma"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theme",
                name = "Color theme",
                desc = "Palette for the particles.",
                icon = "palette",
                default = "cyan",
                options = theme_options,
            ),
            schema.Toggle(
                id = "military",
                name = "24-hour time",
                desc = "Show a 24-hour clock.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "continuous",
                name = "Animate continuously",
                desc = "Shatter and rebuild on a loop instead of only when the minute changes.",
                icon = "wandMagicSparkles",
                default = False,
            ),
        ],
    )
