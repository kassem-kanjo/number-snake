# Decision log

What was decided, why, and what was tried and thrown away. Newest first. Benchmark figures are from `node bench.js 200000` on a 90 by 60 grid unless noted; run-to-run noise is roughly ±10% on lifetimes and ±4 points on idle time.

## 2026-10-13

### Calm is the default; controls are a pinhole
The owner asked for the calm pace by default, with the busy pace behind a button, and for the controls to collapse into a small dot that opens on hover. The panel overlays the bottom of the grid while open rather than reserving space, so the grid never jumps. Benchmark names changed to match: no argument is calm, `busy` is the old normal. Numbers per mode are unchanged by this (calm: about 75 outbreaks per 100,000 ticks, idle 74%; busy: about 290, idle 31%).

### Roadmap review
The owner chose three ideas to build (fullscreen, the trail as a barrier, a second species that circles and crushes) and turned down four: infections that merge or fight, the creature changing with what it eats, painting infection by dragging, and a timeline strip. Those issues are closed as not planned. The project is public under the MIT licence.

### Ambient mode is a mode, not a second simulation
Ambient scales a few existing rates (spawn chance ×0.3, budgets ×0.55, growth ×0.5, at most two colonies, tick rate ×0.6) instead of adding separate logic. Result: 154 outbreaks against 534, idle 73% against 31%, infection never above 6% of the grid, no splitting.

### The creature stays on the grid unless its prey is at the wall
Heads were partly off the edge 13% of the time, including while resting. A hard margin was rejected because cells at the edge would become unreachable, which breaks "infections cannot win". The fix is a soft pull inward that is switched off while hunting something near that wall. Now about 6%, almost all during attacks at the edge.

## 2026-10-12

### Cell numbers mean something
Numbers were random 1 to 8. They now show remaining life on a square-root scale, so the body reads as a contour map. A linear scale was tried first and gave mostly ones and twos.

### Dropped: spitting darts
The creature could throw small darts of itself from range. Dropped: darts were in flight only 2% of the time and hard to see, they needed special cases in six places, and the slowest 10% of fights got about 20% longer.

### Dropped: feuds between colonies
A colony could attack a neighbour's cells. It was safe and cheap, but colonies touch so rarely that an attack happened in only 1.7% of the ticks with two or more alive. Kept on the local branch `worktree-agent-a36bd7aa438846e0d`. Worth revisiting only together with spawning outbreaks closer to each other.

### Dropped: hall of fame
New outbreaks could descend from the longest-lived past ones. Median outbreak life rose 60% (to 994 ticks), idle time halved (to 15%), and traits converged on large colonies that run away. That is less variety, not more.

### Dropped: creature learning
Attack plans leaned toward whatever had eaten fastest. Kills were about 14% quicker, but the spread of plans shrank by a third and the learned preference settled on the plain average, so it narrowed behaviour without creating a style.

### Kept: spores, division into several heads, stealth and poison traits
- Spores: more outbreaks (551 against about 430), all cleared, lineages up to three generations.
- Division: heads split under pressure and wither after. Split 10 to 20% of the time.
- Stealth and poison: fights about 10% longer after softening poison (slow 40%, down from 60%).

### Head size is capped
At full heat the head could reach 22 cells in radius, more than half the grid. Capped to about 18.6. A tighter cap (about 16) made the slowest fights 15 to 20% longer and was backed off.

### Visual restraint
Scars were made fainter and shorter after they washed out the grid. Magenta for poison is limited to half the poison value so infections stay mostly red and black, as originally asked.

### Traits and plans instead of types
The first versions had named infection kinds (plain, runner, fighter, brute) and four named hunting styles. They were replaced by independent continuous traits and freshly rolled plans so that encounters are not built from a fixed set of parts.

### Runs are seeded
Every run grows from one seed shown as a link. A code review found the glyph shuffle used a random sort comparator, which would have made the same seed play differently in different browsers; it was replaced with a Fisher-Yates shuffle.

### Single file, no build
The simulation stays one HTML file that opens by double-click. The only tooling is `bench.js`, which needs Node.
