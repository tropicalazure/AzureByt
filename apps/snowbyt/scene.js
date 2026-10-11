// SnowByt scene: a swirling snowstorm over a cozy cottage, 64x32.
// Pure JavaScript, no dependencies. renderFrame(t) takes t in [0, 1) (one full
// loop) and returns RGBA bytes. Every moving thing is a closed-form periodic
// function of t, so frame N+1 == frame 0 and the loop is seamless.

export const W = 64;
export const H = 32;

const TAU = Math.PI * 2;
const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
const mod = (a, n) => ((a % n) + n) % n;
const mix = (a, b, k) => a + (b - a) * k;
const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);

// Deterministic PRNG so every build produces the identical animation.
function rng(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let r = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    r = (r + Math.imul(r ^ (r >>> 7), 61 | r)) ^ r;
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

// ---------------------------------------------------------------- canvas ---

class Canvas {
  constructor() {
    this.buf = new Float32Array(W * H * 3);
  }
  blend(x, y, c, a = 1) {
    x |= 0; y |= 0;
    if (x < 0 || y < 0 || x >= W || y >= H || a <= 0) return;
    const i = (y * W + x) * 3;
    a = Math.min(a, 1);
    this.buf[i] = mix(this.buf[i], c[0], a);
    this.buf[i + 1] = mix(this.buf[i + 1], c[1], a);
    this.buf[i + 2] = mix(this.buf[i + 2], c[2], a);
  }
  add(x, y, c, a) {
    x |= 0; y |= 0;
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    const i = (y * W + x) * 3;
    this.buf[i] += c[0] * a;
    this.buf[i + 1] += c[1] * a;
    this.buf[i + 2] += c[2] * a;
  }
  rect(x, y, w, h, c, a = 1) {
    for (let j = y; j < y + h; j++) for (let i = x; i < x + w; i++) this.blend(i, j, c, a);
  }
  // Sub-pixel point: spreads alpha over the 4 nearest pixels so slow flakes
  // glide smoothly instead of hopping a whole LED at a time.
  splat(x, y, c, a) {
    const x0 = Math.floor(x), y0 = Math.floor(y);
    const fx = x - x0, fy = y - y0;
    const w = [(1 - fx) * (1 - fy), fx * (1 - fy), (1 - fx) * fy, fx * fy].map((v) => v ** 0.6);
    const n = Math.max(...w);
    this.blend(x0, y0, c, (a * w[0]) / n);
    this.blend(x0 + 1, y0, c, (a * w[1] * 0.6) / n);
    this.blend(x0, y0 + 1, c, (a * w[2] * 0.6) / n);
    this.blend(x0 + 1, y0 + 1, c, (a * w[3] * 0.6) / n);
  }
  disc(cx, cy, r, c, a, additive = false) {
    for (let y = Math.floor(cy - r - 1); y <= cy + r + 1; y++) {
      for (let x = Math.floor(cx - r - 1); x <= cx + r + 1; x++) {
        const d = Math.hypot(x + 0.5 - cx, y + 0.5 - cy);
        const k = clamp(r + 0.5 - d, 0, 1);
        if (k <= 0) continue;
        additive ? this.add(x, y, c, a * k) : this.blend(x, y, c, a * k);
      }
    }
  }
  glow(cx, cy, r, c, a) {
    for (let y = Math.floor(cy - r); y <= cy + r; y++) {
      for (let x = Math.floor(cx - r); x <= cx + r; x++) {
        const d = Math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.4) / r;
        if (d < 1) this.add(x, y, c, a * (1 - d) * (1 - d));
      }
    }
  }
  toRGBA() {
    const out = new Uint8ClampedArray(W * H * 4);
    for (let p = 0; p < W * H; p++) {
      out[p * 4] = this.buf[p * 3] * 255;
      out[p * 4 + 1] = this.buf[p * 3 + 1] * 255;
      out[p * 4 + 2] = this.buf[p * 3 + 2] * 255;
      out[p * 4 + 3] = 255;
    }
    return out;
  }
}

// ---------------------------------------------------------------- palette ---

const C = {
  skyTop: hex("#03061a"),
  skyLow: hex("#1d2b5c"),
  moon: hex("#dfe8ff"),
  hillFar: hex("#2b3a6e"),
  hillNear: hex("#4a5d96"),
  pine: hex("#1d5444"),
  pineSnow: hex("#d4e0ff"),
  snow: hex("#c9d6f5"),
  snowShade: hex("#8c9fd6"),
  wall: hex("#5b3420"),
  wallLine: hex("#3a1f12"),
  roof: hex("#6e2318"),
  roofSnow: hex("#eef3ff"),
  chimney: hex("#6b4a44"),
  door: hex("#2f170c"),
  knob: hex("#ffd27a"),
  window: hex("#ffb648"),
  windowHot: hex("#fff0b8"),
  frame: hex("#2a1308"),
  warm: hex("#ff9a3c"),
  smoke: hex("#b4bcd6"),
  flake: hex("#ffffff"),
  wreath: hex("#1f6a32"),
  berry: hex("#ff3b3b"),
};

