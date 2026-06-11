# BLACK BOX

You run a space agency. Missions launch, things fail, and you figure out why.

---

## What is this

Black Box is a 2D terminal-aesthetic game where you manage a space agency on a budget. Launch missions through a four-phase program (comm satellite, weather satellite, lunar flyby, lunar landing), and when something goes wrong, you investigate.

Investigations aren't handed to you. You open case files one at a time, read obfuscated telemetry and crew logs, and commit to a hypothesis before anything gets revealed. Get it right and research unlocks, making future missions safer. Get it wrong and the root cause stays unresolved.

---

## How to play

**Goal:** Land on the Moon before your budget or reputation collapses.

**Controls:** Mouse only.

1. Press `>` to start the clock
2. Watch active missions in the left panel. Health drops from incidents and wear.
3. When a mission fails, open INVESTIGATIONS
4. Click through the three case files (EVENTS.LOG, TELEMETRY.DAT, COMMS.LOG)
5. After reviewing two files, submit your hypothesis
6. Correct diagnosis unlocks research that makes future missions safer

**Time controls:** `||` pause, `>` 1x, `>>` 5x, `>>>` 30x

---

## Tech stack

- **Engine:** Godot 4.6 (Compatibility renderer, 2D)
- **Language:** GDScript
- **No external assets.** Terminal aesthetic using SystemFont (Courier New)
- Signal-driven UI, no polling

**Architecture:**

```
EventBus            all signals
GameState           funding, reputation, unlocked missions
TimeManager         in-game calendar, time scale
MissionSystem       mission lifecycle and definitions
IncidentSystem      per-day probability rolls
InvestigationSystem case file generation and hypothesis scoring
TechTree            research unlocks and incident modifiers
```

---

## Running locally

1. Download Godot 4.6 from godotengine.org/download
2. Clone this repo
3. Open Godot, import, select `blackbox/project.godot`
4. Press F5 to run

No plugins, no external dependencies.

---

## Roadmap

- [x] Mission lifecycle and incident simulation
- [x] Black box investigation with file browser UI
- [x] Hypothesis commitment system
- [x] Program objectives chain
- [ ] Pre-launch mission configuration
- [ ] Mid-mission decision events
- [ ] Expanded tech tree
- [ ] Eras 2 to 4: Lunar exploration, Mars program
- [ ] Personnel system

---

## License

MIT
