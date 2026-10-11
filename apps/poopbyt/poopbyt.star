"""
Applet: PoopByt
Summary: A silly poop buddy's bathroom day
Description: A smiling poop emoji has a busy day in the bathroom: sitting on the
potty, brushing his teeth, taking a bubble bath, singing into a plunger, and
flushing away with a wave. Ends with a reminder to wash your hands!
"""

load("render.star", "render")

W = 64
H = 32
DELAY = 100
SCENE_LEN = 30

# Colors
WALL = "#1d6a86"
GROUT = "#2b88a8"
BASEBOARD = "#d9d9e6"
FLOOR_A = "#e6e6ee"
FLOOR_B = "#4a3f7a"
WHITE = "#ffffff"
GRAY = "#8f99ad"
CHROME = "#c7d0e0"
BROWN_D = "#4a2a10"
BROWN = "#8a5426"
BROWN_L = "#c08040"
BLACK = "#000000"
MOUTH = "#3a0a0a"
TONGUE = "#ff6b81"
PINK = "#ff7aa8"
BLUSH = "#ff5e7e"
YELLOW = "#ffd93b"
ORANGE = "#ff9a1f"
GREEN = "#6dff7a"
CYAN = "#46e0ff"
WATER = "#5ec8ff"
BUBBLE = "#bfefff"
RED = "#e0332f"
WOOD = "#e0b060"
GOLD = "#e8b830"

POOP = [
    "......dd......",
    ".....dlbd.....",
    "....dlbbbd....",
    "...dddddddd...",
    "..dlbbbbbbbd..",
    "..dbbbbbbbbd..",
    ".dddddddddddd.",
    "dlbbbbbbbbbbbd",
    "dlbbbbbbbbbbbd",
    "dbbbbbbbbbbbbd",
    "dbbbbbbbbbbbbd",
    "dbbbbbbbbbbbbd",
    ".dddddddddddd.",
]
POOP_PAL = {"d": BROWN_D, "b": BROWN, "l": BROWN_L}

DUCK = [
    ".yy....",
    "oky....",
    ".yy..yy",
    ".yyyyyy",
    "..yyyy.",
]
DUCK_PAL = {"y": YELLOW, "o": ORANGE, "k": BLACK}

NOTE = [
    "..##",
    "..#.",
    "..#.",
    ".##.",
    ".##.",
]

# ---------- canvas helpers ----------

