// BunnyByt scene: a golden sparkly bunny hopping on the beach, 64x32.
// Pure JavaScript, no dependencies. renderFrame(t) takes t in [0, 1) (one full
// loop) and returns RGBA bytes. Everything that moves repeats once per loop,
// so the animation is seamless.

export const W = 64;
export const H = 32;
const FRAMES = 64;      // internal time steps per loop

// ---------- palette ----------
const C = {
  skyTop: [70, 140, 235], skyBot: [255, 190, 150],
  sun: [255, 225, 70], sunCore: [255, 250, 190],
  cloud: [255, 255, 255], cloudShade: [215, 225, 245],
  seaDeep: [20, 90, 170], sea: [30, 140, 200], foam: [235, 250, 255],
  wet: [190, 160, 110], sand: [240, 205, 140], sandDot: [215, 175, 110],
  gold: [245, 170, 20], goldHi: [255, 215, 80], goldDk: [175, 105, 5],
  pink: [255, 130, 170], eye: [60, 30, 20], tail: [255, 255, 235],
  star: [255, 120, 80], shell: [255, 200, 220],
  sparkle: [255, 255, 200], sparkleCore: [255, 255, 255],
};

// ---------- bunny sprite (faces right) ----------
// G gold, H highlight, D dark gold, P pink, K eye, W fluffy tail
const BUNNY = [
  "........DH.DH..",
  "........GP.GP..",
  "........GP.GP..",
  "........GG.GG..",
  ".......GHHHHGG.",
  "......GHHHHKHG.",
  "......GHHHHHHGP",
  "...DGGGHHHHHGD.",
  "..GHHHHHGGGGD..",
  ".WGHHHHHHHHGD..",
  "WWGHHHHHHHHGD..",
  ".WDGGGGGGGGGD..",
  "...DD....DD....",
];
const BW = BUNNY[0].length, BH = BUNNY.length;
const SPRITE_COLORS = { G: C.gold, H: C.goldHi, D: C.goldDk, P: C.pink, K: C.eye, W: C.tail };

// ---------- helpers ----------
const lerp = (a, b, t) => a + (b - a) * t;
const mix = (c1, c2, t) => [lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t)];
// tiny deterministic random so the loop is seamless and the same every time
function rand(n) { let x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }

function makeCanvas() {
  const buf = new Uint8ClampedArray(W * H * 4);
  const set = (x, y, c, a = 1) => {
    x = Math.round(x); y = Math.round(y);
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    const i = (y * W + x) * 4;
    buf[i] = lerp(buf[i], c[0], a); buf[i + 1] = lerp(buf[i + 1], c[1], a); buf[i + 2] = lerp(buf[i + 2], c[2], a); buf[i + 3] = 255;
  };
  return { buf, set };
}

// ---------- where the bunny is on frame t ----------
// Hops right across the sand, turns around, hops back. 4 hops each way.
const GROUND = 29;            // y of the bunny's feet
const X_LEFT = 4, X_RIGHT = 44;
function bunnyState(t) {
  const half = FRAMES / 2;
  const goingRight = t < half;
  const p = (t % half) / half;                       // 0..1 along this leg
  const x = goingRight ? lerp(X_LEFT, X_RIGHT, p) : lerp(X_RIGHT, X_LEFT, p);
  const hopP = (p * 4) % 1;                          // 4 hops per leg
  const air = Math.sin(Math.PI * hopP);
  return { x, y: GROUND - BH + 1 - air * 7, air, facingRight: goingRight };
}

// ---------- scene pieces ----------
function drawSky(set) {
  for (let y = 0; y < 15; y++) for (let x = 0; x < W; x++) set(x, y, mix(C.skyTop, C.skyBot, y / 14));
}

function drawSun(set, t) {
  const cx = 54, cy = 5;
  for (let y = -4; y <= 4; y++) for (let x = -4; x <= 4; x++) {
    const d = Math.hypot(x, y);
    if (d <= 3.6) set(cx + x, cy + y, d < 2 ? C.sunCore : C.sun);
  }
  // twinkling rays that slowly spin
  for (let k = 0; k < 8; k++) {
    const ang = (k / 8) * Math.PI * 2 + (t / FRAMES) * Math.PI / 2;
    const on = (k + Math.floor(t / 4)) % 2 === 0;
    set(cx + Math.cos(ang) * 5.5, cy + Math.sin(ang) * 5.5, C.sun, on ? 1 : 0.4);
  }
}

function drawCloud(set, x0, y0) {
  const shape = [" .##.  ", ".####.#", "#######", " ##### "];
  shape.forEach((row, y) => [...row].forEach((ch, x) => {
    if (ch === "#" || ch === ".") set(((x0 + x) % W + W) % W, y0 + y, y === 3 ? C.cloudShade : C.cloud, ch === "." ? 0.7 : 1);
  }));
}

function drawSea(set, t) {
  const phase = (t / FRAMES) * Math.PI * 2;
  for (let y = 15; y < 22; y++) for (let x = 0; x < W; x++) {
    set(x, y, mix(C.seaDeep, C.sea, (y - 15) / 6));
  }
  // rolling foam ripples
  for (let x = 0; x < W; x++) {
    const w = Math.sin(x * 0.4 + phase * 2);
    if (w > 0.75) set(x, 16 + Math.round(Math.sin(x * 0.15 + phase) * 0.6), C.foam, 0.8);
    if (Math.sin(x * 0.3 - phase * 3) > 0.85) set(x, 19, C.foam, 0.6);
  }
  // sun glitter on the water
  for (let k = 0; k < 6; k++) {
    if (rand(k + Math.floor(t / 3) * 7) > 0.5) set(46 + k * 3, 17 + (k % 3), C.sparkleCore);
  }
}

function drawSand(set, t) {
  const phase = (t / FRAMES) * Math.PI * 2;
  // the shoreline washes in and out
  const reach = 22 + Math.round((Math.sin(phase) + 1) * 1.2);
  for (let y = 22; y < H; y++) for (let x = 0; x < W; x++) {
    const edge = reach + Math.round(Math.sin(x * 0.35 + phase) * 0.8);
    if (y <= edge) set(x, y, y === edge ? C.foam : C.wet, y === edge ? 0.9 : 1);
    else set(x, y, C.sand);
  }
  for (let i = 0; i < 40; i++) set(Math.floor(rand(i) * W), 25 + Math.floor(rand(i + 99) * 7), C.sandDot);
  // a starfish and a seashell to find
  [[3, 0], [2, 1], [3, 1], [4, 1], [3, 2], [2, 3], [4, 3]].forEach(([x, y]) => set(57 + x, 26 + y, C.star));
  [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [1, 2]].forEach(([x, y]) => set(32 + x, 29 + y, C.shell));
}

function drawShadow(set, b) {
  const w = Math.round(lerp(10, 5, b.air));
  const cx = b.x + BW / 2;
  for (let i = 0; i < w; i++) set(cx - w / 2 + i, GROUND + 1, C.sandDot, 0.8);
}

function drawBunny(set, b, t) {
  // a shiny glint that sweeps diagonally across the golden fur
  const glint = ((t * 1.5) % 40) - 10;
  for (let y = 0; y < BH; y++) for (let x = 0; x < BW; x++) {
    const ch = BUNNY[y][b.facingRight ? x : BW - 1 - x];
    if (ch === ".") continue;
    let col = SPRITE_COLORS[ch];
    if ("GHD".includes(ch) && Math.abs(x + y - glint) < 1.5) col = C.sparkleCore;
    set(b.x + x, b.y + y, col);
  }
}

// 4-point twinkle star; size 0..2
function drawSparkle(set, x, y, size) {
  if (size <= 0) return;
  set(x, y, C.sparkleCore);
  for (let r = 1; r <= size; r++) {
    const a = r === size ? 0.6 : 1;
    set(x + r, y, C.sparkle, a); set(x - r, y, C.sparkle, a);
    set(x, y + r, C.sparkle, a); set(x, y - r, C.sparkle, a);
  }
}

function drawSparkles(set, t) {
  // sparkles that orbit and twinkle around the bunny
  const b = bunnyState(t);
  for (let k = 0; k < 4; k++) {
    const life = (t + k * 5) % 12;
    const size = life < 6 ? Math.round(life / 2.5) : Math.round((12 - life) / 2.5);
    const seed = Math.floor((t + k * 5) / 12) * 13 + k;
    drawSparkle(set, b.x + rand(seed) * (BW + 4) - 2, b.y + rand(seed + 5) * BH - 2, size);
  }
  // a glittery trail left behind each hop
  for (let age = 1; age <= 10; age++) {
    const s = (t - age * 2 + FRAMES) % FRAMES;
    const pb = bunnyState(s);
    if (rand(s) < 0.4) continue;
    const tx = pb.x + (pb.facingRight ? 0 : BW) + (rand(s + 3) - 0.5) * 4;
    const ty = pb.y + BH - 3 + (rand(s + 7) - 0.5) * 4;
    const size = age < 3 ? 1 : 0;
    if (size) drawSparkle(set, tx, ty, size);
    else set(tx, ty, age < 7 ? C.sparkle : C.gold, 1 - age / 11);
  }
}

// ---------- public: render one frame as RGBA pixels ----------
export function renderFrame(loopT) {
  const t = (((loopT * FRAMES) % FRAMES) + FRAMES) % FRAMES;
  const { buf, set } = makeCanvas();
  drawSky(set);
  drawSun(set, t);
  drawCloud(set, Math.round((t / FRAMES) * W) + 4, 2);
  drawCloud(set, Math.round((t / FRAMES) * W) + 34, 6);
  drawSea(set, t);
  drawSand(set, t);
  const b = bunnyState(t);
  drawShadow(set, b);
  drawBunny(set, b, t);
  drawSparkles(set, t);
  return buf;
}
