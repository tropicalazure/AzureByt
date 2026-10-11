"""
PetByt - a living virtual pet for Tidbyt / TronByt.

Sprites come from Petdex (https://petdex.dev) -- a public gallery of 3000+
animated "Codex pet" companions. Each pet is a 1536x1872 spritesheet laid out
as an 8x9 grid of 192x208 frames. Rows are animation states (idle, wave, run,
sad, think, jump). We crop the row we want, frame by frame, through the
wsrv.nl image proxy (cropped + shrunk to ~26px) and cycle them with
render.Animation.

The pet is ALIVE: its mood is chosen from a deterministic daily life-clock
(sleeps at night, hungry around mealtimes, playful in the afternoon) and from
your other Tidbyt apps -- it celebrates when the Yankees win, sulks when they
lose, and gets excited while a World Cup match is live.

64x32 display.
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("encoding/json.star", "json")
load("encoding/base64.star", "base64")
load("schema.star", "schema")

# --- Constants ---------------------------------------------------------------

MANIFEST_URL = "https://petdex.dev/api/manifest"
# wsrv.nl crops a sub-rectangle (cx,cy,cw,ch) out of the sheet. IMPORTANT:
# wsrv ignores a manual crop if you ALSO ask it to resize (w/h), so we crop
# only here and let render.Image do the downscale to pet size in pixlet.
WSRV = "https://wsrv.nl/?url=%s&cx=%d&cy=%d&cw=%d&ch=%d&output=png"

FRAME_W = 192
FRAME_H = 208
COLS = 8

# How tall the pet is drawn (top area). Bottom 6px is the status bar.
PET_H = 25
PET_W = 23  # FRAME_W/FRAME_H * PET_H, rounded
STATUS_H = 7

# Animation rows within the Petdex spritesheet (0-indexed from the top).
# Petdex/Codex convention: idle, wave, run, sad/failed, think/review, jump.
ROW_IDLE = 0
ROW_WAVE = 1
ROW_RUN = 2
ROW_SAD = 3
ROW_THINK = 4
ROW_JUMP = 5

# Use the first 6 of the 8 columns; the last two are often blank padding.
FRAMES_PER_ROW = 6

# --- Colors ------------------------------------------------------------------

BLACK = "#000000"
WHITE = "#ffffff"
GREY = "#8a93a0"
GREEN = "#3ad13a"
RED = "#ff5555"
YELLOW = "#ffd23f"
BLUE = "#2f6fed"
PINK = "#ff79c6"
MOON = "#cfd6ff"

MLB_TEAM_ID = 147  # Yankees
MLB_URL = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId={}&hydrate=linescore&startDate={}&endDate={}"
WORLDCUP_URL = "https://worldcup26.ir/get/games"

# --- Pet resolution ----------------------------------------------------------

def sheet_url_for(slug):
    """Look up a pet slug in the Petdex manifest -> full spritesheet URL."""
    resp = http.get(MANIFEST_URL, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    data = resp.json()
    for pet in data.get("pets", []):
        if pet.get("slug") == slug:
            return pet.get("spritesheetUrl")
    return None

def frame_image(sheet, row, col):
    """Crop one (row,col) frame from the sheet and shrink it to pet size."""
    cx = col * FRAME_W
    cy = row * FRAME_H
    url = WSRV % (sheet, cx, cy, FRAME_W, FRAME_H)
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    # render.Image downscales the full-res frame to pet size.
    return render.Image(src = resp.body(), width = PET_W, height = PET_H)

def animation_for(sheet, row):
    """Build a render.Animation cycling through one row's frames.

    Frame speed is governed by render.Root(delay=...) at the app level.
    """
    frames = []
    for col in range(FRAMES_PER_ROW):
        img = frame_image(sheet, row, col)
        if img != None:
            frames.append(img)
    if len(frames) == 0:
        return render.Text("?", color = RED)
    return render.Animation(children = frames)

# --- Local sprites (custom mascots, no Petdex/wsrv) --------------------------
#
# "Byt" (aka MarkByt) is an original PixelLab pixel-art mascot, embedded below
# as base64 PNG frames (sources live in sprites/byt/). Unlike the Petdex pets,
# these are drawn at their NATIVE 24x29 resolution -- render.Image is given no
# width/height, so there is no downscale and no blur. Custom pets still flow
# through pick_mood -> MOOD_TABLE exactly like Petdex pets; only the final
# frame source differs, so the two kinds coexist.

BYT_FRAMES = {
    "idle": [
        "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",
    ],
    "celebrate": [
        "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",
    ],
}

# A Petdex pet has 6 animation rows; Byt has two states. Map the row that
# MOOD_TABLE hands us onto one of Byt's local animations. Energetic moods
# (celebrate/excited/play -> JUMP/RUN rows) play "celebrate"; everything else
# falls back to the idle bob.
ROW_TO_LOCAL = {
    ROW_JUMP: "celebrate",
    ROW_RUN: "celebrate",
}

# slug -> embedded frame set. Add more custom mascots here.
LOCAL_SPRITES = {
    "byt": BYT_FRAMES,
}

# slug -> display name shown on the custom-mascot screen.
LOCAL_NAMES = {
    "byt": "MarkByt",
}

def local_animation(slug, row):
    """render.Animation built from a custom pet's embedded frames (native res)."""
    frames_by_anim = LOCAL_SPRITES[slug]
    anim_name = ROW_TO_LOCAL.get(row, "idle")
    encoded = frames_by_anim.get(anim_name, frames_by_anim["idle"])
    frames = []
    for data in encoded:
        # No width/height -> native pixels, crisp (no wsrv/render downscale).
        frames.append(render.Image(src = base64.decode(data)))
    if len(frames) == 0:
        return render.Text("?", color = RED)
    return render.Animation(children = frames)

