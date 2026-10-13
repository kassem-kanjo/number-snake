# Number Snake

A grid of small numbered cells with a blue creature, shaped after a white blood cell, that wanders across it and hunts red-and-black glitchy infections. Nothing about the game is scripted: every infection is born with its own randomly rolled traits, and every attack the creature makes is a freshly rolled plan.

## How to run it

Play it in your browser at **https://kassem-kanjo.github.io/number-snake/**, or download this repository and open `index.html`. There is nothing to install.

- Hold the mouse button down to steer the creature toward the pointer. Let go and it goes back to its own behaviour.
- Hover over an infected cell (button up) to read that infection's nature in a small panel. Hover over the creature to see what it is doing and how it feels.
- Double-click an empty cell to drop a new infection there.
- The controls rest as a small dot at the bottom of the window. Move the mouse onto it and it opens into a panel; move away and it closes. On a touch screen, tap it.
- Space pauses and resumes. R restarts with a new grid. F enters and leaves fullscreen, where only the grid shows and even the dot hides while the mouse is still.
- The Pause, Restart and Fullscreen buttons do the same as the keys.
- The Speed slider sets how fast the simulation runs. The calm pace runs at 60% of the Outbreak pace for the same setting.
- It starts at a calm pace meant for leaving it running: outbreaks are rare, small and slow, at most two at a time. The Outbreak button switches to more, bigger and faster infections, several at once, and back.
- Adding `?saver=1` to the address shows the grid and nothing else and ignores input. The Mac screensaver uses this.
- Record saves a video clip of the grid. Press it once to start and again to stop; the file downloads when you stop.
- The "run" number in the bar is a link to that exact run. Opening it replays the same run, as long as the window is the same size and you don't steer or drop infections.

## What you are looking at

- **Blue cells** are the creature's body. A freshly touched cell is blue when the creature is calm and shifts toward bright cyan as it gets worked up. It fades through cyan, violet and mint into dark navy as its life runs out.
- **The trail** is thickest under the centre of the creature and thins toward its edge. While it is fresh (its first three colours) it is a wall: infection cannot grow into it or back away through it, so a creature that circles an infection pens it in.
- **The body** stretches out along its heading when it moves fast and sits squat when it is still.
- **The dark violet patch** inside the creature is its nucleus. It leans toward whatever the creature is watching, so you can see it notice an infection before it moves. It tightens when the creature coils to strike and nearly closes when the creature dozes.
- **Faint pink cells** mark where infection was recently eaten. They fade.
- **Numbers** on the creature's cells count down how much life each cell has left, from 8 to 1, so the body reads like a contour map: high in the middle of the front, falling away toward the edges and down the trail.
- **Violet-to-pink cells** are infected cells being swallowed and dissolving.
- **Black and red flickering cells** in the creature's body are parts that have been corrupted after a bite bounced off armour.
- **Red dots arcing across the grid** are spores in flight, landing new infections.
- **Small red and black flecks** scatter from the spot where an infection dies. Bigger infections scatter more.
- **Red and black cells** are infected cells. Armoured cells, which take several bites, go almost solid black.
- **Glyphs** are small symbols drawn in an infection's cells. Each infection has its own set. Spiteful infections spark white or pink.
- **Flicker**: an infection's look changes every few ticks. Jumpy infections flicker faster, and ones that hide flicker slowly and stay dark.
- **Magenta cells** in an infection mean it is poisonous: the more magenta, the more likely each mouthful is to poison. Poison slows and shrinks the creature for a while.
- **Torn scanlines** are short red or black bars sticking out of an infection's sides. Bigger infections have more of them.

## How it works

### Infection traits

Each infection rolls its own values for these traits. They are independent, so an infection can be any mixture of them.

| Trait | Range | Meaning |
|---|---|---|
| greed | 0 to 1 | How much of the grid it could ever cover |
| growth | 0.4 to 5 | Cells per tick |
| armour | 0 to 1 | Chance of extra layers on each cell |
| spite | 0 to 1 | How readily, and how often, it hits back |
| nerve | 0 to 1 | How readily it backs away |
| tips | 0 to 1 | 0 grows as a lump, 1 grows as tendrils |
| lure | -1 to 1 | Grows toward (+) or away from (-) the creature |
| drive | 0 to 1 | Creeps in one direction |
| spore | 0 to 1 | How readily it throws off offspring |
| hush | 0 to 1 | How well it hides its scent, so the creature notices it later |
| venom | 0 to 1 | How sick it makes whatever eats it |