// ---------------------------------------------------------- static layers ---

function groundY(x) {
  return 26.5 + Math.sin(x * 0.19) * 0.9 + Math.sin(x * 0.07 + 1.3) * 0.8;
}

function drawSky(cv) {
  for (let y = 0; y < H; y++) {
    const k = clamp(y / 24, 0, 1);
    const c = [0, 1, 2].map((i) => mix(C.skyTop[i], C.skyLow[i], k * k));
    for (let x = 0; x < W; x++) cv.blend(x, y, c);
  }
  // A moon smothered by storm cloud: soft halo plus a dim disc.
  cv.glow(53, 6, 8, hex("#5a6aa8"), 0.3);
  cv.disc(53, 6, 1.8, C.moon, 0.55);
}

function drawHills(cv) {
  for (let x = 0; x < W; x++) {
    const far = 20.5 + Math.sin(x * 0.11 + 0.5) * 1.6 + Math.sin(x * 0.29) * 0.5;
    for (let y = Math.floor(far); y < H; y++) cv.blend(x, y, C.hillFar, y === Math.floor(far) ? 0.6 : 1);
    const near = 23.5 + Math.sin(x * 0.08 + 2.2) * 1.4;
    for (let y = Math.floor(near); y < H; y++) cv.blend(x, y, C.hillNear, y === Math.floor(near) ? 0.7 : 1);
  }
}

function drawPine(cv, cx, baseY, h, sway) {
  // Trunk
  cv.rect(cx, baseY - 1, 1, 2, C.wallLine);
  for (let j = 0; j < h; j++) {
    const y = baseY - 1 - j;
    const tier = j % 4;
    const half = ((h - j) / h) * (h * 0.32) + (tier === 0 ? 0.6 : 0) - tier * 0.25;
    const shift = sway * (j / h);
    for (let x = Math.round(cx - half + shift); x <= Math.round(cx + half + shift); x++) {
      cv.blend(x, y, C.pine);
    }
    // Snow resting on the top of each tier
    if (tier === 3 || j === h - 1) {
      for (let x = Math.round(cx - half + shift); x <= Math.round(cx + half + shift); x++) {
        cv.blend(x, y, C.pineSnow, 0.85);
      }
    }
  }
}

function drawGround(cv, t) {
  for (let x = 0; x < W; x++) {
    const g = groundY(x);
    for (let y = Math.floor(g); y < H; y++) {
      // Rolling drift ridges: brighter on their crests, blue in the troughs.
      const ridge = Math.sin(x * 0.33 + y * 1.1) * 0.5 + Math.sin(x * 0.12 - y * 0.7 + 2) * 0.5;
      let shade = clamp((y - g) / 7 + ridge * 0.25 + 0.15, 0, 1);
      // Trodden path from the door curving down-left out of frame.
      const pathX = 24 - (y - 27) * 1.6;
      if (Math.abs(x - pathX) < 1.6 - (y - 27) * -0.2) shade = Math.min(1, shade + 0.45);
      const c = [0, 1, 2].map((i) => mix(C.snow[i], C.snowShade[i], shade * 0.8));
      cv.blend(x, y, c, y === Math.floor(g) ? 1 - (g - Math.floor(g)) : 1);
    }
  }
  // Drifts banked up against the cottage walls.
  for (const [cx, w] of [[14, 3], [35, 4]]) {
    for (let x = cx - w; x <= cx + w; x++) {
      const top = 25.2 + Math.abs(x - cx) * 0.55;
      for (let y = Math.floor(top); y < 28; y++) cv.blend(x, y, C.snow, y === Math.floor(top) ? 0.6 : 1);
    }
  }
  // Ice-crystal sparkles that wink on and off.
  const r = rng(7);
  for (let i = 0; i < 10; i++) {
    const x = Math.floor(r() * W), y = 27 + Math.floor(r() * 5);
    const k = Math.sin(TAU * ((1 + Math.floor(r() * 3)) * t + r()));
    if (k > 0.75) cv.blend(x, y, C.flake, (k - 0.75) * 4);
  }
}

