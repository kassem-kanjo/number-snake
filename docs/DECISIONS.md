# Decision log

What was decided, why, and what was tried and thrown away. Newest first. Benchmark figures are from `node bench.js 200000` on a 90 by 60 grid unless noted; run-to-run noise is roughly ±10% on lifetimes and ±4 points on idle time.

## 2026-10-13

### The warden is a ring that claps
The owner rejected the first warden: "too similar to the hunter... two same ones make it so messy." It had passed every measurement set for it (it travelled a median 1.4 turns round its prey before striking) and still read as a second blob with a second trail. What was wanted was "like clapping a fly, but a circle".

The warden is now a thin ring whose cells live about five ticks, so it leaves no trail. It rests as a closed circle, opens into a cup facing its prey, slides until the prey is inside, closes the gap, holds, then its radius falls to zero at 0.9 cells a tick, eating what it passes. A colony too big to encircle (the ring tops out at 12 cells, 17 when worked up) gets a ring-sized bite. It is expressed as numbers on the species record (`hollow`, `glow`, `cup`, `crush`, `cap`), not as a named kind. The first warden's edge-following approach, its `standoff` and `circle` plan dimensions and its long trail were deleted.

Outbreak mode, 200,000 ticks: 530 to 553 outbreaks cleared, none left alive, median life 419 to 456 ticks, slowest tenth 1074 to 1177, hunter idle 35 to 38%. The warden eats 21 to 22% of infected cells, up from 12% for the first version. Calm mode: 188 cleared, warden's share 27%. Warden alone in Outbreak mode: all cleared, median 1423, longest 13,000 ticks. Hunter alone is unchanged.

Tuned by eye after the build: the ring is one solid colour with a lighter tone as it fades (five colour bands flickered on such short-lived cells); it rests wider and thinner (radius 5 to 7.5, thickness 1.8) because a small thick ring looked like a doughnut; every clap runs to completion and ends in a small burst.

Process note: the build was first handed to a Sonnet worker from a written spec. It delivered the mechanics; the look had to be finished by eye. Behaviour and appearance work now stays with whoever can see the screen.

### A resize keeps the run
Any change in window size used to start a new run. Now `regrid` rebuilds the per-cell arrays at the new size and carries everything across, anchored to the centre. Growing only adds empty space. On shrinking, each colony slides as a whole until it fits and loses only cells that still cannot fit or that land on another colony; heads, their paths and their remembered places are clamped inside; trail cells outside the new grid are dropped, since heads re-lay them at once. Checked by shrinking and growing a busy run four times (90x60 to 60x40 to 126x81 to 30x20 to 90x60) with the bookkeeping audit after each: no failures, and the one drastic shrink lost 12 of 203 infected cells. A resized run no longer matches its seed link, which was already true of any run in a different-sized window.

### A button for each defender; a lone defender loses its calm
Each species has a button that removes it from the grid or returns it. One must always stay, or infections could win, so asking the last one to leave brings the others back.

The warden alone could not keep up in Outbreak mode: median outbreak life 1708 ticks, the slowest 10% over 5000, one siege of 26,987 ticks (about 8 minutes), peak infection 54%. Rather than special-casing it, the rule is that any species with no partner on the grid feels the full heat and may divide, whatever its own numbers say. Warden alone after that: median about 1300, slowest 10% about 3600, longest 10,900 to 13,000, every outbreak cleared. Still slow, by choice of whoever switched the hunter off. Hunter alone matches the old single-creature numbers (median 551, slowest 10% 1431). Calm mode is fine either way.

