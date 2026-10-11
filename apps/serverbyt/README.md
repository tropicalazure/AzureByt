# ServerByt - home server health, on your Tidbyt

Shows live health for `aura`, the Acer laptop running your Tronbyt server, right on
the physical display: CPU, memory, disk, and CPU temperature, plus uptime. Calm
and green when everything's fine, color-coded and specific about what's wrong
when it's not.

## How it works

```
/proc, /sys (on aura)
        |
        v
exporter/health_exporter.py   <- systemd service "health-exporter", port 9101
        |
        |  GET /health  (JSON, no auth, LAN only)
        v
serverbyt.star                <- runs inside the tronbyt-server container
        |
        v
64x32 display on your Tidbyt/Tronbyt device
```

The exporter just reports raw numbers. All the "is this healthy" judgment -
thresholds, colors, the status message - lives in `serverbyt.star`, so you can
retune it any time without touching the server.

## Files

- `exporter/health_exporter.py` - stdlib-only Python HTTP server. No pip installs
  needed (Ubuntu 26.04 blocks casual `pip install` anyway). Reads `/proc/stat`,
  `/proc/meminfo`, `/proc/uptime`, and `/sys/class/thermal/*/temp` directly.
- `exporter/health-exporter.service` - systemd unit. Runs as `aura17dev`,
  restarts automatically if it ever crashes, and starts on boot.
- `serverbyt.star` - the Tidbyt/Pixlet app. Polls the exporter and renders the
  display.
- `manifest.yaml` - app metadata, same format as the other Byt apps in this
  workspace.

## Already deployed

The exporter is installed and running on `aura` right now:

- Files live at `/DATA/AppData/health-exporter/` on the server.
- Service: `sudo systemctl status health-exporter` (enabled + auto-restart).
- Firewall: port `9101/tcp` is allowed through `ufw` (same pattern as Home
  Assistant's 8123), so the Tronbyt container can reach it.
- Verify any time with: `curl http://192.168.50.190:9101/health`

If you ever need to redeploy after editing `health_exporter.py`:

```bash
scp exporter/health_exporter.py aura:/DATA/AppData/health-exporter/health_exporter.py
ssh aura "sudo systemctl restart health-exporter"
```

## Adding the app to Tronbyt

1. Preview locally first (no server round-trip needed):
   ```bash
   pixlet render serverbyt.star -o preview.webp   # one-shot render
   pixlet serve serverbyt.star                    # live-reloading local preview server
   ```
2. Once you're happy with it, open `http://192.168.50.190:8000`, log in, and add
   `serverbyt.star` as a Custom App. Set its refresh interval to a few minutes -
   the app itself caches the exporter response for 60 seconds either way.
3. Watch it show up on the physical display.

## Tuning thresholds

Open `serverbyt.star` and edit the `THRESHOLDS` dict near the top:

```python
THRESHOLDS = {
    "cpu_percent": (70, 90),    # (warn_at, crit_at)
    "mem_percent": (75, 90),
    "disk_percent": (80, 92),
    "cpu_temp_f": (167, 190),
}
```

These are deliberately calibrated for this specific old laptop chip, not
generic server numbers - old mobile CPUs routinely idle in the 160s-190s F
under load without any damage, so a lower critical threshold would just cause
constant false alarms. Adjust freely if you find your own comfort zone. (The
exporter itself still reports Celsius over the wire - `serverbyt.star`
converts to Fahrenheit for display.)

The display name shown in the status message ("server: all systems nominal")
is the `DISPLAY_NAME` constant near the top of `serverbyt.star`, not the
machine's actual hostname - change it there if you'd rather it say something
else.

## Known limitation: total exporter outages

Pixlet's Starlark has no try/except (confirmed against the installed Pixlet
v0.33.3 - there's no `catch()` builtin either). That means if the exporter is
*completely* unreachable (not just erroring, but connection-refused or
timed-out), the script raises a hard error instead of falling back to a "no
signal" message. In practice this only matters for the few seconds between a
crash and systemd's automatic restart (`RestartSec=5`) - Tronbyt will simply
keep showing the last successfully rendered frame until the next successful
poll. Since the exporter runs on the same physical machine as Tronbyt itself,
there's no real scenario where Tronbyt is up but the whole host is down, so
this edge case is narrow by construction.

The one case this code *does* handle gracefully is an HTTP-level error (a
non-200 response) - that shows a distinct grey "no signal" screen instead of
a crash.