// Sheets of wind-driven snow sweeping across the whole scene, strongest when
// the gust peaks.
function drawVeil(cv, t) {
  const strength = 0.5 + 0.5 * Math.sin(TAU * t - 0.6);
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const v =
        Math.sin(x * 0.22 - y * 0.45 - TAU * 4 * t) * 0.6 +
        Math.sin(x * 0.09 + y * 0.31 - TAU * 3 * t + 1.7) * 0.4;
      if (v > 0.25) cv.add(x, y, C.flake, (v - 0.25) * 0.11 * (0.35 + strength));
    }
  }
}

function drawCottage(cv, t) {
  const L = 14, R = 34, TOP = 18, BOT = 27;

  // Chimney (behind the roof line)
  cv.rect(28, 9, 3, 7, C.chimney);
  cv.rect(28, 11, 3, 1, hex("#4d3430"));
  cv.rect(28, 14, 3, 1, hex("#4d3430"));
  cv.rect(27, 8, 5, 1, C.roofSnow);

  // Log walls
  cv.rect(L, TOP, R - L + 1, BOT - TOP, C.wall);
  for (let y = TOP + 1; y < BOT; y += 2) cv.rect(L, y, R - L + 1, 1, C.wallLine, 0.55);

  // Roof: triangle with a thick snow blanket and drooping eaves
  const apexX = 24, apexY = 9;
  for (let y = apexY; y <= TOP; y++) {
    const half = ((y - apexY) / (TOP - apexY)) * 13.5;
    for (let x = Math.round(apexX - half); x <= Math.round(apexX + half); x++) {
      const edge = Math.min(x - (apexX - half), apexX + half - x);
      // Thick snow blanket over the upper roof with a lumpy lower edge;
      // shingles peek out underneath, with a crisp snowy rim on the gables.
      const blanket = apexY + 5.5 + Math.sin(x * 1.3) * 0.8 + Math.sin(x * 0.55 + 1) * 0.6;
      if (y < blanket) {
        const shade = (x - apexX) / 14; // moonlit left, shadowed right
        cv.blend(x, y, C.roofSnow.map((v, i) => v - Math.max(0, shade) * 0.18 * (i === 2 ? 0.3 : 1)));
      } else if (edge < 1) {
        cv.blend(x, y, C.roofSnow);
      } else {
        cv.blend(x, y, (y - apexY) % 2 ? C.roof : C.roof.map((v) => v * 0.78));
      }
    }
  }
  // Snowy eave lip and icicles
  for (let x = 10; x <= 38; x++) cv.blend(x, TOP, C.roofSnow);
  for (const [x, len] of [[12, 2], [15, 1], [19, 2], [29, 1], [33, 2], [36, 1]]) {
    for (let j = 1; j <= len; j++) cv.blend(x, TOP + j, hex("#cfe6ff"), 0.9 - j * 0.25);
  }

  // Windows with a firelight flicker (integer frequencies keep the loop exact)
  const flick =
    0.82 + 0.1 * Math.sin(TAU * 5 * t) + 0.06 * Math.sin(TAU * 13 * t + 1.1) + 0.04 * Math.sin(TAU * 29 * t + 2.3);
  for (const wx of [16, 29]) {
    for (let y = 20; y < 24; y++) {
      for (let x = wx; x < wx + 4; x++) {
        const hot = 1 - Math.hypot(x - (wx + 1.5), y - 22.5) / 3;
        const c = [0, 1, 2].map((i) => mix(C.window[i], C.windowHot[i], clamp(hot, 0, 1) * 0.6));
        cv.blend(x, y, c.map((v) => v * flick));
      }
    }
    cv.rect(wx + 1, 20, 1, 4, C.frame, 0.85);
    cv.rect(wx, 21, 4, 1, C.frame, 0.85);
    cv.rect(wx - 1, 24, 6, 1, C.roofSnow, 0.9); // snow on the sill
  }

  // Door with a little wreath
  cv.rect(22, 21, 4, BOT - 21, C.door);
  cv.blend(25, 24, C.knob);
  cv.disc(23.5, 22.5, 1.1, C.wreath, 1);
  cv.blend(23, 22, C.door);
  cv.blend(24, 23, C.berry);

  return flick;
}

function drawWarmSpill(cv, flick) {
  // Firelight pooling on the snow and haloing the windows.
  for (const wx of [18, 31]) {
    cv.glow(wx, 22, 7, C.warm, 0.22 * flick);
    cv.glow(wx, 29, 8, C.warm, 0.3 * flick);
  }
  cv.glow(24, 29, 4, C.warm, 0.12 * flick);
}

// --------------------------------------------------------------- dynamics ---

