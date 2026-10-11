// Renders scene.js into:
//   snowbyt.webp  - 64x32 animated WebP for the Tidbyt
//   preview.webp  - 8x LED-matrix mockup for looking at on a monitor
//   snowbyt.star  - Pixlet app with the WebP embedded as base64
// Usage: node build.js
import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { renderFrame, W, H } from "./scene.js";

const FRAMES = 120;
const FRAME_MS = 60; // 120 x 60ms = 7.2s seamless loop
const SCALE = 8;

const frames = Array.from({ length: FRAMES }, (_, i) => renderFrame(i / FRAMES));

function encode(raw, w, h, out, extra) {
  const r = spawnSync(
    "ffmpeg",
    ["-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", `${w}x${h}`,
     "-framerate", `${1000}/${FRAME_MS}`, "-i", "-",
     "-c:v", "libwebp_anim", "-loop", "0", ...extra, out],
    { input: raw, maxBuffer: 1 << 30 },
  );
  if (r.status !== 0) throw new Error(r.stderr.toString());
}

encode(Buffer.concat(frames.map((f) => Buffer.from(f.buffer))), W, H, "snowbyt.webp", ["-lossless", "1", "-compression_level", "6"]);

// LED mockup: each pixel becomes a round dot on a black panel.
const PW = W * SCALE, PH = H * SCALE;
const preview = frames.map((f) => {
  const out = Buffer.alloc(PW * PH * 4);
  for (let y = 0; y < PH; y++) {
    for (let x = 0; x < PW; x++) {
      const sx = Math.floor(x / SCALE), sy = Math.floor(y / SCALE);
      const d = Math.hypot((x % SCALE) - SCALE / 2 + 0.5, (y % SCALE) - SCALE / 2 + 0.5);
      const k = Math.max(0, Math.min(1, SCALE * 0.42 - d));
      const s = (sy * W + sx) * 4, o = (y * PW + x) * 4;
      out[o] = f[s] * k; out[o + 1] = f[s + 1] * k; out[o + 2] = f[s + 2] * k; out[o + 3] = 255;
    }
  }
  return out;
});
encode(Buffer.concat(preview), PW, PH, "preview.webp", ["-quality", "90"]);

const b64 = readFileSync("snowbyt.webp").toString("base64").match(/.{1,76}/g).join("\n");
writeFileSync("snowbyt.star", `"""SnowByt - a swirling snowstorm over a cozy cottage (64x32).

The animation is drawn entirely in JavaScript (scene.js) and rendered to an
animated WebP by build.js, embedded below. Regenerate with: node build.js
"""

load("encoding/base64.star", "base64")
load("render.star", "render")

SNOW_WEBP = base64.decode("""
${b64}
""")

def main():
    return render.Root(
        delay = ${FRAME_MS},
        child = render.Image(src = SNOW_WEBP, width = 64, height = 32),
    )
`);

console.log(`${FRAMES} frames @ ${FRAME_MS}ms, snowbyt.webp = ${readFileSync("snowbyt.webp").length} bytes`);