def local_screen(slug, anim, label, icon, icon_color, delay):
    """Layout for a custom mascot: native sprite on the left, status on the
    right. Byt is 29px tall and would not fit above the 7px status bar used by
    Petdex pets without scaling, so it gets the full 32px height instead."""
    pet = render.Box(
        width = 28,
        height = 32,
        color = BLACK,
        child = render.Padding(pad = (2, 2, 0, 0), child = anim),
    )
    name = LOCAL_NAMES.get(slug, slug)
    # Header already shows the name; the middle line is the mood label (may be "").
    side = render.Box(
        width = 36,
        height = 32,
        color = BLACK,
        child = render.Padding(
            pad = (1, 0, 0, 0),
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "start",
                children = [
                    render.Text(name, font = "tom-thumb", color = GREY),
                    render.Marquee(
                        width = 34,
                        child = render.Text(label, font = "tom-thumb", color = WHITE),
                    ),
                    render.Text(icon, font = "tom-thumb", color = icon_color),
                ],
            ),
        ),
    )
    return render.Root(
        delay = delay,
        child = render.Row(children = [pet, side]),
    )

# --- Mood: the life-clock + app integrations ---------------------------------

def yankees_mood(now):
    """Return a (mood, label) from today's Yankees game, or None."""
    start = (now - time.parse_duration("18h")).format("2006-01-02")
    end = (now + time.parse_duration("18h")).format("2006-01-02")
    resp = http.get(MLB_URL.format(MLB_TEAM_ID, start, end), ttl_seconds = 120)
    if resp.status_code != 200:
        return None

    game = None
    for date in resp.json().get("dates", []):
        for g in date.get("games", []):
            game = g  # most recent in window wins
    if game == None:
        return None

    state = game["status"]["abstractGameState"]  # Preview / Live / Final
    if state == "Live":
        return ("excited", "NYY LIVE")
    if state != "Final":
        return None

    # Final: did the Yankees win?
    teams = game["teams"]
    side = "home" if teams["home"]["team"]["id"] == MLB_TEAM_ID else "away"
    foe = "away" if side == "home" else "home"
    my = int(teams[side].get("score", 0))
    their = int(teams[foe].get("score", 0))
    if my > their:
        return ("celebrate", "NYY WIN!")
    return ("sad", "NYY L")

def worldcup_mood():
    """Excited while any World Cup match is live."""
    resp = http.get(WORLDCUP_URL, ttl_seconds = 120)
    if resp.status_code != 200:
        return None
    body = resp.json()
    games = body.get("games", []) if type(body) == "dict" else []
    for m in games:
        if type(m) == "dict" and str(m.get("time_elapsed", "")).lower() == "live":
            return ("excited", "WC LIVE")
    return None

def clock_mood(now):
    """Deterministic daily rhythm when nothing else is happening."""
    h = now.hour
    if h >= 22 or h < 7:
        return ("sleep", "Zzz")
    if h in (7, 8) or h in (12, 13) or h in (18, 19):
        return ("hungry", "Hungry")
    if h >= 14 and h <= 17:
        return ("play", "Playtime")
    # Late morning / evening: content. Alternate idle/wave for variety.
    if now.minute % 2 == 0:
        return ("happy", "Hi!")
    return ("idle", "")

def pick_mood(now, use_yankees, use_worldcup):
    if use_yankees:
        m = yankees_mood(now)
        if m != None:
            return m
    if use_worldcup:
        m = worldcup_mood()
        if m != None:
            return m
    return clock_mood(now)

