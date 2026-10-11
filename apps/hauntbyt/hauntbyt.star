"""
HauntByt — Animated haunted house scene for Tidbyt

A hand-painted pixel-art backdrop (generated with pixellab.ai, downscaled to
64×32) with ethereal ghosts and an occasional lightning flash animated on top.

To run:
    pixlet serve hauntbyt.star
    pixlet render hauntbyt.star
"""

load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")
load("math.star", "math")

# ═══════════════════════════════════════════════
#  Backdrop  (64×32 pixel-art scene, embedded as PNG bytes)
# ═══════════════════════════════════════════════

BACKDROP = base64.decode("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")

# ═══════════════════════════════════════════════
#  Color Palette  (8-digit hex = #RRGGBBAA for transparency)
# ═══════════════════════════════════════════════

# Ghosts (ethereal — note the alpha so the backdrop shows through)
GHOST_BODY = "#d4e2ffcc"
GHOST_RIM = "#ffffffe0"
GHOST_GLOW = "#aabcff38"
GHOST_EYE = "#1a1030"

# Lightning
BOLT_WHITE = "#ffffff"
BOLT_CORE = "#e8f0ff"
FLASH_STRONG = "#c2cfffb0"
FLASH_WEAK = "#aabcff50"

# ═══════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════

def place(x, y, child):
    """Position a widget absolutely within a Stack using Padding.

    Pixlet's Padding pad tuple is (left, top, right, bottom), so to offset
    a child to (x, y) we pad left by x and top by y.
    """
    return render.Padding(pad = (x, y, 0, 0), child = child)

def pbx(x, y, w, h, color):
    """Positioned colored box."""
    if w <= 0 or h <= 0:
        return render.Box(width = 0, height = 0)
    return place(x, y, render.Box(width = w, height = h, color = color))

# ═══════════════════════════════════════════════
#  Lightning
# ═══════════════════════════════════════════════

def draw_flash(strong):
    """Full-screen flash tint, plus a jagged bolt on the strong frame."""
    elems = []
    elems.append(render.Box(width = 64, height = 32, color = FLASH_STRONG if strong else FLASH_WEAK))
    if strong:
        bolt = [
            (47, 0, 1, 3), (46, 3, 1, 2), (47, 5, 1, 2),
            (45, 7, 1, 3), (46, 10, 1, 2), (44, 12, 1, 2),
        ]
        for (x, y, w, h) in bolt:
            elems.append(pbx(x, y, w, h, BOLT_WHITE))
        elems.append(pbx(48, 6, 2, 1, BOLT_CORE))  # fork
    return elems

# ═══════════════════════════════════════════════
#  Ghosts  (ethereal — semi-transparent so the scene shows through)
# ═══════════════════════════════════════════════

def draw_ghost(gx, gy, hem):
    """Ethereal ghost at absolute (gx, gy). ~7px wide × 8px tall.

    hem: 0/1/2 selects the tattered bottom shape (animates the 'flow').
    """
    elems = []

    # Soft outer aura
    elems.append(pbx(gx - 1, gy + 1, 9, 6, GHOST_GLOW))

    # Silhouette (domed head → body)
    body_rows = [
        (gy + 0, 2, 3), (gy + 1, 1, 5), (gy + 2, 0, 7), (gy + 3, 0, 7),
        (gy + 4, 0, 7), (gy + 5, 0, 7), (gy + 6, 0, 7),
    ]
    for (ry, ox, w) in body_rows:
        elems.append(pbx(gx + ox, ry, w, 1, GHOST_BODY))

    # Bright rim light along the top of the head
    elems.append(pbx(gx + 2, gy, 3, 1, GHOST_RIM))
    elems.append(pbx(gx + 1, gy + 1, 1, 1, GHOST_RIM))

    # Tattered, wavy bottom hem
    if hem == 0:
        drops = [0, 1, 3, 5, 6]
    elif hem == 1:
        drops = [0, 2, 3, 5]
    else:
        drops = [1, 3, 4, 6]
    for d in drops:
        elems.append(pbx(gx + d, gy + 7, 1, 1, GHOST_BODY))

    # Hollow dark eyes + open "boo" mouth
    elems.append(pbx(gx + 1, gy + 2, 2, 2, GHOST_EYE))
    elems.append(pbx(gx + 4, gy + 2, 2, 2, GHOST_EYE))
    elems.append(pbx(gx + 3, gy + 4, 1, 2, GHOST_EYE))

    return elems