A spore child copies its parent's traits with small random nudges. At the calm pace greed and growth are scaled down after rolling (to 55% and 50%), so growth can sit below the range shown.

### Attack plans

Each time the creature goes after an infection, `makePlan` rolls a new plan from independent choices: how much it circles rather than coming straight in, how much it weaves, how fast it approaches, how close it gets before committing, how long it coils before striking, how hard it strikes, how wide it opens, how far past the target it carries on, and how long it rests afterwards. No plan is a preset. A lunge, a quick bite, a tightening spiral and a slow engulf are just different settings of the same choices.

### Idle moods

With nothing to hunt, the creature never simply drifts. Its arousal and restlessness change over time, and every so often it picks somewhere to go: nowhere in particular, a spot where it last fed, or a random point with a lean toward the edges. Along the way it rests and breathes slowly when calm, dawdles, makes sudden starts, and noses about when it arrives. A full creature is calmer.

### Why infections cannot win

- Each infection has an energy budget set by its greed. Every cell it grows and every spore it throws uses energy. When the energy runs out, it stops growing.
- The number of infections alive at once is capped, and new outbreaks become less likely as the grid fills up.
- The creature tracks heat, which rises with how much of the grid is infected and with its own anger (bites bouncing off armour). Higher heat makes it bigger, quicker to strike and shorter in its waits, and more likely to split. The more infection there is, the harder it presses.

### Armour and spite

When a bite bounces off armour, the creature is thrown back, part of its body glitches, and the infection lashes a spike back at it. A spiteful infection does this more readily and harder, but only a limited number of times. The hover panel shows how many hits it has left.

### Spores

An infection with enough cells and energy can throw a spore. The child lands 10 to 30 cells away, takes a share of the parent's remaining energy, and gets a mutated copy of its traits.

### Dividing under pressure

When heat gets high enough, the creature can pinch into several heads, up to a fixed maximum. The heads spring apart and hunt separately. When things calm down, the extra heads wither and disappear. The original head always stays. Two heads after the same infection come round it from opposite sides.

## Testing

Run `node bench.js [ticks] [cols] [rows] [outbreak]` from the project folder. It tests the calm default; to test Outbreak mode pass `outbreak` as the fourth argument, after ticks, columns and rows (for example `node bench.js 200000 90 60 outbreak`). The page picks its own cell size, so the grid can come out smaller than asked for large sizes. `node bench.js --check` is the quick pass/fail version that runs on every pull request. It needs only Node, not a browser. The defaults are 200000 ticks (80000 with `--check`) on a 90 by 60 grid. It runs the simulation headless and prints JSON:

- `ticks`: the number of steps run.
- `outbreaksCleared`: infections that were fully eaten or died out during the run.
- `stillAlive`: infections alive at the end.
- `oldestStillAlive`: age in ticks of the oldest infection still alive.
- `lifeMedian`, `life90`, `lifeMax`: median, 90th percentile and longest life, in ticks, of the cleared infections.
- `idlePct`: percent of ticks the first head spent idle.
- `severalAtOncePct`: percent of ticks with more than one infection alive.
- `maxInfectedPct`: the highest share of the grid that was infected, in percent.
- `maxGeneration`: the deepest spore generation seen (0 is an original infection).
- `splitPct`: percent of ticks with more than one head.
- `growthBlockedByTrail`: how many attempts by an infection to grow or back away into the creature's fresh trail were turned away.
- `maxHeads`: the most heads alive at one time.

Each benchmark run uses a new random seed, so numbers change from run to run. Compare runs with a large tick count, and expect some variation.

## Credit

The idea started from a grid animation by Antonin Waterkeyn, seen in a [post by Figs From Plums](https://x.com/FigsFromPlums/status/2108195710210396426): a snake made of numbered, coloured cells moving across a grid. All code here was written for this project.

## Project docs

- [CHANGELOG.md](CHANGELOG.md): what changed in each version.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code is organised and the rules it must keep.
- [docs/DECISIONS.md](docs/DECISIONS.md): what was decided and why, including ideas that were tried and dropped.
- [CONTRIBUTING.md](CONTRIBUTING.md): how changes are made, checked and released.

## Licence

[MIT](LICENSE). Use it, change it, share it; keep the copyright notice.
