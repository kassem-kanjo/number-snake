# Changelog

Notable changes to Number Snake. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-10-13

First tagged version.

### Added
- A grid of numbered cells with a blue creature that wanders, rests and hunts. Its cells fade through five colours, and each number counts down the cell's remaining life.
- Red-and-black glitch infections, each born with independently rolled traits: greed, growth, armour, spite, nerve, tips, lure, drive, spore, hush and venom.
- Attack plans rolled fresh for every approach (how much it circles, weaves, how close it gets, how hard it strikes, how wide it opens).
- Idle behaviour driven by drifting arousal and restlessness: resting, roaming, patrolling, returning to where it last fed.
- Infections that back away, hit back, hide, poison, and throw spores that carry mutated traits.
- The creature dividing into up to four heads under pressure, with paired heads flanking the same prey.
- A nucleus in each head that leans toward what it is watching; a body that stretches with speed, pulses, and tints toward cyan when worked up.
- Visual detail: swallow stains, fading scars, flecks when a colony dies, torn scanlines on infections.
- Hover panel for infections (traits) and for the creature (what it is doing and how it feels).
- Controls: steer by holding the mouse, double-click to drop an infection, pause, restart, speed.
- Seeded runs with a link that replays the same run.
- Record button that saves a video clip.
- Ambient mode for leaving it running.
- `bench.js`, a headless benchmark, with a `--check` mode that runs on every pull request.
- Project documentation: this changelog, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` and `CONTRIBUTING.md`.

### Fixed
- Duplicate entries in a colony's cell list skewing its centre and the creature's aim.
- A shuffle that made seeded runs differ between browsers.
- Space toggling pause twice; Cmd+R restarting the run; resize wiping the run; non-left clicks steering.
- The creature spending much of its time cut off by the walls.
