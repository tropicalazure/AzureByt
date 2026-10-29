// FlamingoByt scene: a flamingo in sunglasses dancing on a rainbow under a
// disco ball, with two backup dancers, 64x32.
// Pure JavaScript, no dependencies. renderFrame(t) takes t in [0, 1) (one full
// loop) and returns RGBA bytes. Every moving thing is a periodic function of t
// (integer beat counts), so the loop is seamless.

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

// Thick anti-aliased line: stamps soft discs along the segment.
function stroke(cv, x1, y1, x2, y2, r, c, a = 1) {
  const n = Math.max(1, Math.ceil(Math.hypot(x2 - x1, y2 - y1) * 2));
  for (let i = 0; i <= n; i++) cv.disc(mix(x1, x2, i / n), mix(y1, y2, i / n), r, c, a);
}

function ellipse(cv, cx, cy, rx, ry, rot, c, a = 1) {
  const cs = Math.cos(rot), sn = Math.sin(rot);
  for (let y = Math.floor(cy - rx - 1); y <= cy + rx + 1; y++) {
    for (let x = Math.floor(cx - rx - 1); x <= cx + rx + 1; x++) {
      const dx = x + 0.5 - cx, dy = y + 0.5 - cy;
      const u = (dx * cs + dy * sn) / rx, v = (-dx * sn + dy * cs) / ry;
      const k = clamp((1 - Math.hypot(u, v)) * Math.min(rx, ry) + 0.5, 0, 1);
      if (k > 0) cv.blend(x, y, c, a * k);
    }
  }
}

function hsv(h, s, v) {
  h = mod(h, 1) * 6;
  const f = h - Math.floor(h), p = v * (1 - s), q = v * (1 - s * f), u = v * (1 - s * (1 - f));
  return [[v, u, p], [q, v, p], [p, v, u], [p, q, v], [u, p, v], [v, p, q]][Math.floor(h) % 6];
}

const smooth = (k) => k * k * (3 - 2 * k);

// ---------------------------------------------------------------- palette ---

const C = {
  skyTop: hex("#12042e"),
  skyMid: hex("#4a1580"),
  skyLow: hex("#8a2f8f"),
  star: hex("#fff6d8"),
  cloud: hex("#ffe3f1"),
  cloudShade: hex("#c98bd6"),
  pink: hex("#ff6fae"),
  pinkDark: hex("#d93f86"),
  pinkLight: hex("#ffb3d4"),
  leg: hex("#ff8fbf"),
  beak: hex("#ffe0ec"),
  black: hex("#160a14"),
  white: hex("#ffffff"),
  shades: hex("#05040c"),
  string: hex("#7a6d8c"),
  mirror: hex("#c8d2e8"),
};

// ------------------------------------------------------------------- beat ---

const BEATS = 8; // dance beats per loop
const beatOf = (t) => {
  const b = t * BEATS;
  return [Math.floor(b), b - Math.floor(b)]; // [beat index, phase 0..1]
};

// ------------------------------------------------------------- background ---

function drawSky(cv, t) {
  for (let y = 0; y < H; y++) {
    const k = y / (H - 1);
    const c = k < 0.55
      ? [0, 1, 2].map((i) => mix(C.skyTop[i], C.skyMid[i], smooth(k / 0.55)))
      : [0, 1, 2].map((i) => mix(C.skyMid[i], C.skyLow[i], smooth((k - 0.55) / 0.45)));
    for (let x = 0; x < W; x++) cv.blend(x, y, c);
  }
  const r = rng(5);
  for (let i = 0; i < 26; i++) {
    const x = Math.floor(r() * W), y = Math.floor(r() * 16);
    const tw = 0.5 + 0.5 * Math.sin(TAU * ((1 + Math.floor(r() * 3)) * t + r()));
    cv.blend(x, y, C.star, (0.25 + r() * 0.5) * tw);
  }
  // Shooting star streaks across once per loop.
  const s = mod(t * 1 - 0.15, 1);
  if (s < 0.18) {
    const p = s / 0.18;
    const hx = mix(70, 4, p), hy = mix(-1, 9, p);
    for (let k = 0; k < 7; k++) cv.splat(hx + k * 1.6, hy - k * 0.25, C.star, (1 - k / 7) * (1 - p * 0.5));
  }
}