# ═══════════════════════════════════════════════
#  Frame Assembly
# ═══════════════════════════════════════════════

# Lots of frames = tiny per-frame steps = smooth, calm drifting (~19s loop).
NUM_FRAMES = 64

# Lightning fires once per loop: a strike frame then an afterglow frame.
STRIKE_FRAME = 40

# Each ghost wanders a smooth closed loop. Combining a slow horizontal sweep
# (fx=1) with a gentle vertical figure-8 (fy=1 or 2) makes the path curve and
# roam all over the scene instead of sliding on a single track. Keeping the
# frequencies low keeps the motion lazy and floaty. Integer frequencies
# guarantee the loop closes seamlessly.
#       cx  cy  ax  ay  fx fy  phase_x  phase_y  hem
GHOST_PATHS = [
    (28, 12, 20, 7, 1, 2, 0.0, 0.0, 0),
    (32, 14, 22, 6, 1, 1, 2.1, 1.0, 1),
    (26, 11, 17, 8, 1, 2, 4.2, 3.1, 2),
]

def ghost_pos(t, cx, cy, ax, ay, fx, fy, phx, phy):
    """Smooth wandering position along a closed Lissajous path at time t."""
    x = cx + ax * math.sin(fx * t + phx)
    y = cy + ay * math.sin(fy * t + phy)
    return (int(math.round(x)), int(math.round(y)))

def make_frame(frame_num):
    """Compose one animation frame over the backdrop.

    Ghosts drift along wandering loops the whole time; lightning flashes once
    per cycle (strike frame + a softer afterglow frame).
    """
    t = 2.0 * math.pi * frame_num / NUM_FRAMES
    strike = frame_num == STRIKE_FRAME
    afterglow = frame_num == STRIKE_FRAME + 1

    # ── Layer the scene back-to-front ──
    elements = []
    elements.append(render.Image(src = BACKDROP, width = 64, height = 32))

    for (cx, cy, ax, ay, fx, fy, phx, phy, hem_off) in GHOST_PATHS:
        gx, gy = ghost_pos(t, cx, cy, ax, ay, fx, fy, phx, phy)
        elements = elements + draw_ghost(gx, gy, (frame_num + hem_off) % 3)

    if strike or afterglow:
        elements = elements + draw_flash(strike)

    return render.Stack(children = elements)

# ═══════════════════════════════════════════════
#  Schema
# ═══════════════════════════════════════════════

FRAME_DELAY = schema.Dropdown(
    id = "frame_delay",
    name = "Animation Speed",
    desc = "How long each frame is displayed.",
    icon = "gauge",
    default = "300",
    options = [
        schema.Option(display = "Fast (150ms)", value = "150"),
        schema.Option(display = "Normal (300ms)", value = "300"),
        schema.Option(display = "Slow (500ms)", value = "500"),
        schema.Option(display = "Very Slow (800ms)", value = "800"),
    ],
)

def get_schema():
    return schema.Schema(version = "1", fields = [FRAME_DELAY])

# ═══════════════════════════════════════════════
#  Main — returns animated frames
# ═══════════════════════════════════════════════

def main(config):
    """Entry point. Returns one animated Root containing all frames."""
    delay_ms = int(config.str("frame_delay", "300"))

    return render.Root(
        delay = delay_ms,
        show_full_animation = True,
        child = render.Animation(
            children = [make_frame(i) for i in range(NUM_FRAMES)],
        ),
    )
