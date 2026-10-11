load("render.star", "render")
load("http.star", "http")
load("time.star", "time")

API_URL = "https://worldcup26.ir/get/games"

# The API's local_date/persian_date share one wall clock, and the Persian
# calendar field is Tehran time -- so local_date is Tehran time. Convert it
# to US Eastern for display. (America/New_York auto-handles EDT vs EST.)
SRC_TZ = "Asia/Tehran"
ET_TZ = "America/New_York"
TIME_FMT = "01/02/2006 15:04"
FLAG_URL = "https://flagcdn.com/w40/%s.png"

# Map the API's team_id -> ISO 3166-1 code used by flagcdn.
# England/Scotland use FIFA-style subdivision codes that flagcdn supports.
TEAM_FLAGS = {
    "1": "mx", "2": "za", "3": "kr", "4": "cz", "5": "ca", "6": "ba",
    "7": "qa", "8": "ch", "9": "br", "10": "ma", "11": "ht", "12": "gb-sct",
    "13": "us", "14": "py", "15": "au", "16": "tr", "17": "de", "18": "cw",
    "19": "ci", "20": "ec", "21": "nl", "22": "jp", "23": "se", "24": "tn",
    "25": "be", "26": "eg", "27": "ir", "28": "nz", "29": "es", "30": "cv",
    "31": "sa", "32": "uy", "33": "fr", "34": "sn", "35": "iq", "36": "no",
    "37": "ar", "38": "dz", "39": "at", "40": "jo", "41": "pt", "42": "cd",
    "43": "uz", "44": "co", "45": "gb-eng", "46": "hr", "47": "gh", "48": "pa",
}

# Official FIFA 3-letter trigram codes by team_id (NOT just the first 3
# letters of the name, e.g. Japan -> JPN, Germany -> GER).
TEAM_CODES = {
    "1": "MEX", "2": "RSA", "3": "KOR", "4": "CZE", "5": "CAN", "6": "BIH",
    "7": "QAT", "8": "SUI", "9": "BRA", "10": "MAR", "11": "HAI", "12": "SCO",
    "13": "USA", "14": "PAR", "15": "AUS", "16": "TUR", "17": "GER", "18": "CUW",
    "19": "CIV", "20": "ECU", "21": "NED", "22": "JPN", "23": "SWE", "24": "TUN",
    "25": "BEL", "26": "EGY", "27": "IRN", "28": "NZL", "29": "ESP", "30": "CPV",
    "31": "KSA", "32": "URU", "33": "FRA", "34": "SEN", "35": "IRQ", "36": "NOR",
    "37": "ARG", "38": "ALG", "39": "AUT", "40": "JOR", "41": "POR", "42": "COD",
    "43": "UZB", "44": "COL", "45": "ENG", "46": "CRO", "47": "GHA", "48": "PAN",
}

def team_code(team_id, name):
    # Prefer the official FIFA trigram; fall back to a 3-letter name truncation.
    code = TEAM_CODES.get(str(team_id))
    if code != None:
        return code
    return str(name or "TBD").upper()[0:3]

def get_flag(team_id):
    # Returns a render.Image for the team's flag, or None if unavailable.
    code = TEAM_FLAGS.get(str(team_id))
    if code == None:
        return None
    rep = http.get(FLAG_URL % code, ttl_seconds=86400)
    if rep.status_code != 200:
        return None
    return render.Image(src=rep.body(), width=12, height=7)

def side_column(team_code, score, flag):
    # Flag centered on top, 3-letter code below it, then (optionally) the score.
    children = []
    if flag != None:
        children.append(flag)
        children.append(render.Box(width=1, height=2))  # gap between flag and code
    children.append(render.Text(content=team_code, font="tom-thumb", color="#fff"))
    if score != None:
        children.append(render.Text(content=score, font="6x13", color="#fff"))

    return render.Column(
        cross_align = "center",
        children = children,
    )

# Seconds each match page is shown before rotating to the next one.
PAGE_SECONDS = 4

# Most upcoming games to rotate through when nothing is live.
MAX_UPCOMING = 6

MONTHS = {
    "01": "JAN", "02": "FEB", "03": "MAR", "04": "APR", "05": "MAY", "06": "JUN",
    "07": "JUL", "08": "AUG", "09": "SEP", "10": "OCT", "11": "NOV", "12": "DEC",
}

# Tournament round labels keyed by the API's "type" field.
ROUNDS = {
    "group": "GROUP", "r32": "ROUND 32", "r16": "ROUND 16",
    "qf": "QUARTER", "sf": "SEMI", "final": "FINAL", "third": "3RD PLACE",
}

def _num(s):
    s = str(s)
    return int(s) if s.isdigit() else 0

def clean_score(v):
    # The API sends the string "null" (not JSON null) for unplayed games;
    # show a dash for those rather than a misleading 0. A real 0-0 game
    # returns "0", so this only affects genuinely unposted scores.
    s = str(v or "").strip()
    if s == "" or s.lower() == "null":
        return "-"
    return s

def kickoff_parts(match):
    # local_date looks like "MM/DD/YYYY HH:MM"; returns (mm, dd, yyyy, hh, mn) or None.
    raw = str(match.get("local_date", "") or "")
    parts = raw.split(" ")
    if len(parts) < 2:
        return None
    d = parts[0].split("/")
    t = parts[1].split(":")
    if len(d) < 3 or len(t) < 2:
        return None
    return (d[0], d[1], d[2], t[0], t[1])

def kickoff_et(match):
    # Parse the Tehran local_date and convert to US Eastern. Returns a time
    # value, or None if the date is missing/malformed. We validate the shape
    # first because parse_time aborts the script on bad input.
    if kickoff_parts(match) == None:
        return None
    t = time.parse_time(str(match.get("local_date")), format = TIME_FMT, location = SRC_TZ)
    return t.in_location(ET_TZ)

def kickoff_key(match):
    # Sortable value so we can order upcoming games chronologically.
    t = kickoff_et(match)
    return t.unix if t != None else 0

def kickoff_label(match):
    # Returns ("JUN 27", "12:00") in US Eastern for display.
    t = kickoff_et(match)
    if t == None:
        return ("", "")
    return (t.format("Jan 2").upper(), t.format("15:04"))

def round_label(match):
    t = str(match.get("type", "") or "").lower()
    return ROUNDS.get(t, t.upper() if t != "" else "WC 26")

def has_teams(match):
    return (match.get("home_team_name_en") and match.get("away_team_name_en")) and True or False

def render_screen(match):
    # Builds one full 64x32 scoreboard page for a single match.
    home_team = team_code(match.get("home_team_id"), match.get("home_team_name_en"))
    away_team = team_code(match.get("away_team_id"), match.get("away_team_name_en"))

    home_score = clean_score(match.get("home_score"))
    away_score = clean_score(match.get("away_score"))

    # Status banner formatting
    match_status = str(match.get("time_elapsed", "")).lower()
    status_color = "#aaa"
    if match_status == "live":
        status_text = "LIVE"
        status_color = "#0f0"
    elif match_status.startswith("finished"):
        status_text = "FT"
    else:
        matchday = str(match.get("matchday", "") or "")
        status_text = ("MD " + matchday) if matchday != "" else "WC 26"

    # Flags (cached for a day); fall back to the 3-letter code if missing
    home_flag = get_flag(match.get("home_team_id"))
    away_flag = get_flag(match.get("away_team_id"))

    # Scoreboard fills the top, status sits in a thin banner along the bottom.
    return render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Box(
                height = 27,
                child = render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        side_column(home_team, home_score, home_flag),
                        render.Text(content="vs", font="tom-thumb", color="#fff"),
                        side_column(away_team, away_score, away_flag),
                    ],
                ),
            ),
            render.Box(
                width = 64,
                height = 5,
                color = status_color,
                child = render.Text(content=status_text, font="tom-thumb", color="#000"),
            ),
        ],
    )

def upcoming_screen(match):
    # Page for a future match: flags + codes, kickoff date/time, round banner.
    home_team = team_code(match.get("home_team_id"), match.get("home_team_name_en"))
    away_team = team_code(match.get("away_team_id"), match.get("away_team_name_en"))
    home_flag = get_flag(match.get("home_team_id"))
    away_flag = get_flag(match.get("away_team_id"))
    date_str, time_str = kickoff_label(match)

    return render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Matchup (no scores yet)
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    side_column(home_team, None, home_flag),
                    render.Text(content="vs", font="tom-thumb", color="#fff"),
                    side_column(away_team, None, away_flag),
                ],
            ),
            # Kickoff date + time in US Eastern (time highlighted)
            render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content=date_str, font="5x8", color="#fff"),
                    render.Box(width=3, height=1),
                    render.Text(content=time_str, font="5x8", color="#ff0"),
                ],
            ),
            # Round banner, with the timezone noted
            render.Box(
                width = 64,
                height = 5,
                color = "#39f",
                child = render.Text(content=round_label(match) + " - ET", font="tom-thumb", color="#000"),
            ),
        ],
    )

def idle_screen():
    # Shown when nothing is live and no upcoming game has teams assigned yet.
    return render.Box(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(content="WORLD CUP", font="tom-thumb", color="#fff"),
                render.Text(content="2026", font="6x13", color="#ff0"),
            ],
        ),
    )

def main():
    # Fetch data with a 60-second TTL cache for Tronbyt
    rep = http.get(API_URL, ttl_seconds=60)
    if rep.status_code != 200:
        return render.Root(
            child = render.Box(
                child = render.Text("HTTP Err: %d" % rep.status_code, font="5x8", color="#f00")
            )
        )

    # Safely parse JSON. The API returns an object: { "games": [ ... ] }
    body = rep.json()
    matches = body.get("games", []) if type(body) == "dict" else []

    # Verify we actually got a valid, non-empty list of games back
    if type(matches) != "list" or len(matches) == 0:
        return render.Root(
            child = render.Box(
                child = render.Text("No Match Data", font="5x8", color="#ff0")
            )
        )

    # Sort games into live now vs upcoming (with teams actually assigned;
    # knockout placeholders have null team names, so we skip those).
    # Status comes from "time_elapsed": live / notstarted / finished.
    live = []
    upcoming = []
    for m in matches:
        if type(m) != "dict":
            continue
        elapsed = str(m.get("time_elapsed", "")).lower()
        if elapsed == "live":
            live.append(m)
        elif elapsed == "notstarted" and has_teams(m):
            upcoming.append(m)

    # Live games take priority. Otherwise show the next upcoming matches in
    # chronological order. If none have teams yet, fall back to an idle screen.
    if len(live) > 0:
        screens = [render_screen(m) for m in live]
    elif len(upcoming) > 0:
        upcoming = sorted(upcoming, key = kickoff_key)
        screens = [upcoming_screen(m) for m in upcoming[0:MAX_UPCOMING]]
    else:
        screens = [idle_screen()]

    # One game -> static screen. Multiple live -> rotate one page per
    # PAGE_SECONDS, and ask the device to play the whole loop.
    if len(screens) == 1:
        return render.Root(child = screens[0])

    return render.Root(
        delay = PAGE_SECONDS * 1000,
        show_full_animation = True,
        child = render.Animation(children = screens),
    )