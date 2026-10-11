#!/usr/bin/env python3
"""Embed out/dolphin.webp into dolphinbyt.star as a self-contained Tidbyt app."""
import base64
import os
import textwrap

ROOT = os.path.dirname(__file__)

# Pull the frame duration from generate.py so the .star playback speed stays in
# sync with the art. render.Root(delay=...) governs Tidbyt playback - the
# WebP's own per-frame durations are ignored by render.Image.
import generate  # noqa: E402

FRAME_MS = generate.FRAME_MS

webp = open(os.path.join(ROOT, "out", "dolphin.webp"), "rb").read()
b64 = base64.b64encode(webp).decode()
wrapped = "\n".join(textwrap.wrap(b64, 76))

star = '''\
"""DolphinByt - a bright pink dolphin arcing through the deep (64x32).

Self-contained: the animated WebP produced by generate.py is embedded below as
base64, so no network call is needed. render.Image plays animated WebP natively.
"""

load("render.star", "render")
load("encoding/base64.star", "base64")

DOLPHIN_WEBP = base64.decode(\"\"\"
{b64}
\"\"\")

def main(config):
    return render.Root(
        delay = {delay},  # ms per frame - controls playback speed on the Tidbyt
        child = render.Image(src = DOLPHIN_WEBP, width = 64, height = 32),
    )
'''.format(b64=wrapped, delay=FRAME_MS)

out = os.path.join(ROOT, "dolphinbyt.star")
open(out, "w", newline="\n").write(star)
print("Wrote dolphinbyt.star ({} bytes embedded, {} b64 chars)".format(len(webp), len(b64)))
