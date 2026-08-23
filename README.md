# Crooked Galaxy

Mobile-first comedic sci-fi idle RPG built with Godot 4 and GDScript.

## Current playable slice

The prototype implements the product's central test:

`BOUNTY → APPROACH → HUNT / INCIDENT → AUTOMATIC COMBAT → REWARD → LOOT → EQUIP → STRONGER BOUNTY`

It currently includes two complete four-target chapters: Dustball Prime and the frozen corporate world Congelária S.A., each culminating in an original boss and reusable planet-completion screen. Finishing Dustball unlocks a persistent galaxy map and travel. Each planet tracks captures, unlocks harder local warrants independently, and supplies its own hunt incidents and equipment families. A workshop turns unused loot into scrap and spends it on deterministic equipment upgrades. The slice also includes per-target capture records, three risk/reward approaches per contract, AFK-safe hunt resolution, a guided first contract, scalable procedural character portraits, runtime-synthesized sound effects, layered automatic combat with named actions and speed control, a capture beat, an arsenal screen, XP and level progression, simulation-backed risk estimates, post-reward feedback, and local persistence.

## Run

Open `project.godot` in Godot 4, or run from a console where Godot is available:

```powershell
godot --path . --editor
godot --path .
```

Run deterministic core tests:

```powershell
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_flow.gd
godot --headless --path . --script res://tests/test_ui.gd
godot --headless --path . --script res://tests/test_persistence.gd
godot --headless --path . --script res://tests/test_audio.gd
```

Capture the bounty boards, galaxy map, unlocked boss, contract briefing, hunt incident, combat, victory, reward, arsenal, and chapter-completion states for visual review:

```powershell
godot --path . --script res://tools/capture_ui.gd
```

Capture the procedural character lineup:

```powershell
godot --path . --script res://tools/capture_portraits.gd
```

Run the deterministic combat balance simulation:

```powershell
godot --headless --path . --script res://tools/simulate_balance.gd
```

## Project layout

- `scenes/` — Godot scenes.
- `scripts/` — gameplay state, deterministic rules, content, and interface.
- `tests/` — headless deterministic tests.
- `Notes/` — product vision and development rules.
- `References/` — external study material, excluded from Godot imports by `.gdignore`.

Content in `References/` is not part of the game. Crooked Galaxy's code, names, formulas, UI, and distributable assets must remain independently created.