function puff(cv, cx, cy, s, a = 1) {
  const blobs = [[-4, 0, 2.6], [-1.5, -1.6, 3], [2, -1, 2.7], [4.5, 0.4, 2.1], [0.5, 0.8, 2.6]];
  for (const [dx, dy, r] of blobs) cv.disc(cx + dx * s, cy + dy * s + 0.8, r * s, C.cloudShade, a);
  for (const [dx, dy, r] of blobs) cv.disc(cx + dx * s, cy + dy * s, r * s, C.cloud, a);
}

function drawDriftClouds(cv, t) {
  for (const [x0, y, s, laps] of [[0, 6, 0.55, 1], [40, 3, 0.45, 1], [22, 12, 0.5, 2]]) {
    const x = mod(x0 + laps * 84 * t, 84) - 10;
    puff(cv, x, y, s, 0.35);
  }
}

// ---------------------------------------------------------------- rainbow ---

const RB = { cx: 32, cy: 53, outer: 34, bands: 7, bw: 1.6 };
const arcTop = (x) => RB.cy - Math.sqrt(RB.outer ** 2 - (x - RB.cx) ** 2);

function drawRainbow(cv, t, stomp) {
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const dx = x + 0.5 - RB.cx, dy = y + 0.5 - RB.cy;
      const d = Math.hypot(dx, dy);
      const depth = RB.outer - d; // 0 at outer edge
      const span = RB.bands * RB.bw;
      if (depth < -0.5 || depth > span + 0.5) continue;
      const edge = clamp(Math.min(depth + 0.5, span + 0.5 - depth), 0, 1);
      // Colors flow outward through the bands: always a full spectrum,
      // rotating once per loop.
      const band = clamp(depth / RB.bw, 0, RB.bands - 0.001);
      const hue = band / RB.bands * 0.85 - t * 2;
      // Shimmer wave sliding along the arc, plus a ripple from each stomp.
      const ang = Math.atan2(dy, dx) + Math.PI / 2; // 0 at the apex
      let v = 0.78 + 0.14 * Math.sin(ang * 9 - TAU * 6 * t);
      const ring = Math.abs(ang) - stomp.age * 1.1;
      v += 0.5 * Math.exp(-(ring * ring) / 0.03) * (1 - stomp.age);
      cv.blend(x, y, hsv(hue, 0.8 - clamp(v - 1, 0, 0.5), clamp(v, 0, 1)), edge);
    }
  }
}

// --------------------------------------------------------------- flamingo ---

// Two-bone IK for a leg: returns the joint between hip and foot. Flamingo
// "knees" (really ankles) bend backward, i.e. toward -x.
function joint(hx, hy, fx, fy, l1, l2) {
  let dx = fx - hx, dy = fy - hy;
  const d = Math.hypot(dx, dy);
  const dm = Math.min(d, l1 + l2 - 0.01);
  const a = (l1 * l1 - l2 * l2 + dm * dm) / (2 * dm);
  const h = Math.sqrt(Math.max(0, l1 * l1 - a * a));
  dx /= d; dy /= d;
  const mx = hx + dx * a, my = hy + dy * a;
  const px = -dy, py = dx;
  const s = px < 0 ? 1 : -1; // pick the perpendicular that points backward
  return [mx + px * h * s, my + py * h * s];
}

// A dancer is drawn in its own local space (feet at y=0, facing +x) and
// mapped to the screen by origin, scale and facing direction, so the lead and
// the backup dancers share one skeleton.
function dancer(ox, s, dir) {
  const oy = arcTop(ox) - 0.5;
  return {
    s, dir,
    X: (x) => ox + dir * s * x,
    Y: (y) => oy + s * y,
    R: (r) => Math.max(0.33, r * s),
    ground: (lx) => (arcTop(ox + dir * s * lx) - 0.5 - oy) / s,
  };
}

