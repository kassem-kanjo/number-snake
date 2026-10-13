// Runs the simulation in index.html without a browser and prints what happened.
//   node bench.js [ticks] [cols] [rows] [outbreak]     the default is the calm mode
//   node bench.js --check        quick pass/fail, used by CI
// Use it to check a change: every outbreak should still get eaten, and the
// numbers should not drift far from the last run unless you meant them to.
const fs = require('fs');
const path = require('path');

const check = process.argv.includes('--check');
const args = process.argv.slice(2).filter(a => a !== '--check');
const ticks = +args[0] || (check ? 80000 : 200000);
const gridCols = +args[1] || 90;
const gridRows = +args[2] || 60;
const outbreak = args[3] === 'outbreak';

const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
const script = html.slice(html.indexOf('<script>') + 8, html.lastIndexOf('</script>'));

// just enough of a page for the script to start
const noop = () => {};
const ctx = new Proxy({}, { get: () => noop, set: () => true });
const el = () => ({
  getContext: () => ctx, style: { setProperty: noop }, addEventListener: noop, setPointerCapture: noop,
  getBoundingClientRect: () => ({ left: 0, top: 0 }), value: 55, textContent: '',
  classList: { add: noop, remove: noop, toggle: noop },
  clientWidth: gridCols * 9 + 32, clientHeight: gridRows * 9 + 50, offsetWidth: 600, offsetHeight: 60,
  setProperty: noop,
});
global.window = global;
global.document = { getElementById: el };
global.addEventListener = noop;
global.requestAnimationFrame = noop;
global.devicePixelRatio = 1;
global.performance = { now: () => 0 };

new Function(script)();
const s = global.snake;
s.setAmbient(!outbreak);

// things that must be true at any moment
const failures = [];
function audit(t) {
  const cells = s.colonies.reduce((n, c) => n + c.count, 0);
  if (cells !== Math.round(s.infected * gridCols * gridRows)) failures.push(`tick ${t}: colony cell counts (${cells}) disagree with the infected total`);
  for (const c of s.colonies) {
    if (new Set(c.cells).size !== c.cells.length) failures.push(`tick ${t}: colony ${c.id} lists a cell twice`);
    if (!(c.energy <= c.budget)) failures.push(`tick ${t}: colony ${c.id} gained energy`);
  }
  for (const h of s.heads) {
    if (![h.x, h.y, h.a, h.R, h.v].every(Number.isFinite)) failures.push(`tick ${t}: a head has a non-number in its state`);
  }
}

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
  if (check && t % 200 === 0) audit(t);
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
  growthBlockedByTrail: s.walled,
  maxHeads,
}, null, 1));

if (check) {
  const oldest = Math.max(0, ...[...seen.values()].map(b => ticks - b));
  if (!lives.length) failures.push('no outbreak was cleared');
  if (oldest > 12000) failures.push(`an outbreak has survived ${oldest} ticks`);
  if (failures.length) {
    console.error('FAILED\n' + [...new Set(failures)].slice(0, 10).join('\n'));
    process.exit(1);
  }
  console.log('ok');
}