# Mood -> (spritesheet row, animation delay ms, status icon, icon color).
# delay = ms per frame. Higher = slower/calmer. ~130 is lively, ~400 is sleepy.
MOOD_TABLE = {
    "celebrate": (ROW_JUMP, 160, "WIN", YELLOW),
    "excited": (ROW_RUN, 150, "!!", GREEN),
    "play": (ROW_RUN, 180, "*", GREEN),
    "happy": (ROW_WAVE, 230, "<3", PINK),
    "hungry": (ROW_THINK, 280, "X", RED),
    "sad": (ROW_SAD, 320, "v", BLUE),
    "sleep": (ROW_IDLE, 500, "Z", MOON),
    "idle": (ROW_IDLE, 300, "", GREY),
}

# --- Status bar --------------------------------------------------------------

def status_bar(name, label, icon, icon_color):
    text = label if label != "" else name
    return render.Box(
        width = 64,
        height = STATUS_H,
        color = "#11151f",
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (2, 0, 0, 0),
                    child = render.Marquee(
                        width = 50,
                        child = render.Text(text, font = "tom-thumb", color = WHITE),
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Text(icon, font = "tom-thumb", color = icon_color),
                ),
            ],
        ),
    )

def sleep_overlay(pet):
    """Dim-ish night scene: pet plus drifting Z's."""
    return render.Stack(children = [
        pet,
        render.Padding(
            pad = (44, 2, 0, 0),
            child = render.Marquee(
                height = 16,
                scroll_direction = "vertical",
                child = render.Column(children = [
                    render.Text("z", font = "tom-thumb", color = MOON),
                    render.Text("Z", font = "tom-thumb", color = MOON),
                ]),
            ),
        ),
    ])

def error_screen(msg):
    return render.Root(child = render.Box(
        color = BLACK,
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text("PetByt", font = "tb-8", color = YELLOW),
                render.Text(msg, font = "tom-thumb", color = GREY),
            ],
        ),
    ))

# --- Main --------------------------------------------------------------------

def main(config):
    slug = config.str("pet", "totoro")
    tz = config.str("tz", "America/New_York")
    use_yankees = config.bool("yankees", True)
    use_worldcup = config.bool("worldcup", True)

    now = time.now().in_location(tz)
    mood, label = pick_mood(now, use_yankees, use_worldcup)
    row, delay, icon, icon_color = MOOD_TABLE.get(mood, MOOD_TABLE["idle"])

    # Custom embedded mascots (e.g. "byt") skip the Petdex/wsrv crop path.
    if slug in LOCAL_SPRITES:
        anim = local_animation(slug, row)
        return local_screen(slug, anim, label, icon, icon_color, delay)

    sheet = sheet_url_for(slug)
    if sheet == None:
        return error_screen("no pet: " + slug)

    anim = animation_for(sheet, row)
    pet_area = render.Box(
        width = 64,
        height = PET_H,
        color = BLACK,
        child = anim,
    )
    if mood == "sleep":
        pet_area = render.Box(width = 64, height = PET_H, color = "#05070d", child = sleep_overlay(anim))

    return render.Root(
        delay = delay,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                pet_area,
                status_bar(slug, label, icon, icon_color),
            ],
        ),
    )

# --- Schema (mobile app config) ----------------------------------------------

CURATED = [
    ("byt", "Byt"),
    ("totoro", "Totoro"),
    ("aku", "Aku"),
    ("sea-lion", "Sea Lion"),
    ("kirby", "Kirby"),
    ("pochita", "Pochita"),
    ("snoopy", "Snoopy"),
    ("lulu-capybara", "Capybara"),
    ("king-slime", "Slime"),
    ("shiba-2", "Shiba"),
    ("corgi-cool", "Corgi"),
    ("dragon-default", "Dragon"),
    ("penguin-chick", "Penguin"),
    ("frog", "Frog"),
    ("codex-panda", "Panda"),
]

def get_schema():
    options = [schema.Option(display = d, value = v) for (v, d) in CURATED]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "pet",
                name = "Pet",
                desc = "Which Petdex companion to raise.",
                icon = "paw",
                default = "totoro",
                options = options,
            ),
            schema.Text(
                id = "tz",
                name = "Timezone",
                desc = "IANA timezone for the daily rhythm.",
                icon = "clock",
                default = "America/New_York",
            ),
            schema.Toggle(
                id = "yankees",
                name = "React to Yankees",
                desc = "Celebrate wins, sulk on losses, hype live games.",
                icon = "baseball",
                default = True,
            ),
            schema.Toggle(
                id = "worldcup",
                name = "React to World Cup",
                desc = "Get excited while a World Cup match is live.",
                icon = "futbol",
                default = True,
            ),
        ],
    )
