"""
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
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
t8SfzWfWH3/74VcA
""")

ANIM_PILGRIM = base64.decode("""
UklGRjIHAABXRUJQVlA4WAoAAAASAAAAPwAAHwAAQU5JTQYAAAAAAAAAAABBTk1GBgIAAAAAAAAA
AD8AAB8AALQAAAJWUDhM7QEAAC8/wAcAz8Cotm0l323kNhUCaAciMKUTEViEoAgdiEASRY0kqdnl
3WMycA7ue0wDAITkJ/3ym6xhJTNYSDKHZojLb5r/UINH7Aj6/XRTJF007NaJxhwYPIkqcHkdGF5Q
b3Hj5L/HG1fPNmr1yaENWKDZeDldWIGTkEFibdtS29ytF7+fBGTNttN/pTEaEmggov8K3LZROuqO
8RNvh9vH7fDmnyYAAAAAAO7W+K8TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABrXcNut9vtdpvi
11a4Lf4etw2w9D07LxNM03SbptWWe7k8rGCpO3z3+665r1ib37F7cjscDofD/XqOx//WJ/zw+AnO
DoePH4c/f27rxjs+3dHznXvCVvt7y3VN0zQ5uMP7yvWLPep9/WHtgV7jfQN7okvvzb7MPM/zvGAz
e4KtbL/fb4v97VsXarO46HynW7n9E7dl8T226/bCfm6g13merw9rOJ1Opw3wXf4En3+xvl2vS/nq
bowxxtcYY4wx7hZxHM9X8XuM8WIhl1fL6O7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u6u
qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqkqSJEmSJEmSJEmSJEmSJEmSJEmSJEmSJAEA
QU5NRsQAAAABAAADAAA9AAAKAAC0AAAAVlA4TKsAAAAvPYACEEegJgCQBq49b+rQwP4FTKQ4kqTk
XHB4EQSBEraqyDao600FbZSXQRV/8x8A4KfvK/gN9fDu+3LOxpQFNpFtOzk//zINfXCAAyTwKxxQ
IwHt+eEgov8K27ZBxgxvACEEADgiAAAA5zEXt6YehAhaqouS5pJiTUbVP1oZdcbvKn9b296BJjnE
oWkY+3FSYlirBoq5HTHbV7i/eev/U9I/6uSJnHPOYgYAQU5NRoYAAAAKAAADAAArAAAKAAC0AAAA
VlA4TG0AAAAvK4ACEDegppEUOHjdS4kdZKCojRRoDZy8EYI4xBMJkNA4YPL/Ie+Y5j8AzLT+9oLU
7XwERpEkRUrON0jBAwKQgH8d7Kkgov9q0zZgNqceghYAAAAAAAAAAOz6U7//+bmKt1fjGY9G/HA9
H7sAAEFOTUbMAAAAAQAAAwAAPQAADQAAtAAAAFZQOEyzAAAALz1AAxA/oCYAEgYucDSwjg3sX8BE
SgIAQfDmiREMZbaiNlKgXW4s4Ab/BrDCb/4DAD1zrvGdPN2+l7O24Ka2banZzO0MLes7wEEk/F/F
Qer4b5kdRPRfYdu2TfZO2jOQZRkAAMDOy9K8oiWmtnnBXcyKdLqhfbKmyQpF9kCdD01k4vPEfxq6
thuqO/vikd2212/Pxbfw6rN/2sOaF8YaQgjh/LsAAAAAAAAAAO++4FPeHQIAQU5NRn4AAAAKAAAH
AAArAAAIAAC0AAAAVlA4TGYAAAAvKwACEDegppEUOHjdS4kdZKCojRRoDZy8EYI4xBMJkNA4YPL/
Ie+Y5j8AzLT+9oLU7XwEVpEktWridzKAGAQg4fk3Eg1E9F9t2gbMlJ5DTAAA9BVcFQCAR3gKAHx0
2wIA8IPe9xlBTk1G1gAAAAEAAAMAAD0AABAAALQAAABWUDhMvQAAAC89AAQQR6AmAJAGrj1v6tDA
/gVMpDiSpORccHgRBIEStqrINqjrTQVtlJdBFX/zHwDgp+8r+A318O77cs7GlAXHtW1XyebPMIHl
HOmADixBRnbg2BKsnZ+JFUT0X2Hbtk32Ttoz0HUdAADAzutaZNEaxmeRwa9QFWOOLqpiix/Vo/7N
nxul0CTrsNznaV6K9MxYYqiSIe7Ts757OtQdH1gkJWKMMSZX/4zlPvDb/zzkDQAAAAAAAAD8N5yw
EQBBTk1GggAAAAoAAAUAACsAAAoAALQAAABWUDhMagAAAC8rgAIQL6CmbSM41e0fj84paiMFWgMn
b4QgDvFEAiQ0Dpj8f8g7pvkPAJvW312Q+h2wiiSpVZP+QQoeEIB/O+kFBRH9V5u2ATOn5wyoAQAW
lgAAAACe6eMF1p/5m0MEAIB/mS9/an/6zAJBTk1G3AAAAAEAAAMAAD0AABIAALQAAABWUDhMxAAA
AC89gAQQT6AmAAiGa89OGuhfQCLFkSQl54LDiwiIlbAVNJLUfC/gADeYRwNWeuY/AICf1u2rV+FX
1N3d5WVa66YMcFTbtpvsR2fWi4wUBThAQjLDAVMkYDm9YCCi/wrbtm2yd9KegYgAAABo+PHYTaJH
UR52E/hYxKqconexsorx6lASirAYCd/b5Xg4XjbjM89mYlXXuWIY3is03z0+0aqbAEme53neOeK1
BgAAAAAAAAAAAAAAAMDkKfFn9Zn1xt9++BQ=
""")

ANIM_FEATHER = base64.decode("""
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
AAAAAAAAYPKU+LP6zHrjbz98CgA=
""")

ANIM_NONE = base64.decode("""
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
s/rMeuNvP3wKAA==
""")

ASSETS = {
    "both": ANIM_BOTH,
    "pilgrim": ANIM_PILGRIM,
    "feather": ANIM_FEATHER,
    "none": ANIM_NONE,
}

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
