"""
Yankees Score - a Pixlet app for Tidbyt / TronByt
Styled after the official Tidbyt MLB app: "MLB" header with live status,
then a row per team showing the real "spot" logo (round PNG badge),
team abbreviation, and score (or W-L record for scheduled games).
Single data source: the free public MLB Stats API (no key required).
64x32 display.
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")

# --- Constants ---------------------------------------------------------------

TEAM_ID = 147  # New York Yankees

NAVY = "#0c2340"
WHITE = "#ffffff"
GREY = "#9aa4b2"
GREEN = "#3ad13a"
ORANGE = "#f4811f"
BLACK = "#000000"

# 3-day window: catches yesterday's final, today's game, next scheduled.
# hydrate=linescore gives score + inning in the same response.
SCHEDULE_URL = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId={}&hydrate=linescore&startDate={}&endDate={}"

# Transparent team logo PNG (no circle), recolored for dark backgrounds.
# Keyed by ESPN slug -- see logo_slug().
LOGO_URL = "https://a.espncdn.com/i/teamlogos/mlb/500-dark/{}.png"

# MLB team id -> short abbreviation (schedule API doesn't include these).
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

# Per-team background color shown behind the logo (dark, team-flavored so the
# "dark-bg" logo variant stays legible). Keyed by MLB team id.
TEAM_BG = {
    108: "#862633",
    109: "#A71930",
    110: "#000000",
    111: "#0C2340",
    112: "#0E3386",
    113: "#000000",
    114: "#0C2340",
    115: "#333366",
    116: "#0C2340",
    117: "#002D62",
    118: "#004687",
    119: "#005A9C",
    120: "#AB0003",
    121: "#002D72",
    133: "#003831",
    134: "#000000",
    135: "#2F241D",
    136: "#0C2C56",
    137: "#000000",
    138: "#0C2340",
    139: "#092C5C",
    140: "#003278",
    141: "#134A8E",
    142: "#002B5C",
    143: "#284898",
    144: "#13274F",
    145: "#000000",
    146: "#000000",
    147: "#0C2340",
    158: "#12284B",
}

# ESPN logo slugs are the lowercased abbreviation, except for a few.
LOGO_SLUG_OVERRIDE = {109: "ari", 145: "chw"}

def logo_slug(team_id):
    tid = int(team_id)
    return LOGO_SLUG_OVERRIDE.get(tid, TEAM_ABBR.get(tid, "mlb").lower())

# --- Data fetch --------------------------------------------------------------

def get_game():
    now = time.now()
    start = (now - time.parse_duration("24h")).format("2006-01-02")
    end = (now + time.parse_duration("48h")).format("2006-01-02")
    url = SCHEDULE_URL.format(TEAM_ID, start, end)

    resp = http.get(url, ttl_seconds = 60)
    if resp.status_code != 200:
        return None

    games = []
    for date in resp.json().get("dates", []):
        for g in date.get("games", []):
            games.append(g)

    if len(games) == 0:
        return None

    live = None
    upcoming = None
    final = None
    for g in games:
        state = g["status"]["abstractGameState"]  # Preview / Live / Final
        if state == "Live":
            live = g
        elif state == "Preview" and upcoming == None:
            upcoming = g
        elif state == "Final":
            final = g  # most recent wins

    if live != None:
        return live
    if upcoming != None:
        return upcoming
    return final

# --- Helpers -----------------------------------------------------------------

def get_logo(team_id):
    resp = http.get(LOGO_URL.format(logo_slug(team_id)), ttl_seconds = 86400)
    if resp.status_code != 200:
        return None
    return resp.body()

def logo_widget(team_id, size):
    # The team-color band behind the row provides the background; the logo
    # (dark-bg variant) sits directly on it.
    img = get_logo(team_id)
    if img == None:
        return render.Box(width = size, height = size)
    return render.Image(src = img, width = size, height = size)

def abbr(team_id):
    return TEAM_ABBR.get(int(team_id), "")

def header_bits(game):
    """Returns (status_text, status_color) for the right side of the header."""
    state = game["status"]["abstractGameState"]
    ls = game.get("linescore", {})

    if state == "Live":
        inning = ls.get("currentInningOrdinal", "")
        half = ls.get("inningState", "")  # Top / Bottom / Middle / End
        arrow = "^" if half in ("Top", "Middle") else "v"
        return (arrow + inning, GREEN)

    if state == "Final":
        innings = int(ls.get("currentInning", 9))
        tag = "FINAL" if innings <= 9 else "F/" + str(innings)
        return (tag, GREY)

    # Preview -> compact start time ET, e.g. "3:45P"
    t = time.parse_time(game["gameDate"]).in_location("America/New_York")
    return (t.format("3:04") + t.format("PM")[0:1], WHITE)

def right_widget(team_obj, show_score):
    """Score for live/final games, else a compact W-L record."""
    if show_score:
        return render.Text(str(int(team_obj.get("score", 0))), color = WHITE, font = "tb-8")
    rec = team_obj.get("leagueRecord", {})
    text = "{}-{}".format(int(rec.get("wins", 0)), int(rec.get("losses", 0)))
    return render.Text(text, color = WHITE, font = "tom-thumb")

# --- Render rows -------------------------------------------------------------

def team_row(team_obj, show_score):
    tid = team_obj["team"]["id"]
    bg = TEAM_BG.get(int(tid), NAVY)
    return render.Box(
        color = bg,
        height = 12,
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
                            logo_widget(tid, 11),
                            render.Box(width = 3, height = 1),
                            render.Text(abbr(tid), color = WHITE, font = "tb-8"),
                        ],
                    ),
                    right_widget(team_obj, show_score),
                ],
            ),
        ),
    )

def no_game():
    return render.Root(
        child = render.Box(
            color = BLACK,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Text("NYY", color = WHITE, font = "6x13"),
                    render.Text("No game", color = GREY),
                ],
            ),
        ),
    )

# --- Main --------------------------------------------------------------------

def main():
    game = get_game()
    if game == None:
        return no_game()

    home = game["teams"]["home"]
    away = game["teams"]["away"]

    status, status_color = header_bits(game)
    show_score = game["status"]["abstractGameState"] in ("Live", "Final")

    header = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text("MLB", color = ORANGE, font = "tb-8"),
            render.Text(status, color = status_color, font = "tb-8"),
        ],
    )

    return render.Root(
        child = render.Box(
            color = BLACK,
            child = render.Column(
                expanded = True,
                children = [
                    render.Padding(pad = (2, 0, 2, 0), child = header),
                    team_row(away, show_score),
                    team_row(home, show_score),
                ],
            ),
        ),
    )
