#!/usr/bin/env python3
"""Build self-contained thanksgivingbyt.star with embedded animated WebP assets."""
import base64
import os
import textwrap

ROOT = os.path.dirname(os.path.abspath(__file__))

# Read the generated WebPs
assets = {}
for style in ["both", "pilgrim", "feather", "none"]:
    path = os.path.join(ROOT, f"turkey_{style}.webp")
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing {path}, run generate_art.py first!")
    data = open(path, "rb").read()
    b64 = base64.b64encode(data).decode("ascii")
    assets[style] = "\n".join(textwrap.wrap(b64, 76))

star_code = f'''"""
Applet: ThanksgivingByt
Summary: Kentucky Thanksgiving timer
Description: Thanksgiving countdown to Kentucky on Nov 24, 2026 featuring an
animated Turkey, pilgrim hat, Native American feather motif, falling autumn
leaves, and harvest pumpkins.
Author: marka
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ANIM_BOTH = base64.decode("""
{assets["both"]}
""")

ANIM_PILGRIM = base64.decode("""
{assets["pilgrim"]}
""")

ANIM_FEATHER = base64.decode("""
{assets["feather"]}
""")

ANIM_NONE = base64.decode("""
{assets["none"]}
""")

ASSETS = {{
    "both": ANIM_BOTH,
    "pilgrim": ANIM_PILGRIM,
    "feather": ANIM_FEATHER,
    "none": ANIM_NONE,
}}

def parse_target(target_str, tz):
    # Safe validation before parse_time: YYYY-MM-DD (10 chars with hyphens)
    if len(target_str) == 10 and target_str[4] == "-" and target_str[7] == "-":
        return time.parse_time(target_str, "2006-01-02", location = tz)
    return time.time(year = 2026, month = 11, day = 24, hour = 0, minute = 0, second = 0, location = tz)

def main(config):
    tz = config.get("timezone") or config.get("$tz") or "America/New_York"
    now = time.now().in_location(tz)

    target_str = config.get("target_date") or "2026-11-24"
    target = parse_target(target_str, tz)

    destination = (config.get("destination") or "KENTUCKY").strip().upper()
    if len(destination) > 10:
        destination = destination[:10]

    hat_style = config.get("hat_style", "both")
    turkey_asset = ASSETS.get(hat_style, ANIM_BOTH)

    diff = target - now
    diff_hours = diff.hours

    # Layout elements depending on countdown progress
    if diff_hours < -96:
        # Long after trip: friendly celebration
        header_text = destination
        center_widget = render.Column(
            cross_align = "center",
            children = [
                render.Text("GOBBLE", font = "tom-thumb", color = "#ff9800"),
                render.Text("GOBBLE!", font = "tom-thumb", color = "#ffcc80"),
            ],
        )
        badge_text = "THANKS"
    elif diff_hours < -48:
        # Thanksgiving Feast Day (Nov 26-27)
        header_text = "HAPPY"
        center_widget = render.Column(
            cross_align = "center",
            children = [
                render.Text("FEAST", font = "tb-8", color = "#ff9800"),
                render.Text("DAY!", font = "tom-thumb", color = "#ffcc80"),
            ],
        )
        badge_text = "THANKS!"
    elif diff_hours <= 0:
        # Arrival / Trip Day! (Nov 24-25)
        header_text = destination
        center_widget = render.Column(
            cross_align = "center",
            children = [
                render.Text("TRIP", font = "tb-8", color = "#ff9800"),
                render.Text("DAY!", font = "tb-8", color = "#ffcc80"),
            ],
        )
        badge_text = "WE'RE IN KY!"
    elif diff_hours <= 24:
        # Final 24 hours countdown
        hrs = int(diff_hours)
        if hrs < 1:
            hrs = 1
        header_text = destination
        center_widget = render.Row(
            cross_align = "center",
            children = [
                render.Text(str(hrs), font = "tb-8", color = "#ff9800"),
                render.Box(width = 2, height = 1),
                render.Column(
                    children = [
                        render.Text("HRS", font = "tom-thumb", color = "#ffffff"),
                        render.Text("LEFT", font = "tom-thumb", color = "#ffb74d"),
                    ],
                ),
            ],
        )
        badge_text = "TOMORROW!"
    else:
        # Days countdown (> 24 hours)
        days = int((diff_hours + 23.9) / 24)
        header_text = destination
        center_widget = render.Row(
            cross_align = "center",
            children = [
                render.Text(str(days), font = "tb-8", color = "#ff9800"),
                render.Box(width = 2, height = 1),
                render.Column(
                    children = [
                        render.Text("DAYS", font = "tom-thumb", color = "#ffffff"),
                        render.Text("LEFT", font = "tom-thumb", color = "#ffb74d"),
                    ],
                ),
            ],
        )
        # Format target date badge (e.g. "NOV 24")
        badge_text = target.format("Jan 02").upper()

    return render.Root(
        delay = 180,
        child = render.Stack(
            children = [
                # Background animated turkey, foliage, and ribbon
                render.Image(src = turkey_asset, width = 64, height = 32),

                # Right column for countdown information
                render.Padding(
                    pad = (27, 2, 1, 1),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            # Top destination / trip title
                            render.Text(header_text, font = "tom-thumb", color = "#ffcc80"),

                            # Center countdown / milestone display
                            center_widget,

                            # Bottom date / status badge
                            render.Box(
                                color = "#8d2b0b",
                                height = 7,
                                child = render.Padding(
                                    pad = (3, 1, 3, 1),
                                    child = render.Text(badge_text, font = "tom-thumb", color = "#ffe0b2"),
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    hat_options = [
        schema.Option(display = "Pilgrim Hat & Native Feather", value = "both"),
        schema.Option(display = "Pilgrim Hat Only", value = "pilgrim"),
        schema.Option(display = "Native Feather Headband", value = "feather"),
        schema.Option(display = "Wild Turkey (No Hat)", value = "none"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "destination",
                name = "Trip Destination",
                desc = "Destination name to display (e.g. Kentucky).",
                icon = "mapPin",
                default = "Kentucky",
            ),
            schema.Text(
                id = "target_date",
                name = "Target Date (YYYY-MM-DD)",
                desc = "Date to count down to (default: 2026-11-24).",
                icon = "calendar",
                default = "2026-11-24",
            ),
            schema.Dropdown(
                id = "hat_style",
                name = "Turkey Theme / Hat",
                desc = "Theme styling for the turkey mascot.",
                icon = "hatCowboy",
                default = "both",
                options = hat_options,
            ),
        ],
    )
'''

out_path = os.path.join(ROOT, "thanksgivingbyt.star")
with open(out_path, "w", newline="\n") as f:
    f.write(star_code)

import shutil
import subprocess

if shutil.which("pixlet"):
    subprocess.run(["pixlet", "format", out_path], check=True)
    print("Formatted with pixlet format.")

print(f"Successfully generated {out_path} ({len(star_code)} characters)")

