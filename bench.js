// Runs the simulation in index.html without a browser and prints what happened.
//   node bench.js [ticks] [cols] [rows] [ambient]
// Use it to check a change: every outbreak should still get eaten, and the
// numbers should not drift far from the last run unless you meant them to.
const fs = require('fs');
const path = require('path');

const ticks = +process.argv[2] || 200000;
const gridCols = +process.argv[3] || 90;
const gridRows = +process.argv[4] || 60;
const ambient = process.argv[5] === 'ambient';

const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
const script = html.slice(html.indexOf('<script>') + 8, html.lastIndexOf('</script>'));

// just enough of a page for the script to start
const noop = () => {};
const ctx = new Proxy({}, { get: () => noop, set: () => true });
const el = () => ({
  getContext: () => ctx, style: {}, addEventListener: noop, setPointerCapture: noop,
  getBoundingClientRect: () => ({ left: 0, top: 0 }), value: 55, textContent: '',
  classList: { add: noop, remove: noop, toggle: noop },
  clientWidth: gridCols * 9 + 32, clientHeight: gridRows * 9 + 24,
});
global.window = global;
global.document = { getElementById: el };
global.addEventListener = noop;
global.requestAnimationFrame = noop;
global.devicePixelRatio = 1;
global.performance = { now: () => 0 };

new Function(script)();
const s = global.snake;
if (ambient) s.setAmbient(true);

const seen = new Map(), lives = [], modes = {};
let maxInfected = 0, several = 0, maxGen = 0, maxHeads = 0, split = 0;
for (let t = 0; t < ticks; t++) {
  s.tick();
  if (s.infected > maxInfected) maxInfected = s.infected;
  if (s.colonies.length > 1) several++;
  if (s.heads.length > 1) split++;
  if (s.heads.length > maxHeads) maxHeads = s.heads.length;
  modes[s.head.mode] = (modes[s.head.mode] || 0) + 1;
  const ids = new Set();
  for (const c of s.colonies) {
    ids.add(c.id);
    if (!seen.has(c.id)) seen.set(c.id, t);
    if (c.gen > maxGen) maxGen = c.gen;
  }
  for (const [id, born] of seen) if (!ids.has(id)) { lives.push(t - born); seen.delete(id); }
}
lives.sort((a, b) => a - b);
const pct = n => Math.round(100 * n / ticks);

console.log(JSON.stringify({
  ticks,
  outbreaksCleared: lives.length,
  stillAlive: seen.size,
  oldestStillAlive: Math.max(0, ...[...seen.values()].map(b => ticks - b)),
  lifeMedian: lives[lives.length >> 1],
  life90: lives[Math.floor(lives.length * 0.9)],
  lifeMax: lives[lives.length - 1],
  idlePct: pct(modes.idle || 0),
  severalAtOncePct: pct(several),
  maxInfectedPct: Math.round(100 * maxInfected),
  maxGeneration: maxGen,
  splitPct: pct(split),
  maxHeads,
}, null, 1));