### A second species: the warden
Added a second permanent defender beside the hunter (GitHub issue #5). The owner asked for "one that circles then crushes the virus, and it acts way more calm and calculated". The warden is teal and green, so it reads apart from the blue hunter. Each species is a record of numbers in one `SPECIES` table, and no code chooses behaviour by species name.

Outbreak mode, 200,000 ticks on a 90 by 60 grid, two runs each (run 1 / run 2). Before, then after: outbreaks cleared 523 / 549, then 517 / 580. Median life 600 / 488, then 473 / 431. Slowest tenth (life90) 1556 / 1263, then 1140 / 990. Idle 28% / 36%, then 37% / 35%. Peak infected share 35% / 60%, then 43% / 43%. Trail-blocked growth 72,792 / 84,346, then 73,393 / 80,789. The warden ate 12% / 13% of infected cells. With two defenders, outbreaks live about 15 to 20% shorter at the median and about 25 to 30% shorter in the slowest tenth.

Calm mode, same settings: outbreaks cleared 147 / 143, then 147 / 142. Median life 454 / 442, then 378 / 366. Slowest tenth 838 / 849, then 625 / 563. Idle 76% / 74%, then 79% / 79%. Peak infected share 6% / 6%, then 4% / 4%. The warden ate 10% / 11%. Calm mode is quieter but not trivial.

Circling, measured over 100,000 Outbreak ticks, two runs: the warden made 217 / 179 circling approaches. The median total angle around the prey's centre was 0.90 / 0.91 of a turn over all approaches, and 1.41 / 1.35 turns for approaches that went on to a strike. Its net (signed) angle is smaller, about 0.2 of a turn, because it reverses at walls and colonies often sit near one. About 57% / 59% of approaches travelled at least 0.75 of a turn. About half do not end in a strike, because the hunter eats the prey first or the head changes target. Warden strikes: 82 / 66, all slow (burst below 0.7). Hunter strikes: 865 / 795, of which 56 / 44 were slow. Trail-blocked growth attempts per 100,000 busy ticks went from 44,551 / 34,620 to 45,765 / 37,416, so there is no clear change.

Tuned or rejected:
- The first warden pace of 0.35 to 0.6 was too slow to get round a ring of 15 to 20 cells in the circling time (median 0.38 net and 0.65 gross turns). It became 0.7 to 1.1.
- Circling time began at 260 to 520 ticks and became 200 to 420. That gave about 25 more strikes per 100,000 ticks while the median travel stayed above 0.75 of a turn.
- Wall reversal was added. Without it, colonies within about 14 cells of a wall were circled poorly (net 0.43 turns, against 1.07 for colonies in the open). Reversal raised the total angle travelled but lowered the net angle. It happens at most once every 60 ticks.
- Cells are coloured by species, using a per-cell `who` array, rather than by the head now on the cell. Each cell keeps the colour of whoever laid it.

### The busy mode is called Outbreak
The owner found "Busy" dull for something meant to be shown off. Outbreak says what the mode is in the simulation's own terms. The button turns red when it is on.

### The fresh trail is a barrier
Infection cannot grow or retreat into a creature cell that still has more than 34% of its life (its first three colours). One line in `pickFrontier`. In outbreak mode the trail turned away 56,000 to 77,000 growth attempts per 200,000 ticks, so it is constantly in play, while lifetimes stayed inside run-to-run noise (median 543 to 560 ticks against 551 to 568 before; slowest 10% 1413 to 1555 against 1458 to 1473). Calm mode: 11,000 blocked, all outbreaks cleared. Kept: it gives circling a purpose and sets up a defender that pens its prey.

### Calm is the default; controls are a pinhole
The owner asked for the calm pace by default, with the outbreak pace behind a button, and for the controls to collapse into a small dot that opens on hover. The panel overlays the bottom of the grid while open rather than reserving space, so the grid never jumps. Benchmark names changed to match: no argument is calm, `outbreak` is the old normal. Numbers per mode are unchanged by this (calm: about 75 outbreaks per 100,000 ticks, idle 74%; outbreak: about 290, idle 31%).

### Roadmap review
The owner chose three ideas to build (fullscreen, the trail as a barrier, a second species that circles and crushes) and turned down four: infections that merge or fight, the creature changing with what it eats, painting infection by dragging, and a timeline strip. Those issues are closed as not planned. The project is public under the MIT licence.

### The calm pace is a mode, not a second simulation
First added as "ambient mode" and later made the default. It scales a few existing rates (spawn chance ×0.3, budgets ×0.55, growth ×0.5, at most two colonies, tick rate ×0.6) instead of adding separate logic. Result: 154 outbreaks against 534, idle 73% against 31%, infection never above 6% of the grid, no splitting.

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