def make_bg():
    rows = []
    for y in range(H):
        row = []
        for x in range(W):
            if y < 22:
                c = GROUT if (x % 8 == 7 or y % 8 == 7) else WALL
            elif y == 22:
                c = BASEBOARD
            else:
                c = FLOOR_A if ((x // 4) + ((y - 23) // 4)) % 2 == 0 else FLOOR_B
            row.append(c)
        rows.append(row)
    return rows

def copy_bg(bg):
    return [list(r) for r in bg]

def px(cv, x, y, c):
    if x >= 0 and x < W and y >= 0 and y < H and c != None:
        cv[y][x] = c

def rect(cv, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(cv, xx, yy, c)

def sprite(cv, x, y, rows, pal):
    for j in range(len(rows)):
        row = rows[j]
        for i in range(len(row)):
            ch = row[i]
            if ch != ".":
                px(cv, x + i, y + j, pal[ch])

def bubble(cv, x, y, big):
    if big:
        for (dx, dy) in [(1, 0), (2, 0), (0, 1), (3, 1), (0, 2), (3, 2), (1, 3), (2, 3)]:
            px(cv, x + dx, y + dy, BUBBLE)
        px(cv, x + 1, y + 1, WHITE)
    else:
        for (dx, dy) in [(1, 0), (0, 1), (2, 1), (1, 2)]:
            px(cv, x + dx, y + dy, BUBBLE)

def sparkle(cv, x, y, c):
    px(cv, x, y, WHITE)
    px(cv, x - 1, y, c)
    px(cv, x + 1, y, c)
    px(cv, x, y - 1, c)
    px(cv, x, y + 1, c)

def note(cv, x, y, c):
    sprite(cv, x, y, NOTE, {"#": c})

def to_widget(cv):
    rows = []
    for y in range(H):
        row = cv[y]
        kids = []
        start = 0
        for x in range(1, W + 1):
            if x == W or row[x] != row[start]:
                kids.append(render.Box(width = x - start, height = 1, color = row[start]))
                start = x
        rows.append(render.Row(children = kids))
    return render.Column(children = rows)

def txt(x, y, s, c):
    return [
        render.Padding(pad = (x + 1, y + 1, 0, 0), child = render.Text(s, font = "tom-thumb", color = BLACK)),
        render.Padding(pad = (x, y, 0, 0), child = render.Text(s, font = "tom-thumb", color = c)),
    ]

# ---------- the star of the show ----------

def draw_poop(cv, x, y, eyes = "open", look = 0, mouth = "smile", blush = False, arms = "down", cap = False):
    sprite(cv, x, y, POOP, POOP_PAL)

    if eyes == "open":
        for ex in [3, 9]:
            rect(cv, x + ex, y + 6, 2, 3, WHITE)
            rect(cv, x + ex + look, y + 7, 1, 2, BLACK)
    elif eyes == "happy":
        for ex in [2, 9]:
            px(cv, x + ex, y + 8, BLACK)
            px(cv, x + ex + 1, y + 7, BLACK)
            px(cv, x + ex + 2, y + 8, BLACK)
    elif eyes == "squint":
        for (dx, dy) in [(3, 6), (4, 7), (3, 8), (10, 6), (9, 7), (10, 8)]:
            px(cv, x + dx, y + dy, BLACK)

    if blush:
        rect(cv, x + 1, y + 9, 2, 1, BLUSH)
        rect(cv, x + 11, y + 9, 2, 1, BLUSH)

    if mouth == "smile":
        rect(cv, x + 4, y + 10, 6, 1, MOUTH)
        rect(cv, x + 5, y + 11, 4, 1, MOUTH)
        rect(cv, x + 6, y + 11, 2, 1, TONGUE)
    elif mouth == "teeth":
        rect(cv, x + 4, y + 10, 6, 1, WHITE)
        rect(cv, x + 5, y + 11, 4, 1, MOUTH)
    elif mouth == "o":
        rect(cv, x + 6, y + 9, 2, 1, MOUTH)
        rect(cv, x + 5, y + 10, 4, 1, MOUTH)
        rect(cv, x + 6, y + 11, 2, 1, MOUTH)
    elif mouth == "wavy":
        for (dx, dy) in [(4, 10), (5, 11), (6, 10), (7, 11), (8, 10), (9, 11)]:
            px(cv, x + dx, y + dy, MOUTH)

    if arms == "down":
        for (dx, dy) in [(-1, 9), (-2, 10), (14, 9), (15, 10)]:
            px(cv, x + dx, y + dy, BROWN_D)
    elif arms == "up":
        for (dx, dy) in [(-1, 8), (-2, 7), (-2, 6), (14, 8), (15, 7), (15, 6)]:
            px(cv, x + dx, y + dy, BROWN_D)
    elif arms == "wave1":
        for (dx, dy) in [(-1, 9), (-2, 10), (14, 8), (15, 7), (16, 6)]:
            px(cv, x + dx, y + dy, BROWN_D)
    elif arms == "wave2":
        for (dx, dy) in [(-1, 9), (-2, 10), (14, 8), (15, 7), (15, 6), (14, 5)]:
            px(cv, x + dx, y + dy, BROWN_D)

    if cap:
        rect(cv, x + 5, y - 1, 4, 1, PINK)
        rect(cv, x + 3, y, 8, 2, PINK)
        rect(cv, x + 2, y + 2, 10, 1, PINK)
        for (dx, dy) in [(5, 0), (8, 1), (4, 1), (2, 2), (5, 2), (8, 2), (11, 2)]:
            px(cv, x + dx, y + dy, WHITE)

# ---------- bathroom furniture ----------

BOWL = [(20, 10), (21, 10), (22, 9), (23, 9), (24, 8), (25, 7), (26, 6), (27, 5), (28, 5), (29, 6), (30, 6)]

def draw_tank(cv, cx, pressed = False):
    rect(cv, cx - 9, 3, 18, 1, WHITE)
    rect(cv, cx - 9, 4, 18, 1, GRAY)
    rect(cv, cx - 8, 5, 16, 10, GRAY)
    rect(cv, cx - 7, 5, 14, 9, WHITE)
    rect(cv, cx - 6, 8 if pressed else 7, 3, 1, CHROME)

def draw_bowl(cv, cx):
    for (yy, hw) in BOWL:
        rect(cv, cx - hw, yy, hw * 2, 1, WHITE)
        px(cv, cx - hw, yy, GRAY)
        px(cv, cx + hw - 1, yy, GRAY)
    rect(cv, cx - 10, 21, 20, 1, CHROME)
    rect(cv, cx - 6, 30, 12, 1, GRAY)

def draw_sink(cv):
    rect(cv, 4, 2, 16, 11, CHROME)
    rect(cv, 5, 3, 14, 9, "#9fe3ff")
    for i in range(4):
        px(cv, 7 + i, 7 - i, WHITE)
        px(cv, 9 + i, 8 - i, WHITE)
    rect(cv, 11, 12, 2, 2, CHROME)
    rect(cv, 2, 14, 20, 1, GRAY)
    rect(cv, 2, 15, 20, 2, WHITE)
    rect(cv, 4, 17, 16, 1, WHITE)
    rect(cv, 9, 18, 6, 11, WHITE)
    rect(cv, 9, 18, 1, 11, GRAY)
    rect(cv, 14, 18, 1, 11, GRAY)
    rect(cv, 7, 29, 10, 2, WHITE)

def draw_tub(cv):
    rect(cv, 6, 12, 4, 1, CHROME)
    rect(cv, 6, 13, 1, 4, CHROME)
    rect(cv, 4, 17, 56, 1, WHITE)
    rect(cv, 4, 18, 56, 1, GRAY)
    rect(cv, 5, 19, 54, 8, WHITE)
    rect(cv, 5, 19, 1, 8, GRAY)
    rect(cv, 58, 19, 1, 8, GRAY)
    rect(cv, 7, 27, 50, 1, GRAY)
    rect(cv, 9, 28, 3, 2, GOLD)
    rect(cv, 52, 28, 3, 2, GOLD)

# ---------- scenes ----------

def scene_potty(bg, t):
    cv = copy_bg(bg)
    texts = []
    draw_tank(cv, 32)
    if t < 10:
        draw_poop(cv, 25, 8, look = 0 if (t // 3) % 2 == 0 else 1)
        texts += txt(1, 2, "hmm...", YELLOW)
    elif t < 18:
        draw_poop(cv, 25 + (t % 2), 8, eyes = "squint", mouth = "wavy", blush = True)
        texts += txt(0, 2, "nnngh!", ORANGE)
    elif t < 24:
        k = t - 18
        draw_poop(cv, 25, 8, look = 0, mouth = "o")
        arc = [0, 2, 4, 5, 4, 2][k]
        for (sx, d) in [(21, -1), (42, 1)]:
            px(cv, sx + d * k, 19 - arc, WATER)
            px(cv, sx + d * (k + 2), 20 - arc, WATER)
            px(cv, sx + d * k, 20 - arc, CYAN)
        texts += txt(44, 2, "PLOP!", YELLOW)
    else:
        draw_poop(cv, 25, 8, eyes = "happy", arms = "up", blush = True)
        on = t % 2 == 0
        sparkle(cv, 10 if on else 14, 12, YELLOW)
        sparkle(cv, 52 if on else 55, 16, PINK)
        sparkle(cv, 47, 11 if on else 13, CYAN)
        texts += txt(40, 2, "TA-DA!", GREEN)
    draw_bowl(cv, 32)
    return cv, texts

def scene_brush(bg, t):
    cv = copy_bg(bg)
    texts = []
    draw_sink(cv)
    x, y = 27, 10
    if t < 22:
        draw_poop(cv, x, y, eyes = "happy", mouth = "smile", arms = "none")
        bx = [0, 1, 2, 1][t % 4] - 1
        rect(cv, x + 7 + bx, y + 9, 2, 1, WHITE)
        rect(cv, x + 7 + bx, y + 10, 3, 1, CYAN)
        rect(cv, x + 10 + bx, y + 10, 8, 1, CYAN)
        px(cv, x + 15 + bx, y + 11, BROWN_D)
        px(cv, x - 1, y + 9, BROWN_D)
        px(cv, x - 2, y + 10, BROWN_D)
        foam = [(3, 11), (10, 11), (2, 10), (11, 9), (4, 12), (9, 12)]
        for i in range(3):
            fx, fy = foam[(t + i * 2) % len(foam)]
            px(cv, x + fx, y + fy, WHITE)
        for i in range(3):
            ph = (t + i * 4) % 12
            bubble(cv, x + 1 - i * 3 - ph // 4, y + 8 - ph, i == 1)
        texts += txt(44, 2, "SCRUB", YELLOW if (t // 3) % 2 == 0 else CYAN)
    else:
        draw_poop(cv, x, y, eyes = "happy", mouth = "teeth", arms = "up", blush = True)
        if t % 2 == 0:
            sparkle(cv, x + 8, y + 8, YELLOW)
        sparkle(cv, x + 17, y + 3, WHITE)
        texts += txt(39, 2, "SHINY!", GREEN)
    return cv, texts

def scene_bath(bg, t):
    cv = copy_bg(bg)
    texts = []
    sway = [0, 0, 1, 1, 1, 0, 0, -1, -1, -1][t % 10]
    draw_tub(cv)
    draw_poop(cv, 25 + sway, 3, eyes = "happy", mouth = "smile", blush = True, arms = "none", cap = True)
    for x in range(5, 59):
        h = 1 + (x * 7 + t // 3) % 2
        for yy in range(17 - h, 18):
            px(cv, x, yy, WHITE if (x + yy) % 3 else BUBBLE)
    sprite(cv, 46, 11 + (t // 3) % 2, DUCK, DUCK_PAL)
    for (bx, off, big) in [(12, 0, True), (18, 6, False), (41, 3, False), (55, 9, True)]:
        ph = (t + off) % 14
        if ph < 12:
            bubble(cv, bx + (ph // 3) % 2, 14 - ph, big)
        else:
            sparkle(cv, bx + 1, 3, WHITE)
    texts += txt(1, 1, "RUB-A", PINK if (t // 5) % 2 == 0 else YELLOW)
    texts += txt(44, 1, "DUB!", YELLOW if (t // 5) % 2 == 0 else PINK)
    return cv, texts

def scene_sing(bg, t):
    cv = copy_bg(bg)
    texts = []
    bounce = [0, 1, 2, 1][t % 4]
    x, y = 24, 10 - bounce

    # disco floor lights
    colors = [PINK, YELLOW, GREEN, CYAN]
    for i in range(4):
        tx = 4 + i * 16 + (8 if (t // 4) % 2 else 0)
        rect(cv, tx, 23, 4, 4, colors[(i + t // 4) % 4])

    draw_poop(cv, x, y, eyes = "happy", mouth = "o" if (t // 3) % 2 == 0 else "smile", blush = True, arms = "none")
    for dy in [9, 10, 11]:
        px(cv, x + 10, y + dy, "#8a1a18")
    for dy in [9, 10, 11]:
        px(cv, x + 11, y + dy, RED)
    px(cv, x + 12, y + 10, RED)
    for i in range(6):
        px(cv, x + 13 + i, y + 10 + i, WOOD)
    px(cv, x + 15, y + 11, BROWN_D)
    px(cv, x - 1, y + 9, BROWN_D)
    px(cv, x - 2, y + 8, BROWN_D)
    px(cv, x - 3, y + 7, BROWN_D)

    ncol = [YELLOW, PINK, GREEN, ORANGE]
    for i in range(4):
        ph = (t + i * 5) % 18
        if i % 2 == 0:
            nx = 44 + i * 4 + ph // 4
        else:
            nx = 14 - i * 3 - ph // 4
        note(cv, nx, 18 - ph, ncol[i])
    texts += txt(16, 1, "LA LA LA", ncol[(t // 3) % 4])
    return cv, texts

def scene_flush(bg, t):
    cv = copy_bg(bg)
    texts = []
    draw_tank(cv, 32, pressed = (t >= 10 and t < 13))
    if t < 10:
        draw_poop(cv, 25, 8, eyes = "happy", arms = "wave1" if (t // 2) % 2 == 0 else "wave2", blush = True)
        texts += txt(2, 2, "BYE", YELLOW)
        texts += txt(44, 2, "BYE!", PINK)
    elif t < 22:
        k = t - 10
        draw_poop(cv, 25, 8 + k, eyes = "open" if k < 4 else "happy", look = k % 2, mouth = "o", arms = "wave1" if k % 2 == 0 else "wave2")
        for i in range(6):
            a = (k + i * 2) % 12
            sx = [22, 26, 31, 37, 41, 37, 31, 26, 22, 26, 31, 37][a]
            sy = [19, 18, 17, 18, 19, 20, 20, 20, 19, 18, 17, 18][a]
            px(cv, sx, sy, WATER if i % 2 == 0 else CYAN)
        texts += txt(40, 2, "FLUSH!" if k < 6 else "WHEEE!", CYAN)
    else:
        for (sx, sy, c) in [(30, 17, BUBBLE), (35, 16, WHITE), (44, 12, YELLOW), (52, 20, PINK)]:
            if (t + sx) % 3 != 0:
                sparkle(cv, sx, sy, c)
        texts += txt(1, 2, "WASH", YELLOW)
        texts += txt(1, 9, "YOUR", GREEN)
        texts += txt(1, 16, "HANDS!", PINK)
    draw_bowl(cv, 32)
    return cv, texts

SCENES = [scene_potty, scene_brush, scene_bath, scene_sing, scene_flush]

def main(_config):
    bg = make_bg()
    frames = []
    for scene in SCENES:
        for t in range(SCENE_LEN):
            cv, texts = scene(bg, t)
            frames.append(render.Stack(children = [to_widget(cv)] + texts))
    return render.Root(
        delay = DELAY,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )
