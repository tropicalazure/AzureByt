"""
ServerByt - home server health at a glance, for Tidbyt / TronByt.

Polls a small stdlib-only exporter (see exporter/health_exporter.py) running
on the Acer laptop that hosts this Tronbyt server, and renders a 64x32
glanceable status display:
  - a pulsing "mood orb" on the left, color-coded by overall health
  - a compact CPU / MEM / DISK / TEMP readout on the right, each colored by
    its own threshold so you can see exactly which metric is the problem
  - a scrolling marquee naming the host and a plain-English status phrase

Overall status is the worst of the four individual metric statuses. If the
exporter can't be reached, a distinct grey "no signal" state is shown
instead of crashing.

Single data source: http://192.168.50.190:9101/health (LAN-only, no auth).
64x32 display.
"""

load("render.star", "render")
load("http.star", "http")

# --- Constants -----------------------------------------------------------

EXPORTER_URL = "http://192.168.50.190:9101/health"

# Each entry is (warn_at, crit_at): value >= warn_at is WARN, >= crit_at is CRIT.
# Calibrated for this specific hardware (old Acer laptop chip, 4 cores /
# 7GB RAM) rather than generic desktop-server numbers - these mobile chips
# routinely idle in the 70s-80s C (167-190 F) under load without any damage,
# so treating that as critical would just produce constant false alarms.
THRESHOLDS = {
    "cpu_percent": (70, 90),
    "mem_percent": (75, 90),
    "disk_percent": (80, 92),
    "cpu_temp_f": (167, 190),
}

DISPLAY_NAME = "server"

METRIC_LABELS = {
    "cpu_percent": "CPU",
    "mem_percent": "MEM",
    "disk_percent": "DSK",
    "cpu_temp_f": "TMP",
}

COLOR_OK = "#2ecc71"
COLOR_OK_LIGHT = "#7fe6ab"
COLOR_WARN = "#f1c40f"
COLOR_CRIT = "#e74c3c"
COLOR_UNKNOWN = "#7f8c8d"
COLOR_BG = "#1a1a2e"
COLOR_ACCENT = "#3498db"

STATUS_RANK = {"ok": 0, "warn": 1, "unknown": 1, "crit": 2}

# --- Status logic ----------------------------------------------------------

def status_for(metric_key, value):
    if value == None:
        return "unknown"
    warn_at, crit_at = THRESHOLDS[metric_key]
    if value >= crit_at:
        return "crit"
    if value >= warn_at:
        return "warn"
    return "ok"

def color_for_status(status):
    if status == "ok":
        return COLOR_OK
    if status == "warn":
        return COLOR_WARN
    if status == "crit":
        return COLOR_CRIT
    return COLOR_UNKNOWN

def worst_status(statuses):
    worst = "ok"
    for s in statuses:
        if STATUS_RANK[s] > STATUS_RANK[worst]:
            worst = s
    return worst

def status_phrase(overall, statuses_by_metric):
    if overall == "ok":
        return "%s: all systems nominal" % DISPLAY_NAME
    problems = [METRIC_LABELS[k] for k, s in statuses_by_metric.items() if s in ("warn", "crit")]
    return "%s: check %s" % (DISPLAY_NAME, ", ".join(problems))

# --- Render pieces -----------------------------------------------------------

def metric_row(key, value, unit, status):
    color = color_for_status(status)
    label = METRIC_LABELS[key]
    text = "%s --" % label if value == None else "%s %d%s" % (label, int(value), unit)
    return render.Text(text, font = "tom-thumb", color = color)

def mood_orb(overall_status):
    color = color_for_status(overall_status)

    # Every frame uses the same diameter (12) so the orb's footprint never
    # changes size - only its color pulses/flashes. That keeps it fixed-width
    # so it can't push the stat text around as it animates.
    #
    # Healthy: gentle breathing color pulse. Warning: steady, unmoving.
    # Critical: a hard flash between the status color and black, so it reads
    # as "alarm" even out of the corner of your eye.
    if overall_status == "ok":
        frames = [
            render.Circle(color = color, diameter = 12),
            render.Circle(color = COLOR_OK_LIGHT, diameter = 12),
        ]
    elif overall_status == "crit":
        frames = [
            render.Circle(color = color, diameter = 12),
            render.Circle(color = "#000000", diameter = 12),
        ]
    else:
        frames = [render.Circle(color = color, diameter = 12)]

    orb = render.Animation(children = frames)

    # Pin the orb to a fixed-size box, belt-and-suspenders against any future
    # frame-size change reflowing the row layout.
    return render.Box(
        width = 14,
        height = 14,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [orb],
        ),
    )

def render_unreachable():
    return render.Root(
        child = render.Stack(children = [
            render.Box(width = 64, height = 32, color = COLOR_BG),
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Circle(color = COLOR_UNKNOWN, diameter = 10),
                    render.Text("no signal", font = "tom-thumb", color = COLOR_UNKNOWN),
                ],
            ),
        ]),
    )

# --- Main --------------------------------------------------------------------

def main(config):
    resp = http.get(EXPORTER_URL, ttl_seconds = 60)
    if resp.status_code != 200:
        return render_unreachable()

    data = resp.json()

    cpu = data.get("cpu_percent", None)
    mem = data.get("mem_percent", None)
    disk = data.get("disk_percent", None)
    temp_c = data.get("cpu_temp_c", None)
    temp_f = None if temp_c == None else temp_c * 9.0 / 5.0 + 32.0

    statuses = {
        "cpu_percent": status_for("cpu_percent", cpu),
        "mem_percent": status_for("mem_percent", mem),
        "disk_percent": status_for("disk_percent", disk),
        "cpu_temp_f": status_for("cpu_temp_f", temp_f),
    }
    overall = worst_status(statuses.values())

    return render.Root(
        delay = 500,
        child = render.Stack(children = [
            render.Box(width = 64, height = 32, color = COLOR_BG),
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Row(
                    expanded = True,
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (2, 0, 4, 0),
                            child = mood_orb(overall),
                        ),
                        render.Column(
                            main_align = "space_evenly",
                            children = [
                                metric_row("cpu_percent", cpu, "%", statuses["cpu_percent"]),
                                metric_row("mem_percent", mem, "%", statuses["mem_percent"]),
                                metric_row("disk_percent", disk, "%", statuses["disk_percent"]),
                                metric_row("cpu_temp_f", temp_f, "f", statuses["cpu_temp_f"]),
                            ],
                        ),
                    ],
                ),
            ),
            render.Padding(
                pad = (0, 24, 0, 0),
                child = render.Marquee(
                    width = 64,
                    child = render.Text(
                        status_phrase(overall, statuses),
                        font = "tom-thumb",
                        color = COLOR_ACCENT,
                    ),
                ),
            ),
        ]),
    )