// Storm wind: a steady push to the right plus a gust that swells and fades
// once per loop. Gust is an x *offset*, so it stays periodic.
const gust = (t) => Math.sin(TAU * t) * 6 + Math.sin(TAU * 2 * t + 0.7) * 2;

function drawSmoke(cv, t) {
  const N = 7;
  for (let i = 0; i < N; i++) {
    const a = mod(i / N + t * 2, 1); // age 0..1, two full cycles per loop
    const x = 29.5 + a * a * 16 + Math.sin(TAU * (a * 1.5 + i * 0.37)) * 1.2 + gust(t) * a * 0.25;
    const y = 7 - a * 9;
    const r = 0.6 + a * 2.2;
    cv.disc(x, y, r, C.smoke, 0.5 * (1 - a) * clamp(a * 6, 0, 1));
  }
}

function makeFlakes(seed, n, opts) {
  const r = rng(seed);
  return Array.from({ length: n }, () => ({
    x0: r() * 72,
    y0: r() * 38,
    fall: opts.fall[0] + Math.floor(r() * (opts.fall[1] - opts.fall[0] + 1)), // laps per loop (integer)
    drift: opts.drift[0] + Math.floor(r() * (opts.drift[1] - opts.drift[0] + 1)),
    swirlA: opts.swirl * (0.6 + r() * 0.8),
    swirlF: 1 + Math.floor(r() * 3),
    ph: r() * TAU,
    bright: opts.bright[0] + r() * (opts.bright[1] - opts.bright[0]),
    big: r() < (opts.bigChance || 0),
  }));
}

const FAR = makeFlakes(11, 90, { fall: [1, 2], drift: [1, 1], swirl: 1.5, bright: [0.35, 0.55] });
const MID = makeFlakes(23, 70, { fall: [2, 3], drift: [1, 2], swirl: 3, bright: [0.75, 0.95] });
const NEAR = makeFlakes(37, 34, { fall: [3, 4], drift: [2, 3], swirl: 4.5, bright: [1, 1], bigChance: 0.35 });

function flakePos(f, t, gustK) {
  const yy = f.y0 + f.fall * 38 * t;
  const y = mod(yy, 38) - 3;
  // The swirl depends on height *and* time, so flakes curl through little
  // vortices on the way down instead of sliding in straight lines.
  const sx = f.swirlA * Math.sin(TAU * (f.swirlF * t) + y * 0.35 + f.ph);
  const sy = f.swirlA * 0.45 * Math.cos(TAU * (f.swirlF * t) + y * 0.35 + f.ph);
  const x = mod(f.x0 + f.drift * 72 * t + sx + gust(t) * gustK, 72) - 4;
  return [x, y + sy];
}

function drawFlakes(cv, flakes, t, gustK) {
  for (const f of flakes) {
    const [x, y] = flakePos(f, t, gustK);
    if (f.big) {
      cv.disc(x, y, 0.75, C.flake, f.bright);
    } else {
      cv.splat(x, y, C.flake, f.bright);
    }
  }
}

// Spindrift: wisps of snow skating along the ground in the wind.
function drawSpindrift(cv, t) {
  const r = rng(91);
  for (let i = 0; i < 9; i++) {
    const baseY = 26 + r() * 5;
    const x0 = r() * 80;
    const laps = 2 + Math.floor(r() * 2);
    const head = mod(x0 + laps * 80 * t, 80) - 8;
    const len = 4 + r() * 5;
    for (let k = 0; k < len; k++) {
      const x = head - k;
      const y = baseY - Math.sin((k / len) * Math.PI) * 0.8 + Math.sin(TAU * t * 3 + i) * 0.4;
      cv.splat(x, y, C.flake, 0.35 * (1 - k / len));
    }
  }
}

// ---------------------------------------------------------------- compose ---

export function renderFrame(t) {
  const cv = new Canvas();
  drawSky(cv);
  drawFlakes(cv, FAR, t, 0.4);
  drawHills(cv);
  const sway = Math.sin(TAU * t) * 0.6;
  drawPine(cv, 4, 25, 12, sway);
  drawPine(cv, 9, 26, 8, sway * 0.8);
  drawPine(cv, 44, 26, 9, sway * 0.8);
  drawPine(cv, 51, 26, 15, sway);
  drawPine(cv, 59, 26, 10, sway * 0.9);
  drawGround(cv, t);
  drawSmoke(cv, t);
  const flick = drawCottage(cv, t);
  drawWarmSpill(cv, flick);
  drawSpindrift(cv, t);
  drawFlakes(cv, MID, t, 0.7);
  drawFlakes(cv, NEAR, t, 1);
  drawVeil(cv, t);
  return cv.toRGBA();
}
