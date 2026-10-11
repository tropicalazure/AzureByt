"""
VestaByt
A Tidbyt/Tronbyt app that mimics the look of a Vestaboard split-flap
display: a black tile grid with white characters. Content (quotes,
facts, jokes, "on this day" trivia, word of the day) is generated on
the fly by the DeepSeek API.

This app does not talk to Vestaboard or any Vestaboard hardware/API at
all -- it's a pure visual homage, driven by its own content generator.

Rendering happens entirely on the Tronbyt server (Tidbyt/Tronbyt apps
are rendered server-side into a WebP animation and then pushed to the
physical device), so the DeepSeek API key never reaches the device --
it's read from this app's config, stored in Tronbyt's own database.
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEEPSEEK_URL = "https://api.deepseek.com/chat/completions"

# --- Board geometry -------------------------------------------------
# 10 cols x 4 rows of 6x8px tiles fills the 64x32 canvas exactly:
# 10 chars/line x 4 lines = 40 visible characters. Content longer than
# that gets truncated (no scrolling -- see main()), same as a real
# Vestaboard's fixed grid.
COLS = 10
ROWS = 4
TILE_W = 6
TILE_H = 8
FONT = "tom-thumb"

TILE_BG = "#000000"
CHAR_FG = "#ffffff"

# --- Flip animation ---------------------------------------------------
# Each non-blank tile flips through a couple of glyphs before landing
# on its final character. Letters reveal strictly one at a time (like a
# typewriter): GAP_FRAMES >= SPIN_STEPS so the next letter never starts
# spinning until the previous one has landed. Blank/space tiles aren't
# animated at all -- there's nothing to reveal. All tiles hold their
# landed character for the remaining frames once the board is settled.
SPIN_POOL = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
SPIN_STEPS = 2
GAP_FRAMES = 2
REST_FRAMES = 15
FLIP_DELAY_MS = 90

def spin_glyph(reveal_idx, step):
    idx = (reveal_idx * 17 + step * 29 + 7) % len(SPIN_POOL)
    return SPIN_POOL[idx]

MONTH_NAMES = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
]

SYSTEM_PROMPT = (
    "You generate extremely short content for a tiny LED sign styled " +
    "like a Vestaboard split-flap display. Reply with ONLY the " +
    "requested content: no preamble, no explanations, no quotation " +
    "marks, no markdown, no emoji. Keep your entire reply under 36 " +
    "characters."
)

CATEGORY_KEYS = ["quote", "fact", "joke", "onthisday", "word"]

CATEGORY_PROMPTS = {
    "quote": {
        "user": "Share one short, real, famous quote from an actual historical figure or notable person, formatted as: QUOTE - AUTHOR. Under 36 characters total.",
        "temperature": 0.8,
    },
    "fact": {
        "user": "Share one true, surprising, interesting fact. Under 36 characters.",
        "temperature": 0.9,
    },
    "joke": {
        "user": "Tell one short, original, clean one-liner joke or pun. Under 36 characters.",
        "temperature": 1.2,
    },
    "onthisday": {
        "user": "Give one real historical event that occurred on {date} (any past year). Format: YEAR - EVENT. Under 36 characters.",
        "temperature": 0.6,
    },
    "word": {
        "user": "Give one interesting, uncommon English word and a very short definition. Format: WORD - definition. Under 36 characters.",
        "temperature": 0.8,
    },
}

FALLBACKS = {
    "quote": "STAY HUNGRY STAY FOOLISH - S JOBS",
    "fact": "HONEY NEVER SPOILS",
    "joke": "I TOLD A CHEMISTRY JOKE. NO REACTION.",
    "onthisday": "SIGNAL LOST - CHECK API KEY",
    "word": "PETRICHOR - SMELL OF RAIN",
}

def main(config):
    category_pref = config.str("category", "random")

    if category_pref == "custom":
        custom_phrase = config.str("custom_phrase", "")
        if custom_phrase == "":
            custom_phrase = "ADD A CUSTOM PHRASE IN APP SETTINGS"
        lines = wrap_text(custom_phrase.upper(), COLS)[:ROWS]
        return render_board(lines)

    api_key = config.str("api_key", "")
    refresh_minutes = int(config.str("refresh_minutes", "30"))
    model = config.str("model", "deepseek-v4-flash")

    if api_key == "":
        return render_board(["ADD DEEPSEEK", "API KEY IN", "APP SETTINGS"])

    cache_key = "vestabyt_v1_%s_%s" % (category_pref, model)
    cached = cache.get(cache_key)
    if cached != None:
        data = json.decode(cached)
    else:
        cat = category_pref
        if cat == "random" or cat not in CATEGORY_KEYS:
            idx = int(random.number(0, len(CATEGORY_KEYS) - 1))
            cat = CATEGORY_KEYS[idx]
        text = fetch_content(cat, api_key, model)
        data = {"category": cat, "text": text}
        cache.set(cache_key, json.encode(data), ttl_seconds = refresh_minutes * 60)

    lines = wrap_text(data["text"].upper(), COLS)[:ROWS]
    return render_board(lines)

def fetch_content(category, api_key, model):
    prompt_cfg = CATEGORY_PROMPTS[category]
    user_prompt = prompt_cfg["user"]

    if category == "onthisday":
        now = time.now()
        today_str = MONTH_NAMES[now.month - 1] + " " + str(now.day)
        user_prompt = user_prompt.format(date = today_str)

    res = http.post(
        DEEPSEEK_URL,
        headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + api_key,
        },
        json_body = {
            "model": model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": prompt_cfg["temperature"],
            "max_tokens": 100,
            "thinking": {"type": "disabled"},
            "stream": False,
        },
    )

    if res.status_code != 200:
        return FALLBACKS[category]

    body = res.json()
    choices = body.get("choices", [])
    if len(choices) == 0:
        return FALLBACKS[category]

    text = choices[0]["message"]["content"]
    text = text.strip().strip('"').strip("'").strip()
    if text == "":
        return FALLBACKS[category]
    if len(text) > 80:
        text = text[:80]
    return text

def wrap_text(text, width):
    words = text.split(" ")
    lines = []
    cur = ""
    for w in words:
        candidate = w if cur == "" else cur + " " + w
        if len(candidate) <= width:
            cur = candidate
        else:
            if cur != "":
                lines.append(cur)
                cur = ""
            remaining = w
            for _ in range(20):
                if len(remaining) <= width:
                    break
                lines.append(remaining[:width])
                remaining = remaining[width:]
            cur = remaining
    if cur != "":
        lines.append(cur)
    return lines

def glyph_box(ch):
    return render.Box(
        width = TILE_W - 1,
        height = TILE_H - 1,
        color = TILE_BG,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [render.Text(content = ch, font = FONT, color = CHAR_FG)],
        ),
    )

def blank_tile():
    return render.Padding(
        pad = (0, 0, 1, 1),
        child = glyph_box(" "),
    )

def char_tile(ch, reveal_idx, total_frames):
    stagger = reveal_idx * GAP_FRAMES
    frames = []
    for _ in range(stagger):
        frames.append(glyph_box(" "))
    for step in range(SPIN_STEPS):
        frames.append(glyph_box(spin_glyph(reveal_idx, step)))
    settle_count = total_frames - stagger - SPIN_STEPS
    for _ in range(settle_count):
        frames.append(glyph_box(ch))
    return render.Padding(
        pad = (0, 0, 1, 1),
        child = render.Animation(children = frames),
    )

def render_board(lines):
    grid_lines = []
    for row_idx in range(ROWS):
        grid_lines.append(lines[row_idx] if row_idx < len(lines) else "")

    n_chars = 0
    for line in grid_lines:
        for i in range(COLS):
            if i < len(line) and line[i] != " ":
                n_chars += 1

    total_frames = max(n_chars - 1, 0) * GAP_FRAMES + SPIN_STEPS + REST_FRAMES

    reveal_idx = 0
    rows = []
    for line in grid_lines:
        row_children = []
        for col_idx in range(COLS):
            ch = line[col_idx] if col_idx < len(line) else " "
            if ch == " ":
                row_children.append(blank_tile())
            else:
                row_children.append(char_tile(ch, reveal_idx, total_frames))
                reveal_idx += 1
        rows.append(render.Row(children = row_children))
    grid = render.Column(children = rows)

    # No scrolling: a real Vestaboard is a fixed grid too -- content
    # that doesn't fit just gets truncated (see main()), not scrolled.
    # (Marquee also collapses to a single static frame and ignores
    # nested Animation frames whenever it doesn't need to scroll, which
    # made it a poor fit here anyway.)
    return render.Root(
        delay = FLIP_DELAY_MS,
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [grid],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "DeepSeek API Key",
                desc = "Your DeepSeek API key. Used server-side only -- never sent to the device.",
                icon = "key",
            ),
            schema.Dropdown(
                id = "category",
                name = "Content",
                desc = "What kind of content to show on the board.",
                icon = "shuffle",
                default = "random",
                options = [
                    schema.Option(display = "Surprise me (random mix)", value = "random"),
                    schema.Option(display = "Famous quotes", value = "quote"),
                    schema.Option(display = "Interesting facts", value = "fact"),
                    schema.Option(display = "Jokes", value = "joke"),
                    schema.Option(display = "On this day in history", value = "onthisday"),
                    schema.Option(display = "Word of the day", value = "word"),
                    schema.Option(display = "Custom phrase", value = "custom"),
                ],
            ),
            schema.Text(
                id = "custom_phrase",
                name = "Custom phrase",
                desc = "Your own message to display. Only used when Content is set to \"Custom phrase\" -- no DeepSeek key needed for this mode.",
                icon = "pen",
            ),
            schema.Dropdown(
                id = "refresh_minutes",
                name = "Refresh interval",
                desc = "How often to fetch new content from DeepSeek.",
                icon = "clock",
                default = "30",
                options = [
                    schema.Option(display = "Every 10 minutes", value = "10"),
                    schema.Option(display = "Every 15 minutes", value = "15"),
                    schema.Option(display = "Every 30 minutes", value = "30"),
                    schema.Option(display = "Every hour", value = "60"),
                    schema.Option(display = "Every 3 hours", value = "180"),
                ],
            ),
            schema.Dropdown(
                id = "model",
                name = "DeepSeek model",
                desc = "Flash is faster/cheaper; Pro is higher quality.",
                icon = "microchip",
                default = "deepseek-v4-flash",
                options = [
                    schema.Option(display = "Flash (fast, cheap)", value = "deepseek-v4-flash"),
                    schema.Option(display = "Pro (higher quality)", value = "deepseek-v4-pro"),
                ],
            ),
        ],
    )
