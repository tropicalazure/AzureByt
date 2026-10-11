"""
MLB Standings - a Pixlet app for Tidbyt / TronByt

Smoothly scrolls through every division. Each division leads with a two-tone,
gold-accented header bar, followed by a row per team showing the real team logo
(dark-bg PNG badge), abbreviation, games-back, and W-L record. The division
leader is highlighted in gold.

Single data source: the free public MLB Stats API (no key required).
64x32 display.
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")

# --- Constants ---------------------------------------------------------------

WHITE = "#ffffff"
GREY = "#7e8794"
GOLD = "#ffcf33"
BLACK = "#000000"

# League palettes: a lighter top and darker bottom give the header bar depth,
# with a gold hairline underneath tying it to the leader highlight.
AL_LIGHT = "#d11a35"
AL_DARK = "#7c0a1c"
NL_LIGHT = "#16489c"
NL_DARK = "#0a234f"

STANDINGS_URL = "https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season={}&standingsTypes=regularSeason"
LOGO_URL = "https://a.espncdn.com/i/teamlogos/mlb/500-dark/{}.png"
MLB_LOGO_URL = "https://a.espncdn.com/i/teamlogos/leagues/500-dark/mlb.png"

# Display order + label + (light, dark) header colors + league for each
# division id.
DIVISIONS = [
    (201, "AL EAST", AL_LIGHT, AL_DARK, "AL"),
    (202, "AL CENTRAL", AL_LIGHT, AL_DARK, "AL"),
    (200, "AL WEST", AL_LIGHT, AL_DARK, "AL"),
    (204, "NL EAST", NL_LIGHT, NL_DARK, "NL"),
    (205, "NL CENTRAL", NL_LIGHT, NL_DARK, "NL"),
    (203, "NL WEST", NL_LIGHT, NL_DARK, "NL"),
]

# MLB team id -> short abbreviation (standings API has team.name, not abbr).
TEAM_ABBR = {
    108: "LAA",
    109: "AZ",
    110: "BAL",
    111: "BOS",
    112: "CHC",
    113: "CIN",
    114: "CLE",
    115: "COL",
    116: "DET",
    117: "HOU",
    118: "KC",
    119: "LAD",
    120: "WSH",
    121: "NYM",
    133: "ATH",
    134: "PIT",
    135: "SD",
    136: "SEA",
    137: "SF",
    138: "STL",
    139: "TB",
    140: "TEX",
    141: "TOR",
    142: "MIN",
    143: "PHI",
    144: "ATL",
    145: "CWS",
    146: "MIA",
    147: "NYY",
    158: "MIL",
}

# Fallback swatch color used only if a team's logo fails to load.
TEAM_COLOR = {
    108: "#ba0021",
    109: "#a71930",
    110: "#df4601",
    111: "#bd3039",
    112: "#0e3386",
    113: "#c6011f",
    114: "#e31937",
    115: "#5d3597",
    116: "#fa4616",
    117: "#eb6e1f",
    118: "#bd9b60",
    119: "#005a9c",
    120: "#ab0003",
    121: "#ff5910",
    133: "#efb21e",
    134: "#fdb827",
    135: "#ffc425",
    136: "#00a3a3",
    137: "#fd5a1e",
    138: "#c41e3a",
    139: "#8fbce6",
    140: "#c0111f",
    141: "#1d6fe0",
    142: "#d31145",
    143: "#e81828",
    144: "#ce1141",
    145: "#c4ced4",
    146: "#00a3e0",
    147: "#c4ced4",
    158: "#ffc52f",
}

# ESPN logo slugs are the lowercased abbreviation, except for a few.
LOGO_SLUG_OVERRIDE = {109: "ari", 145: "chw", 133: "oak"}

# --- Data fetch --------------------------------------------------------------

def get_standings():
    season = time.now().in_location("America/New_York").format("2006")
    resp = http.get(STANDINGS_URL.format(season), ttl_seconds = 600)
    if resp.status_code != 200:
        return None

    by_div = {}
    for rec in resp.json().get("records", []):
        div_id = rec.get("division", {}).get("id")
        teams = []
        for t in rec.get("teamRecords", []):
            teams.append({
                "id": int(t["team"]["id"]),
                "w": int(t.get("wins", 0)),
                "l": int(t.get("losses", 0)),
                "gb": str(t.get("gamesBack", "-")),
                "rank": int(t.get("divisionRank", "9")),
            })
        teams = sorted(teams, key = lambda x: x["rank"])
        by_div[div_id] = teams
    return by_div

def logo_slug(team_id):
    return LOGO_SLUG_OVERRIDE.get(team_id, TEAM_ABBR.get(team_id, "mlb").lower())

def get_logo(url):
    resp = http.get(url, ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    return resp.body()

# --- Render ------------------------------------------------------------------

def abbr(team_id):
    return TEAM_ABBR.get(team_id, "?")

def logo_widget(team_id, size):
    img = get_logo(LOGO_URL.format(logo_slug(team_id)))
    if img == None:
        return render.Box(width = size, height = size, color = TEAM_COLOR.get(team_id, GREY))
    return render.Image(src = img, width = size, height = size)

def team_row(t, is_leader, idx):
    # Each division page packs a header + five rows into 32px, so a row is just
    # 6px tall with a small logo and the compact 3x5 pixel font.
    bg = "#1a2029" if idx % 2 == 0 else "#0b0e13"
    if is_leader:
        bg = "#243a52"
    txt = GOLD if is_leader else WHITE
    rec = "{}-{}".format(t["w"], t["l"])

    # Trim a trailing ".0" so whole-number games-back stays narrow ("11" not
    # "11.0"), which keeps it from crowding the abbreviation.
    gb = t["gb"]
    if gb.endswith(".0"):
        gb = gb[:-2]

    # games-back (grey) sits just left of the W-L so every record lines up flush
    # right; the leader shows no games-back.
    right_kids = []
    if not is_leader and gb != "-":
        right_kids.append(render.Text(gb, font = "CG-pixel-3x5-mono", color = GREY))
        right_kids.append(render.Box(width = 3, height = 1))
    right_kids.append(render.Text(rec, font = "CG-pixel-3x5-mono", color = txt))

    return render.Box(
        width = 64,
        height = 5,
        color = bg,
        child = render.Padding(
            pad = (2, 0, 2, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            logo_widget(t["id"], 5),
                            render.Box(width = 2, height = 1),
                            render.Text(abbr(t["id"]), font = "CG-pixel-3x5-mono", color = txt),
                        ],
                    ),
                    render.Row(cross_align = "center", children = right_kids),
                ],
            ),
        ),
    )

def division_header(label, light, dark, mlb_logo):
    # Fixed (non-scrolling) title bar: a league-colored band with the MLB badge
    # and the division name centered over it.
    bar = render.Box(width = 64, height = 7, color = light)
    logo = render.Image(src = mlb_logo, width = 5, height = 5) if mlb_logo != None else render.Box(width = 5, height = 5)

    # tom-thumb's glyphs hug the top of their cell, so centering looks top-heavy;
    # a 1px top pad optically centers the label within the 7px band.
    label_layer = render.Box(
        width = 64,
        height = 7,
        child = render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    logo,
                    render.Box(width = 2, height = 1),
                    render.Text(label, font = "tom-thumb", color = WHITE),
                ],
            ),
        ),
    )
    return render.Stack(children = [bar, label_layer])

def division_page(label, light, dark, teams, mlb_logo):
    # A complete 64x32 screen: fixed header on top, all five teams below.
    rows = [team_row(t, i == 0, i) for i, t in enumerate(teams)]
    return render.Box(
        width = 64,
        height = 32,
        color = BLACK,
        child = render.Column(children = [division_header(label, light, dark, mlb_logo)] + rows),
    )

def selected_divisions(view):
    """Which divisions to render this cycle, in display order."""
    if view == "al":
        return [d for d in DIVISIONS if d[4] == "AL"]
    if view == "nl":
        return [d for d in DIVISIONS if d[4] == "NL"]
    if view == "alternate":
        # Flip leagues over time so a viewer sees AL, then NL, then AL...
        league = "AL" if (time.now().unix // 120) % 2 == 0 else "NL"
        return [d for d in DIVISIONS if d[4] == league]

    # Otherwise a specific division id was chosen.
    return [d for d in DIVISIONS if str(d[0]) == view]

def error_screen(msg):
    return render.Root(
        child = render.Box(
            color = BLACK,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Text("MLB", font = "6x13", color = AL_LIGHT),
                    render.Text(msg, font = "tom-thumb", color = GREY),
                ],
            ),
        ),
    )

# --- Main --------------------------------------------------------------------

def main(config):
    data = get_standings()
    if data == None:
        return error_screen("No data")

    mlb_logo = get_logo(MLB_LOGO_URL)
    view = config.get("view", "alternate")

    pages = []
    for div_id, label, light, dark, _league in selected_divisions(view):
        teams = data.get(div_id)
        if teams == None or len(teams) == 0:
            continue
        pages.append(division_page(label, light, dark, teams, mlb_logo))

    if len(pages) == 0:
        return error_screen("No data")

    # A single division is just a static screen; multiple divisions flip as
    # pages, each held long enough to read and well inside Tidbyt's ~15s window.
    if len(pages) == 1:
        return render.Root(child = pages[0])

    return render.Root(
        delay = 3500,
        child = render.Animation(children = pages),
    )

def get_schema():
    options = [
        schema.Option(display = "Alternate AL / NL", value = "alternate"),
        schema.Option(display = "American League", value = "al"),
        schema.Option(display = "National League", value = "nl"),
    ]
    for div_id, label, _l, _d, _lg in DIVISIONS:
        options.append(schema.Option(display = label, value = str(div_id)))
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "view",
                name = "Show",
                desc = "One league per cycle (alternating), a single league, or one division.",
                icon = "baseball",
                default = "alternate",
                options = options,
            ),
        ],
    )
