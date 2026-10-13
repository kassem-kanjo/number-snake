# Number Snake

A grid of small numbered cells with a blue creature, shaped after a white blood cell, that wanders across it and hunts red-and-black glitchy infections. Nothing about the game is scripted: every infection is born with its own randomly rolled traits, and every attack the creature makes is a freshly rolled plan.

## How to run it

Open `index.html` in any web browser. There is nothing to install.

- Hold the mouse button down to steer the creature toward the pointer. Let go and it goes back to its own behaviour.
- Hover over an infected cell (button up) to read that infection's nature in a small panel.
- Double-click an empty cell to drop a new infection there.
- Space pauses and resumes. R restarts with a new grid.
- The Pause and Restart buttons do the same as the keys.
- The Speed slider sets how many simulation steps run per second.
- The "run" number in the bar is a link to that exact run. Opening it replays the same run, as long as the window is the same size and you don't steer.

## What you are looking at

- **Blue cells** are the creature's body. A freshly touched cell is bright blue. It fades through cyan, violet and mint into dark navy as its life runs out.
- **The trail** is thickest under the centre of the creature and thins toward its edge.
- **The body** stretches out along its heading when it moves fast and sits squat when it is still.
- **The dark violet patch** inside the creature is its nucleus. It leans toward whatever the creature is watching, so you can see it notice an infection before it moves, and it tightens when the creature coils to strike.
- **Faint pink cells** mark where infection was recently eaten. They fade.
- **Numbers** appear on the cells the creature has passed over. Each is rolled from 1 to 8. The code gives them no further meaning.
- **Violet-to-pink cells** are infected cells being swallowed and dissolving.
- **Black and red flickering cells** in the creature's body are parts that have been corrupted after a bite bounced off armour.
- **Red dots arcing across the grid** are spores in flight, landing new infections.
- **Small red and black flecks** scatter from the spot where an infection dies. Bigger infections scatter more.
- **Red and black cells** are infected cells. Armoured cells, which take several bites, go almost solid black.
- **Glyphs** are small symbols drawn in an infection's cells. Each infection has its own set. Spiteful infections spark white or pink.
- **Flicker**: an infection's look changes every few ticks. Jumpy infections flicker faster, and ones that hide flicker slowly and stay dark.
- **Magenta cells** in an infection mean it is poisonous. Eating them slows and shrinks the creature for a while.
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

A spore child copies its parent's traits with small random nudges.

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

Run `node bench.js [ticks] [cols] [rows]` from the project folder. It needs only Node, not a browser. The defaults are 200000 ticks on a 90 by 60 grid. It runs the simulation headless and prints JSON:

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
- `maxHeads`: the most heads alive at one time.

Each benchmark run uses a new random seed, so numbers change from run to run. Compare runs with a large tick count, and expect some variation.