function pose(t, D) {
  const [beat, p] = beatOf(t);
  const bob = 0.7 - 0.7 * Math.cos(TAU * 2 * p); // dips twice per beat
  const shimmy = Math.sin(TAU * (BEATS / 2) * t) * 1.2;
  const hip = [shimmy, -8.1 + bob];
  const k = Math.sin(Math.PI * p); // kick envelope for this beat
  const kicker = beat % 2; // legs take turns
  // Choreography: kicks, a classic one-leg tuck, then high kicks + wing flaps.
  let kickTo;
  if (beat < 4) kickTo = [hip[0] + 5.5, hip[1] + 3.5];
  else if (beat < 6) kickTo = [hip[0] - 1.5, hip[1] + 2];
  else kickTo = [hip[0] + 6.5, hip[1] + 1];
  const flap = beat >= 6 ? Math.abs(Math.sin(TAU * 2 * p)) : beat === 3 ? k : 0;
  const feet = [-2, 2].map((fx, i) => {
    const plant = [fx, D.ground(fx)];
    if (i !== kicker) return plant;
    return [mix(plant[0], kickTo[0], k), mix(plant[1], kickTo[1], k)];
  });
  const neckSway = Math.sin(TAU * BEATS * t + 0.6) * 1.6;
  const headBob = Math.cos(TAU * BEATS * 2 * t) * 0.5;
  return { beat, p, hip, feet, kicker, k, flap, neckSway, headBob };
}

function drawFlamingo(cv, P, D, glint) {
  const { X, Y, R } = D;
  const line = (x1, y1, x2, y2, r, c, a) => stroke(cv, X(x1), Y(y1), X(x2), Y(y2), R(r), c, a);
  const oval = (cx, cy, rx, ry, rot, c, a) => ellipse(cv, X(cx), Y(cy), rx * D.s, ry * D.s, rot * D.dir, c, a);
  const dot = (x, y, c, a = 1) => cv.blend(Math.floor(X(x)), Math.floor(Y(y)), c, a);
  const [hx, hy] = P.hip;

  // Legs (the far leg first, slightly darker)
  P.feet.forEach(([fx, fy], i) => {
    const [jx, jy] = joint(hx, hy, fx, fy, 5.1, 5.1);
    const c = i === 0 ? C.pinkDark : C.leg;
    line(hx, hy, jx, jy, 0.35, c);
    line(jx, jy, fx, fy, 0.35, c);
    cv.disc(X(jx), Y(jy), R(0.55), c, 1);
    line(fx - 0.5, fy, fx + 1.4, fy, 0.4, c); // webbed foot
  });

  // Body: plump tilted oval, tail feathers up at the back.
  const bx = hx - 0.6, by = hy - 1.9;
  oval(bx, by, 4.4, 2.1, -0.25, C.pink);
  oval(bx + 0.6, by + 0.9, 3.2, 1, -0.15, C.pinkDark, 0.45);
  line(bx - 3.8, by - 0.9, bx - 5.6, by - 2.3, 0.5, C.pinkDark);

  // Neck: an S-curve from the chest up to the head.
  const n0 = [hx + 2.8, hy - 3.2];
  const head = [hx + 3 + P.neckSway, hy - 8.6 + P.headBob];
  const c1 = [n0[0] + 4, n0[1] - 2.5];
  const c2 = [head[0] - 4.5, head[1] + 2];
  let prev = n0;
  for (let i = 1; i <= 14; i++) {
    const u = i / 14, w = 1 - u;
    const pt = [0, 1].map(
      (j) => w * w * w * n0[j] + 3 * w * w * u * c1[j] + 3 * w * u * u * c2[j] + u * u * u * head[j],
    );
    line(prev[0], prev[1], pt[0], pt[1], 0.5, C.pink);
    prev = pt;
  }

  // Head and the famous bent beak with its black tip.
  const [qx, qy] = head;
  cv.disc(X(qx), Y(qy), R(1.2), C.pink, 1);
  line(qx + 1, qy + 0.1, qx + 2.4, qy + 0.9, 0.45, C.beak);
  line(qx + 2.4, qy + 0.9, qx + 2.3, qy + 2.2, 0.45, C.black);

  // Sunglasses: a dark lens over the eye, an arm back over the head, and a
  // glint that flashes on the beat.
  line(qx - 0.6, qy - 0.9, qx - 1.4, qy - 1.1, 0.25, C.shades);
  line(qx - 0.3, qy - 0.5, qx + 1.1, qy - 0.5, 0.55, C.shades);
  dot(qx + 0.8, qy - 0.8, glint.c, glint.a);

  // Wing: folded on the body, or fanned up when flapping.
  if (P.flap > 0.05) {
    const sx = hx + 0.2, sy = hy - 2.8;
    for (let f = 0; f < 4; f++) {
      const ang = mix(Math.PI + 0.25, -2.0 - f * 0.28, P.flap);
      const len = 5.5 - f * 0.6;
      const ex = sx + Math.cos(ang) * len, ey = sy + Math.sin(ang) * len;
      line(sx, sy, ex, ey, 0.55, f === 0 ? C.pinkLight : C.pink);
      cv.disc(X(ex), Y(ey), R(0.5), C.black, 0.9);
    }
  } else {
    oval(bx - 0.2, by - 0.3, 2.8, 1.2, -0.2, C.pinkLight, 0.85);
    dot(bx - 2.8, by - 0.5, C.pinkDark, 0.9);
  }
}

