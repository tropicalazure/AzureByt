"""
Applet: Independence Byt
Summary: 4th of July celebration
Description: A festive, animated 4th of July display with bursting
fireworks over a night sky, a patriotic stripe, and a scrolling banner.
Author: markamccray
"""

load("render.star", "render")

RED = "#B22234"
WHITE = "#FFFFFF"
BLUE = "#3C3B6E"
GOLD = "#FFD700"
NIGHT = "#050818"

WIDTH = 64
HEIGHT = 32
SKY_HEIGHT = 20
TOTAL_FRAMES = 30

COLORS = [GOLD, RED, WHITE, "#66CCFF"]

FIREWORKS = [
    {"cx": 12, "cy": 7, "offset": 0},
    {"cx": 33, "cy": 5, "offset": 7},
    {"cx": 52, "cy": 9, "offset": 4},
]

STARS = [
    (4, 2), (20, 3), (44, 2), (60, 4),
    (8, 12), (26, 13), (40, 14), (58, 12),
]

CYCLE = 10
GROW_FRAMES = 6

def burst_particles(cx, cy, radius, color):
    children = []

    # inner glow
    if radius > 0:
        gx = cx - 1
        gy = cy - 1
        if gx >= 0 and gy >= 0 and gx + 2 <= WIDTH and gy + 2 <= SKY_HEIGHT:
            children.append(
                render.Padding(
                    pad = (gx, gy, 0, 0),
                    child = render.Box(width = 2, height = 2, color = color),
                ),
            )

    dirs = [
        (0, -1), (0, 1), (-1, 0), (1, 0),
        (-1, -1), (1, -1), (-1, 1), (1, 1),
    ]
    for (dx, dy) in dirs:
        x = cx + dx * radius
        y = cy + dy * radius
        if x >= 0 and x < WIDTH and y >= 0 and y < SKY_HEIGHT:
            children.append(
                render.Padding(
                    pad = (x, y, 0, 0),
                    child = render.Box(width = 1, height = 1, color = color),
                ),
            )
    return children

def sky_frame(t):
    children = [render.Box(width = WIDTH, height = SKY_HEIGHT, color = NIGHT)]

    for i, (sx, sy) in enumerate(STARS):
        if (t + i) % 4 != 0:
            children.append(
                render.Padding(
                    pad = (sx, sy, 0, 0),
                    child = render.Box(width = 1, height = 1, color = WHITE),
                ),
            )

    for fw in FIREWORKS:
        local_t = (t + fw["offset"]) % CYCLE
        if local_t < GROW_FRAMES:
            radius = local_t + 1
            burst_index = ((t + fw["offset"]) // CYCLE) % len(COLORS)
            color = COLORS[burst_index]
            children.extend(burst_particles(fw["cx"], fw["cy"], radius, color))

    return render.Stack(children = children)

def stripe_accent():
    return render.Column(
        children = [
            render.Box(width = WIDTH, height = 1, color = RED),
            render.Box(width = WIDTH, height = 1, color = WHITE),
            render.Box(width = WIDTH, height = 1, color = BLUE),
        ],
    )

def banner():
    return render.Box(
        width = WIDTH,
        height = HEIGHT - SKY_HEIGHT - 3,
        color = "#000000",
        child = render.Marquee(
            width = WIDTH,
            child = render.Text(
                content = "HAPPY 4TH OF JULY!   ",
                color = GOLD,
                font = "tb-8",
            ),
        ),
    )

def main(config):
    frames = []
    for t in range(TOTAL_FRAMES):
        frame = render.Column(
            children = [
                sky_frame(t),
                stripe_accent(),
                banner(),
            ],
        )
        frames.append(frame)

    return render.Root(
        delay = 120,
        child = render.Animation(children = frames),
    )
