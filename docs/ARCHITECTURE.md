# Architecture

The whole simulation is one file, `index.html`: markup, styles and a single script. There is no build step and there are no dependencies. `bench.js` runs the same script under Node with a stubbed page.

## Layout of the script

The script is one closure, split by banner comments into these sections, in order:

| Section | What lives there |
|---|---|
| Setup (top) | Colours, tuning constants, `SPECIES` (the species records), the seeded random generator, `reset`, `newHead`, `layout` |
| Infection | Traits, building colonies, growth, retreat, retaliation, spores, spawning, `updateColonies` |
| Creature | Steering helpers, `idle`, `makePlan`, `engage`, `moveHead`, `stampHead`, `divide`, `manageHeads`, `tick` |
| Drawing | `draw` and the colony drawing helpers |
| Controls | The frame loop, buttons, keys, pointer steering, double-click planting |
| Hover inspector | The panel for colonies and heads, then Record, the Outbreak switch, the pinhole dock, fullscreen and resize handling |

## Data model

The grid is `cols` by `rows`. Every per-cell value is a typed array indexed by `y * cols + x`.

**Creature cells**

- `life`: ticks left. `born`: the life the cell was last topped up to. Colour comes from `life / born`; the printed number comes from `life / FULL`.
- `edge`, `vigor`, `tint`: fixed per-cell noise for a ragged outline, uneven lifetimes and uneven colour changes.
- `hurt`, `stain`, `scar`: tick numbers until which a cell shows corruption, a swallowed cell dissolving, or a faint mark where infection was eaten.
- `who`: the species index of the head that last topped the cell up. Drawing takes the palette and nucleus colour from it.

**Infection cells**

- `germ`: armour layers left (0 means not infected). `owner`: the colony's id. `germHit`: the tick the cell last lost a layer.

**Colonies** (`colonies`, and `byId` for lookup)

- `traits` is the rolled nature. Most values are also copied onto the colony for speed; greed is not, because it only sets the starting `budget`.
- `cells` is a list of indices that may contain dead entries; `held` is the matching Set that stops an index being listed twice. Always test a cell with `alive(c, i)`. Both are rebuilt together when the list gets too stale.
- `count` is the true number of living cells. `energy` is how many more cells it may ever grow.

**Heads** (`heads`)

- The creature is one or more heads. Each has a position, heading, radius, a `mode`, a `plan`, a `prey`, its own trail `path`, a `species` (its record from `SPECIES`), and inner state: `arousal`, `restless`, `fullness`, `anger`, `heat`, `sick`, `vitality`.
- `root` is true for the two permanent heads: the hunter, which is always `heads[0]`, is steered by the mouse and is counted in the tally; and the warden. Withering (`vitality`) applies only to heads that are not root. A head made by `divide` inherits its parent's species.
- A species with `hollow` above 0 has a ring for a body instead of a blob. Its heads carry `ring` (the current radius) and `gap` (the half-angle of the opening, centred on the heading; 0 is a closed circle), each with a goal it eases toward. `stampHead` lays only the cells on the ring, which live `glow` ticks, so a ring leaves no trail. During a strike the radius falls faster each tick (`clap`, growing with `crush`, capped at the ring's thickness), and whatever it meets is removed regardless of armour. When it reaches zero the impact sets `ripples`, `shakeUntil` and `freeze`; while `freeze` is above 0, `tick` does nothing.
- The global `head` points at whichever head is acting. `tick` sets it before `moveHead` and `stampHead`; `updateColonies` sets it to the head nearest each colony. Anything that reads `head` relies on that.

## Resizing

`layout` picks the cell size and grid from the window. The first time it calls `reset`; after that it calls `regrid`, which moves every per-cell array, colony, head and mark onto the new grid without restarting. Any new per-cell array must be carried across in `regrid` as well as created in `reset`.

## One tick

1. Every creature cell loses one tick of life.
2. For each head: `moveHead` (sense, pick or continue a mode, steer, move), then `stampHead` (top up the cells under it, eat or chip the infection under it, trigger retaliation).
3. `manageHeads`: heads may divide; extra (non-root) heads wither.
4. `updateColonies`: maybe spawn; then for each colony survey, grow, retreat, maybe throw a spore; remove dead colonies.
5. Flecks move and expire.

Drawing happens separately, once per animation frame in which at least one tick ran.

## Rules that must hold

- **The fresh trail blocks infection.** `pickFrontier` refuses any creature cell with more than `BARRIER` of its life left, for growth and for retreat alike.
- **One defender per infection.** In `moveHead`, `known` leaves out any infection another head has claimed, unless it is big enough to seat more (`SHARE` cells per extra head).
- **At least one defender is always present.** `setPresent` refuses to remove the last species.
- **Infections cannot win.** Growth only ever spends `energy`, spores hand over part of the parent's energy, and nothing adds energy. The creature gets stronger with `heat`.
- **Seeded runs replay exactly.** Tick logic uses only `random()`. `Math.random()` is used only to pick a seed, in `reset`, when the address did not ask for one. Drawing and hover code must not call `random()` or change simulation state. User input (steering, double-click) is allowed to change a run.
- **Bookkeeping stays consistent.** `infected` equals the number of cells with `germ > 0`; each colony's `count` equals the cells it owns. Only `addCell` and `removeCell` change these.
- **Nothing is chosen from a list of types.** A species is a record of numbers, not a named behaviour. Behaviour comes from continuous traits and rolled plans. A new behaviour should be a new trait or a new plan dimension, not a new named kind or species.
- **Behaviour is not chosen by species name.** Species differ only through the numbers in `SPECIES`: palette, the ranges plans are rolled from, and temperament. A value of 0 switches a behaviour off (the hunter's `hollow` is 0, so it is a solid blob, and the warden's chance of dividing is 0). No code tests a species name.

## Adding a trait

1. Add it to `TRAITS` with its range and a one-line meaning.
2. Roll it in `rollTraits`. `mutate` picks it up automatically.
3. Copy it onto the colony in `buildColony`, and give it a visible cue in `c.look` if it should be readable on screen.
4. Use it where the behaviour happens.
5. Add a label to `SHOWN` so the hover panel shows it, and a row to the trait table in the README.
6. Run the benchmark before and after (see `CONTRIBUTING.md`).
