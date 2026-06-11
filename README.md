# BLACK BOX

> *You are responsible for humanity's future in space.*

A space agency management and investigation game. Launch missions, watch them fail, and figure out why.

![Black Box Screenshot](docs/screenshot.png)

---

## What is this

Black Box is a 2D terminal-aesthetic game where you run a space agency. You manage a budget, launch missions through a four-phase program (communications satellite → weather satellite → lunar flyby → lunar landing), and when something goes wrong — and it will — you investigate the failure like a black box recorder.

Investigations aren't handed to you. You open classified case files one by one, read obfuscated telemetry and symptom logs, and commit to a hypothesis before seeing any recommendations. Get it right: research unlocks and future missions get safer. Get it wrong: the root cause stays unresolved and the next mission launches with the same vulnerability.

---

## How to play

**Goal:** Land on the Moon before your budget or reputation collapses.

**Controls:** Mouse only. All UI is clickable.

1. Press `>` to start the clock
2. Monitor active missions in the left panel — health drops from wear and incidents
3. When a mission fails, go to **INVESTIGATIONS**
4. Click through the three case files (`EVENTS.LOG`, `TELEMETRY.DAT`, `COMMS.LOG`)
5. After reviewing two files, submit your hypothesis
6. Correct diagnosis → research unlocks → future missions are safer

**Time controls:** `||` pause · `>` 1× · `>>` 5× · `>>>` 30×

---

## Tech stack

- **Engine:** Godot 4.6 (Compatibility renderer, 2D only)
- **Language:** GDScript
- **No assets** — pure code. Terminal aesthetic via SystemFont (Courier New)
- Signal-driven UI, no polling

**Architecture:**

```
EventBus          — all signals
GameState         — funding, reputation, unlocked missions
TimeManager       — in-game calendar, time scale
MissionSystem     — mission lifecycle and definitions
IncidentSystem    — per-day probability rolls
InvestigationSystem — case file generation and hypothesis scoring
TechTree          — research unlocks and incident modifiers
```

---

## Running locally

1. Download [Godot 4.6](https://godotengine.org/download)
2. Clone this repo
3. Open Godot → Import → select `blackbox/project.godot`
4. Press F5 to run

No plugins, no external dependencies.

---

## Roadmap

- [x] Mission lifecycle and incident simulation
- [x] Black box investigation with file browser UI
- [x] Hypothesis commitment system (murder mystery, not a tutorial)
- [x] Program objectives chain
- [ ] Pre-launch mission configuration (make failures feel like decisions)
- [ ] Mid-mission decision events
- [ ] Expanded tech tree
- [ ] Eras 2–4: Lunar exploration → Mars program
- [ ] Personnel system

---

## License

MIT
