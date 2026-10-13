# How work is done here

## Workflow

1. **Start from an issue.** Every change has a GitHub issue that says what and why. Ideas go in as issues labelled `idea` until they are picked up.
2. **Branch off `main`.** Name it by kind and topic: `feat/trail-barrier`, `fix/wall-clipping`, `docs/architecture`.
3. **Open a pull request** that links the issue (`Closes #12`), says what changed and how it was checked, and includes benchmark numbers for anything that touches the simulation.
4. **Checks must pass.** The pull request runs `node bench.js --check`.
5. **Merge by squash**, delete the branch, and add a line to `CHANGELOG.md` under Unreleased.

`main` should always open and run.

## Checking a change

```bash
node bench.js 200000 90 60 outbreak
```

Run it before and after, at least twice each, because every run uses a new seed. Outbreak mode is the demanding one, so it is the one to compare. Expectations on the default 90 by 60 grid:

| Field | Healthy range |
|---|---|
| `stillAlive` | 0 to 6, with `oldestStillAlive` not growing run to run |
| `lifeMedian` | 400 to 520 ticks |
| `life90` | 900 to 1200 ticks |
| `idlePct` | 30 to 40 |
| `maxInfectedPct` | usually 30 to 55 |

A change is suspect if it moves `lifeMedian` or `life90` by more than about 25%, or pushes `idlePct` below about 26. Record what you measured in `docs/DECISIONS.md`, including for ideas that were dropped.

For the calm default (expect far fewer outbreaks, the creature idle around 70 to 75% of the time, and infection under about 10% of the grid):

```bash
node bench.js 200000
```

The quick pass/fail version, which CI runs in both modes:

```bash
node bench.js --check
```

```bash
node bench.js --check 80000 90 60 outbreak
```

It fails if the script throws, if bookkeeping drifts, if no outbreak is cleared, or if an outbreak survives far longer than any normal one.

Then open `index.html` and look. The benchmark cannot judge how it feels.

## What the benchmark prints

`node bench.js [ticks] [cols] [rows] [outbreak]` tests the calm default; pass `outbreak` as the fourth argument for Outbreak mode. The defaults are 200000 ticks (80000 with `--check`) on a 90 by 60 grid, and the page picks its own cell size, so large grids can come out smaller than asked. Every run uses a new seed.

- `ticks`: the number of steps run.
- `outbreaksCleared`: infections that were fully eaten or died out during the run.
- `stillAlive`: infections alive at the end.
- `oldestStillAlive`: age in ticks of the oldest infection still alive.
- `lifeMedian`, `life90`, `lifeMax`: median, 90th percentile and longest life, in ticks, of the cleared infections.
- `idlePct`: percent of ticks the first head spent idle.
- `severalAtOncePct`: percent of ticks with more than one infection alive.
- `maxInfectedPct`: the highest share of the grid that was infected, in percent.
- `maxGeneration`: the deepest spore generation seen (0 is an original infection).
- `eatenShare`: percent of infected cells eaten by each species, by name.
- `splitPct`: percent of ticks with a split-off head alive. The two permanent defenders do not count.
- `growthBlockedByTrail`: how many attempts by an infection to grow or back away into the creature's fresh trail were turned away.
- `maxHeads`: the most heads alive at one time, counting both permanent defenders.

## Rules for the code

Read `docs/ARCHITECTURE.md` first. In short:

- Infections can never win.
- Tick logic uses only the seeded `random()`; drawing never does.
- New behaviour is a new trait or plan dimension, never a new named type.
- If an addition is rarely visible or needs special cases all over, remove it and write down why.

## Releases

Versions follow semantic versioning. To release: move the Unreleased notes in `CHANGELOG.md` under a new version heading, merge, then tag and publish with `gh release create vX.Y.Z --notes-from-tag` or with the changelog section as notes.
