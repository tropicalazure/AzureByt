"""
America250Byt — America's 250th Birthday celebration for Tidbyt
The official AMERICA250 "250" ribbon logo centered, with red/white/blue
fireworks bursting around it over a twinkling night sky. 1776–2026.

To run:
    pixlet serve america250byt.star
    pixlet render america250byt.star
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

# ═══════════════════════════════════════════════
#  Embedded AMERICA250 "250" ribbon logo (44×21 PNG)
# ═══════════════════════════════════════════════

LOGO_B64 = "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"

# ═══════════════════════════════════════════════
#  Color Palette
# ═══════════════════════════════════════════════

NIGHT = "#05040f"  # deep night-sky background

STAR_DIM = "#3a3a55"
STAR_LIT = "#c9d4ff"

# Firework shade ramps: [flash core, bright, mid, dim ember]
RED = ["#ffffff", "#ff7a6a", "#ff2424", "#9c1010"]
BLUE = ["#ffffff", "#88a4ff", "#2a48ff", "#142aa8"]
GOLD = ["#ffffff", "#ffe89a", "#ffc024", "#9c7410"]
WHT = ["#ffffff", "#e6ecff", "#a6b6da", "#5a6488"]

# ═══════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════

def place(x, y, child):
    """Absolute-position a widget within a Stack via Padding.

    Pixlet Padding pad order is (left, top, right, bottom).
    x = horizontal offset (left), y = vertical offset (top).
    """
    return render.Padding(pad = (x, y, 0, 0), child = child)

def bx(w, h, color):
    """Colored box shortcut."""
    return render.Box(width = w, height = h, color = color)

def pbx(x, y, w, h, color):
    """Positioned colored box."""
    return place(x, y, bx(w, h, color))

def plot(x, y, color):
    """A single clipped pixel. Returns [] if off-screen."""
    if x < 0 or x > 63 or y < 0 or y > 31:
        return []
    return [pbx(x, y, 1, 1, color)]

def ring(cx, cy, r, diag):
    """Coordinates of a star/ring burst at radius r."""
    pts = [(cx + r, cy), (cx - r, cy), (cx, cy + r), (cx, cy - r)]
    if diag:
        d = r * 7 // 10
        if d < 1:
            d = 1
        pts.extend([
            (cx + d, cy + d),
            (cx + d, cy - d),
            (cx - d, cy + d),
            (cx - d, cy - d),
        ])
    return pts

# ═══════════════════════════════════════════════
#  Night sky + twinkling stars
# ═══════════════════════════════════════════════

STARS = [
    (2, 3), (6, 9), (12, 2), (20, 6), (30, 2),
    (38, 8), (46, 3), (52, 9), (58, 2), (61, 11),
    (4, 16), (60, 16), (2, 26), (62, 28), (33, 30),
    (9, 30), (55, 27),
]

def draw_stars(frame):
    elems = []
    for i in range(len(STARS)):
        sx, sy = STARS[i]
        # Twinkle: each star lit on a staggered cadence
        lit = (frame + i * 5) % 6 < 2
        elems.extend(plot(sx, sy, STAR_LIT if lit else STAR_DIM))
    return elems

# ═══════════════════════════════════════════════
#  Fireworks
# ═══════════════════════════════════════════════

# Each firework: (center_x, center_y, start_frame, shade_ramp)
# The 35x17 logo sits centered (x:14-49, y:12-29), so these bursts live in
# the open sky to its left, right, and above — fully visible all the way out
# to radius 4. Staggered starts keep 3-4 bursting at any moment.
FIREWORKS = [
    # Left column (clear of the logo at x>=14)
    (6, 8, 0, RED),
    (5, 17, 8, WHT),
    (7, 26, 4, GOLD),
    # Right column (clear of the logo at x<=49)
    (57, 8, 2, BLUE),
    (58, 17, 10, GOLD),
    (56, 26, 6, RED),
    # Bottom corners
    (11, 29, 3, BLUE),
    (52, 29, 5, WHT),
    # One high above, between the wordmark's gaps
    (32, 3, 7, GOLD),
]

LIFE = 6  # frames a firework is visible
LOOP = 12  # total frames in the animation cycle

def draw_firework(cx, cy, shades, local):
    """Draw one firework at lifecycle stage `local` (0..LIFE-1)."""
    flash, bright, mid, dim = shades[0], shades[1], shades[2], shades[3]
    out = []

    if local == 0:
        # Rising trail
        out.extend(plot(cx, cy + 4, dim))
        out.extend(plot(cx, cy + 3, bright))
    elif local == 1:
        # Ignition point
        out.extend(plot(cx, cy + 1, bright))
        out.extend(plot(cx, cy, flash))
    elif local == 2:
        # First flash — tight burst
        out.extend(plot(cx, cy, flash))
        for (x, y) in ring(cx, cy, 1, True):
            out.extend(plot(x, y, bright))
    elif local == 3:
        # Full bloom
        out.extend(plot(cx, cy, flash))
        for (x, y) in ring(cx, cy, 1, True):
            out.extend(plot(x, y, flash))
        for (x, y) in ring(cx, cy, 2, True):
            out.extend(plot(x, y, mid))
    elif local == 4:
        # Expanding + cooling
        for (x, y) in ring(cx, cy, 2, True):
            out.extend(plot(x, y, mid))
        for (x, y) in ring(cx, cy, 3, True):
            out.extend(plot(x, y, dim))
    else:
        # Falling embers
        for (x, y) in ring(cx, cy, 3, True):
            out.extend(plot(x, y, dim))
        for (x, y) in ring(cx, cy, 4, False):
            out.extend(plot(x, y, dim))

    return out

def draw_fireworks(frame):
    elems = []
    for (cx, cy, start, shades) in FIREWORKS:
        local = (frame - start) % LOOP
        if local < LIFE:
            elems.extend(draw_firework(cx, cy, shades, local))
    return elems

# ═══════════════════════════════════════════════
#  AMERICA wordmark (tricolor) + logo
# ═══════════════════════════════════════════════

def america_text():
    """The AMERICA wordmark in red/white/blue, centered up top."""
    letters = [
        ("A", "#ff3030"),
        ("M", "#ffffff"),
        ("E", "#3a5cff"),
        ("R", "#ff3030"),
        ("I", "#ffffff"),
        ("C", "#3a5cff"),
        ("A", "#ff3030"),
    ]
    kids = [
        render.Text(content = c, font = "tom-thumb", color = col)
        for (c, col) in letters
    ]
    return render.Box(
        width = 64,
        height = 6,
        child = render.Row(children = kids),
    )

def logo_image():
    """The embedded AMERICA250 '250' ribbon, centered."""
    return render.Image(
        src = base64.decode(LOGO_B64),
        width = 35,
        height = 17,
    )

# ═══════════════════════════════════════════════
#  Frame Assembly
# ═══════════════════════════════════════════════

def make_frame(frame):
    elements = []

    # Layer 1: night sky
    elements.append(bx(64, 32, NIGHT))

    # Layer 2: twinkling stars
    elements.extend(draw_stars(frame))

    # Layer 3: fireworks (behind the logo)
    elements.extend(draw_fireworks(frame))

    # Layer 4: the 250 ribbon logo, centered (35 wide -> x=14/15 split)
    elements.append(place(15, 11, logo_image()))

    # Layer 5: AMERICA wordmark on top, snug above the ribbon
    elements.append(place(0, 4, america_text()))

    return render.Stack(children = elements)

# ═══════════════════════════════════════════════
#  Schema
# ═══════════════════════════════════════════════

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "frame_delay",
                name = "Animation Speed",
                desc = "How fast the fireworks burst.",
                icon = "gauge",
                default = "130",
                options = [
                    schema.Option(display = "Fast (90ms)", value = "90"),
                    schema.Option(display = "Normal (130ms)", value = "130"),
                    schema.Option(display = "Slow (190ms)", value = "190"),
                ],
            ),
        ],
    )

# ═══════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════

def main(config):
    delay_ms = int(config.str("frame_delay", "130"))
    roots = []
    for f in range(LOOP):
        roots.append(render.Root(
            child = make_frame(f),
            delay = delay_ms,
            show_full_animation = True,
        ))
    return roots