// ------------------------------------------------------------- disco ball ---

const BALL = { x: 20, y: 4.6, r: 3.4 };

function drawDiscoBall(cv, t) {
  const { x: cx, y: cy, r } = BALL;
  stroke(cv, cx, -1, cx, cy - r + 0.5, 0.3, C.string);
  const spin = TAU * t * 2;
  const L = [-0.5, -0.6, 0.62]; // light from the upper left
  for (let y = Math.floor(cy - r); y <= cy + r; y++) {
    for (let x = Math.floor(cx - r); x <= cx + r; x++) {
      const nx = (x + 0.5 - cx) / r, ny = (y + 0.5 - cy) / r;
      const q = nx * nx + ny * ny;
      if (q > 1) continue;
      const nz = Math.sqrt(1 - q);
      // Mirror tiles: latitude/longitude grid that spins with the ball.
      const lon = Math.atan2(nx, nz) + spin, lat = Math.asin(ny);
      const fi = Math.floor(mod(lon, TAU) / (TAU / 14)), fj = Math.floor((lat + 1.6) / 0.4);
      const tile = rng(fi * 31 + fj * 7 + 1)();
      const diffuse = clamp(nx * L[0] + ny * L[1] + nz * L[2], 0, 1);
      // Each tile flashes when its facet sweeps past the light.
      const flash = Math.max(0, Math.sin(TAU * (tile + t * 4))) ** 6;
      const v = 0.25 + diffuse * 0.45 + tile * 0.15 + flash * 0.6;
      const c = flash > 0.5 ? hsv(tile + t, 0.35, 1) : C.mirror;
      cv.blend(x, y, c.map((u) => u * clamp(v, 0, 1.2)), clamp(1 - q, 0, 1) * 3);
    }
  }
  // Star glint that pops on every beat.
  const [, p] = beatOf(t);
  const g = (1 - p) ** 3;
  if (g > 0.05) {
    const gx = cx - 1.2, gy = cy - 1.4;
    cv.add(Math.floor(gx), Math.floor(gy), C.white, g);
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) cv.add(Math.floor(gx) + dx, Math.floor(gy) + dy, C.white, g * 0.5);
  }
}

