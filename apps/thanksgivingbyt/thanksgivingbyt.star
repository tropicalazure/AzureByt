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
AAAA0GnPx7naKAAAfnlF2AAA
""")

ANIM_PILGRIM = base64.decode("""
UklGRo4HAABXRUJQVlA4WAoAAAASAAAAPwAAHwAAQU5JTQYAAAAAAAAAAABBTk1G4gEAAAAAAAAA
AD8AAB8AALQAAAJWUDhMyQEAAC8/wAcA18Cm1rYlv7swsfnEqh1IoZnI4CTjEICNGooaSVKjvXvM
ZOBed0prbce+9meDr5E+Y1hN1IwimUMzgaR9R3XmP8zWxn+fupuu1+qvDlk0q9rqgW0QxUz8J7/J
KkPxrncb3lB+ltKZx26BBw1FZ6YlkBYkiUIayJJsO26bk2te+iEkhWiAB+5/pQRIVQGV/4j+M3Db
SFHULt3MwtEjPnLZS/5g3AIAAAAAAAAAAAAAAAAAAAAAAAAAwDRN02D+/o/8XO4hlZTGnLeUQinT
NI25sO8lpVTH5y3nPMJpTzmnx6P6UH9SSTnnR8PXn5x/fzvPuZdSKhdF6epmzkMNpdE2d+bY7yXV
pTfHfDU9ndLmbQQ1dp7bueZUuqpdqLbmeW7Jh3pSH/Rp7OQxLMuyLEsdrNvo2in1jV+WdV3X9lI6
uWdM9b5eNI7vvju1XRoN5NwYRdVlMURvPEDtXJfRn5/9G82re/rn3u73+61/wOsi7n7/vt/v4+nv
16vGterq+ImIiIiIiIiIiIiIiH/vtvF8u6/zfm3btm3btm3btm3btm3btm3btm3btm3btiVJkiRJ
kiRJkiRJkiRJkiRJkiRJkiRJkgAAQU5NRnAAAAABAAACAAAUAAAOAAC0AAAAVlA4TFgAAAAvFIAD
ECdAmG00gBlM7Pz/50OQbZsbwzgGc4UratsG6rcUyh/etTGY/wBQLfreblAISZLTFwAe4f1Bs0BE
/9WmbcDsdsobABgAAAAAAAAAAAAAsPw16xvcQU5NRlQBAAAAAAAAAAAWAAAZAAC0AAAAVlA4TDwB
AAAvFkAGEIegJpKt5v9fJUqGLmuJGhCIIGSgSFEkqXGYG54UCshtIUoj2Wq+SmBRSByOFmiPblC0
QiM5zfwHAHBlO/tIEObmSovh8WtaOxcz/41zwJeqW7S5eB4ESAAxku22zX0BD1EM/XdL/g84VBDR
f4Vt2zZAkm6P5gsAAAAAAAAAAABIKaXfRQGA/1rokLYyjuPgOFJK24P7PiT5fu5jDFsS3YyhOXMf
wNgZGTCDhvMD1/VgviRvjeZ8d8BhuBO/EuFzB3p2DXPOHXDIqNkxJEnxq7L65vcg50x4FhA0XnM+
83vLEz0WF4K452MeW3+11lprzjmmHQLV2lpr8anQYZiZKu0GnknQKzPedvhbWjDX9g2OG4/rGPvb
YdcFLG+/DqBHxsLiPxrbHCICrbkJU2zGi7g/dlIz28wAQU5NRrwAAAAGAAAAAAAKAAAVAAC0AAAA
VlA4TKMAAAAvCkAFEG+gJJIV6oH6SiwVyEEGEqNJp6iRJDW7DPe6rINjC6c2kq3kRwKkTgdkdE8h
1OI28x8AEBWHfSyI+halVCTymhtVfm0P6BYMF+8ZXMW2rTarzCClEpjRQw1UBP9FQiSUQUJ1JamG
iP6rbduG4ZieNwBNrcjmr+eaCzLMigHrHSXh7pcu1cId31i4GDlnI5NY2wQxg2KQZasNAAAg8XMK
AEFOTUYqAAAACwAAAQAAAQAAAQAAtAAAAFZQOEwSAAAALwFAABAPMGzzHvMfOEYgov8hQU5NRsQA
AAABAAAAAAAVAAAUAAC0AAAAVlA4TKwAAAAvFQAFEG+gNAAIBm1F1Tfzdc15itpIgcPLzZOsCxwg
ATWRbDW/CuRY0VEiA9VYQAJa4sx/AICxtPzIEc5mVKKb/8kvy10yu7XhymFUcBvbtqos3CWmBY+I
f0aqEVVoAQ4pLdu7QwkR/Vfbtg0jp2dKzgAAMNENmMak5XzTDTbkEjtWu14/nj2/IaFfbeWC0AvG
22LArB6wfns6XqcHP92CPqumjRMAAP54YTMAQU5NRloBAAAAAAAAAAAXAAAZAAC0AAAAVlA4TEIB
AAAvF0AGEIegJpKt5v8uARVDl7VEDQjEC1ZQpDiSlDjODfqyiMDbFFQb2zb0P7J9i2RkytCebkRa
0cgezX8AAJOxqwy2zyQXo6C3tJ5d7PwPzgFfpm7V5uG5xpAEaOAwsq2qOcDz88gzSf/d4rugJUT0
X4HbNsqOBx3dKwAAAAAAAAAAAIBSSnk5KwDw5vH23OrD9U5HLCzMypITESWi1lqrHEX4/8DS3tp5
yxbb3/4GJjG4Z9yIng3ZIsEL+P34lIh/hiecdnrGEBlEYs7AyjrbHEIQ7r13CexsI77FTFjjNpNL
gbDexWjo3fDqJCbg3mmttUaePssnMKmm+1iajzm42b7vO2Lu+PCabHdjP4BxkYh9qlfa8j/EwUNr
J1BhPv0C4UYG8IC4T3Eoc+7dV+ZxHIeu5VWw9v12letFPUdrFjcAQU5NRoAAAAABAAABAAAVAAAV
AAC0AAAAVlA4TGcAAAAvFUAFEDegEJIV6gF8cwoif45A1LRtBHV6xzI8EoefQMPiObRRXhoRzOY/
AHBK3v/c1dKmAVaRJLVq4jcSkIAE/PtKLwiI6D/ZAEVT2JxRAQAAAAAAAAAAANBpz8e52igAAH55
RdgAAA==
""")

ANIM_FEATHER = base64.decode("""
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
""")

ANIM_NONE = base64.decode("""
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
ANBpz8e52igAAH55RdgAAA==
""")

ASSETS = {
    "both": ANIM_BOTH,
    "pilgrim": ANIM_PILGRIM,
    "feather": ANIM_FEATHER,
    "none": ANIM_NONE,
}

# The turkey scene owns x=0..25; the countdown panel starts after a 1px gap.
PANEL_X = 27
PANEL_W = 64 - PANEL_X

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
    if len(destination) > 20:
        destination = destination[:20]

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
                render.Text("DAY!", font = "tom-thumb", color = "#ffcc80"),
            ],
        )
        badge_text = "ARRIVED!"
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
        delay = 120,
        child = render.Stack(
            children = [
                # Background animated turkey, foliage, and ribbon
                render.Image(src = turkey_asset, width = 64, height = 32),

                # Right column for countdown information. It sits between the
                # bead ribbon (y=0) and the soil strip (y=29..31) baked into
                # the art, so the text and the turkey share one scene.
                render.Padding(
                    pad = (PANEL_X, 2, 0, 3),
                    child = render.Column(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            # Top destination / trip title; scrolls when too long
                            render.Marquee(
                                width = PANEL_W,
                                align = "center",
                                child = render.Text(header_text, font = "tom-thumb", color = "#ffcc80"),
                            ),

                            # Center countdown / milestone display
                            center_widget,

                            # Bottom date / status badge
                            render.Box(
                                color = "#8d2b0b",
                                width = PANEL_W,
                                height = 7,
                                child = render.Padding(
                                    pad = (0, 1, 0, 0),
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
