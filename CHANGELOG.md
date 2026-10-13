# Changelog

Notable changes to Number Snake. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `skip=N` in the address starts a run N ticks in, so a link can open mid-action.

### Changed
- Resizing the window, or entering and leaving fullscreen, no longer restarts the run. A bigger window adds empty grid round what is there; a smaller one pushes the defenders and infections back inside.
- The README is shorter, leads with an image and links to play or download, and explains each trait alongside how to spot it. The benchmark's field list moved to CONTRIBUTING.md.

## [0.2.0] - 2026-10-13

### Added
- A Mac app and a Mac screensaver, with an icon, as downloads on each release. Build them yourself with `mac/build.sh`.
- A button for each defender, to take it off the grid or put it back. Run links carry the choice (`hunter=0`, `warden=0`).
- An icon and link-preview details on the page, so a shared link shows a title, a description and the icon.
- MIT licence.
- A hosted version at https://kassem-kanjo.github.io/number-snake/.
- The creature's fresh trail is a barrier: infection cannot grow, or back away, into cells the creature has just covered.
- A screensaver view (`saver=1` in the address): the grid and nothing else, ignoring input.
- Fullscreen (F or the Fullscreen button): nothing but the grid, with the controls hidden while the mouse is still.
- A second, permanent defender, the warden (teal and green): it circles an infection colony, tightens in, then coils and crushes it. It is calmer than the hunter and never divides.

### Fixed
- The control panel clipping when its text grew, staying open after a click, and its hover area blocking the grid beneath it.
- `bench.js --check` failing falsely on grids other than 90 by 60.
- Fullscreen on older Safari; the grid being laid out twice when entering or leaving fullscreen.

### Changed
- A run link saved before the calm pace became the default replays at the calm pace, so it will not match the run it was copied from.
- The calm pace is now the default. The former normal pace is now called Outbreak and has its own button; run links carry `outbreak=1` instead of `ambient=1`.
- The control bar is now a pinhole at the bottom of the window that opens into a panel on hover. The grid uses the freed space.
- `bench.js` tests the calm mode by default; pass `outbreak` for outbreak mode.

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