// Light thrown by the ball: slowly rotating beams plus colored reflection
// spots sweeping across the whole scene.
function drawDiscoLights(cv, t) {
  for (let i = 0; i < 4; i++) {
    const ang = Math.PI * 0.5 + Math.sin(TAU * (t + i / 4)) * 1.1;
    const c = hsv(i / 4 + t, 0.6, 1);
    for (let d = BALL.r; d < 40; d += 0.5) {
      const x = BALL.x + Math.cos(ang) * d, y = BALL.y + Math.sin(ang) * d;
      cv.add(Math.floor(x), Math.floor(y), c, 0.07 * (1 - d / 40));
    }
  }
  const r = rng(77);
  for (let i = 0; i < 16; i++) {
    const x = mod(r() * 80 + (1 + Math.floor(r() * 2)) * 80 * t, 80) - 8;
    const y = r() * 30;
    cv.glow(x, y, 1.6, hsv(r() + t, 0.55, 1), 0.55);
  }
}

// Soft spotlight on the lead dancer, pulsing with the beat.
function drawSpotlight(cv, t) {
  const [, p] = beatOf(t);
  const a = 0.05 + 0.05 * (1 - p);
  for (let y = 0; y < 21; y++) {
    const half = 3 + y * 0.35;
    for (let x = Math.floor(33 - half); x <= 33 + half; x++) {
      const e = clamp(half - Math.abs(x + 0.5 - 33), 0, 1);
      cv.add(x, y, hex("#fff2d6"), a * e);
    }
  }
}

// ---------------------------------------------------------------- effects ---

// Sparkle burst where the kicking foot comes back down on the rainbow.
function drawStompSparks(cv, P, D) {
  const lander = 1 - P.kicker; // the leg that kicked on the previous beat
  const fx = D.X([-2, 2][lander]), fy = D.Y(D.ground([-2, 2][lander]));
  const a = P.p;
  for (let i = 0; i < 8; i++) {
    const ang = -Math.PI * (0.05 + 0.9 * (i / 7));
    const d = (1 + a * 7) * D.s;
    const x = fx + Math.cos(ang) * d, y = fy + Math.sin(ang) * d * 0.7 + a * a * 4 * D.s;
    cv.splat(x, y, hsv(i / 8 + P.beat * 0.13, 0.5, 1), (1 - a) * 1.1 * D.s);
  }
}

const NOTE = ["011", "010", "010", "110", "110"];
function drawNotes(cv, t) {
  for (let i = 0; i < 4; i++) {
    const a = mod(t * 2 + i / 4, 1);
    const side = i % 2 ? 1 : -1;
    const x = 32 + side * (9 + a * 9) + Math.sin(TAU * (a * 2 + i * 0.3)) * 1.5;
    const y = 15 - a * 16;
    const c = hsv(i * 0.27 + t, 0.45, 1);
    const alpha = clamp(a * 5, 0, 1) * (1 - a);
    NOTE.forEach((row, ry) => {
      [...row].forEach((on, rx) => on === "1" && cv.blend(Math.round(x) + rx, Math.round(y) + ry, c, alpha));
    });
  }
}

// ---------------------------------------------------------------- compose ---

const LEAD = dancer(32, 1, 1);
const BACKUPS = [dancer(12, 0.6, 1), dancer(52, 0.6, -1)]; // facing the lead

export function renderFrame(t) {
  const cv = new Canvas();
  drawSky(cv, t);
  drawDriftClouds(cv, t);
  drawDiscoLights(cv, t);
  const P = pose(t, LEAD);
  drawRainbow(cv, t, { age: P.p });
  puff(cv, 5, 29.5, 1.1);
  puff(cv, 59, 29.5, 1.1);
  drawNotes(cv, t);
  drawSpotlight(cv, t);
  drawDiscoBall(cv, t);
  const glint = { c: hsv(t * 3, 0.3, 1), a: 0.4 + 0.6 * (1 - P.p) ** 2 };
  for (const D of BACKUPS) {
    const BP = pose(t, D);
    drawFlamingo(cv, BP, D, glint);
    drawStompSparks(cv, BP, D);
  }
  drawFlamingo(cv, P, LEAD, glint);
  drawStompSparks(cv, P, LEAD);
  return cv.toRGBA();
}
