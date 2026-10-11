#!/usr/bin/env python3
"""
health_exporter.py - minimal stdlib-only host health metrics HTTP server.

Exposes GET /health as JSON on 0.0.0.0:9101, e.g.:
  {
    "hostname": "aura",
    "cpu_percent": 12.3,
    "mem_percent": 41.0,
    "disk_percent": 6.2,
    "cpu_temp_c": 58.0,
    "uptime_seconds": 123456.7,
    "load_avg": [0.12, 0.20, 0.18],
    "updated_at": 1751500000.0
  }

A background thread recomputes cpu_percent (which needs two /proc/stat
samples a bit apart) every REFRESH_SECONDS and stores results in a shared
cache dict. The HTTP handler only ever reads the cache, so requests stay
fast no matter how often the Tidbyt/Tronbyt app polls us.

No third-party dependencies. No auth - intended for LAN-only use.
"""

import glob
import http.server
import json
import os
import shutil
import socket
import threading
import time

PORT = 9101
BIND_ADDR = "0.0.0.0"
REFRESH_SECONDS = 2.0

_cache_lock = threading.Lock()
_cache = {}


def _read_proc_stat_total_idle():
    """Return (total, idle) jiffies summed across all CPUs from /proc/stat."""
    with open("/proc/stat") as f:
        line = f.readline()  # first line: aggregate "cpu  ..." across all cores
    values = [int(p) for p in line.split()[1:]]
    idle = values[3] + values[4]  # idle + iowait
    total = sum(values)
    return total, idle


def _find_cpu_temp_path():
    """Locate the thermal zone whose 'type' is x86_pkg_temp; fall back to None."""
    for type_path in glob.glob("/sys/class/thermal/thermal_zone*/type"):
        try:
            with open(type_path) as f:
                if f.read().strip() == "x86_pkg_temp":
                    return type_path.replace("/type", "/temp")
        except OSError:
            continue
    return None


def _read_cpu_temp_c(temp_path):
    if not temp_path:
        return None
    try:
        with open(temp_path) as f:
            millidegrees = int(f.read().strip())
        return round(millidegrees / 1000.0, 1)
    except (OSError, ValueError):
        return None


def _read_mem_percent():
    meminfo = {}
    with open("/proc/meminfo") as f:
        for line in f:
            key, _, rest = line.partition(":")
            meminfo[key] = int(rest.strip().split()[0])  # kB
    total = meminfo["MemTotal"]
    available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
    used_percent = 100.0 * (1 - (available / total))
    return round(used_percent, 1)


def _read_disk_percent(path="/"):
    usage = shutil.disk_usage(path)
    return round(100.0 * usage.used / usage.total, 1)


def _read_uptime_seconds():
    with open("/proc/uptime") as f:
        return float(f.read().split()[0])


def _snapshot(cpu_percent, temp_path):
    return {
        "hostname": socket.gethostname(),
        "cpu_percent": cpu_percent,
        "mem_percent": _read_mem_percent(),
        "disk_percent": _read_disk_percent("/"),
        "cpu_temp_c": _read_cpu_temp_c(temp_path),
        "uptime_seconds": _read_uptime_seconds(),
        "load_avg": list(os.getloadavg()),
        "updated_at": time.time(),
    }


def _updater_loop(temp_path, prev_total, prev_idle):
    """Background thread: refresh the metrics cache every REFRESH_SECONDS."""
    while True:
        time.sleep(REFRESH_SECONDS)
        total, idle = _read_proc_stat_total_idle()
        d_total = total - prev_total
        d_idle = idle - prev_idle
        cpu_percent = round(100.0 * (1 - d_idle / d_total), 1) if d_total > 0 else 0.0
        prev_total, prev_idle = total, idle

        with _cache_lock:
            _cache.update(_snapshot(cpu_percent, temp_path))


class HealthHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # keep the systemd journal quiet

    def do_GET(self):
        if self.path != "/health":
            self.send_response(404)
            self.end_headers()
            return
        with _cache_lock:
            body = json.dumps(_cache).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    temp_path = _find_cpu_temp_path()

    # Populate the cache once, synchronously, before serving traffic,
    # so the first request doesn't see an empty payload.
    prev_total, prev_idle = _read_proc_stat_total_idle()
    with _cache_lock:
        _cache.update(_snapshot(0.0, temp_path))

    updater = threading.Thread(
        target=_updater_loop, args=(temp_path, prev_total, prev_idle), daemon=True
    )
    updater.start()

    server = http.server.ThreadingHTTPServer((BIND_ADDR, PORT), HealthHandler)
    print(f"health_exporter listening on {BIND_ADDR}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
