# Crooked Galaxy

Mobile-first comedic sci-fi idle RPG built with Godot 4 and GDScript.

## Current playable slice

The prototype implements the product's central test:

`BOUNTY → HUNT → AUTOMATIC COMBAT → REWARD → LOOT → EQUIP → STRONGER BOUNTY`

It currently includes three original bounties on Dustball Prime, procedural equipment, XP and level progression, reputation ranks, risk estimates, and local persistence.

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
```

Capture the current bounty board for visual review:

```powershell
godot --headless --path . --script res://tools/capture_ui.gd
```

## Project layout

- `scenes/` — Godot scenes.
- `scripts/` — gameplay state, deterministic rules, content, and interface.
- `tests/` — headless deterministic tests.
- `Notes/` — product vision and development rules.
- `References/` — external study material, excluded from Godot imports by `.gdignore`.

Content in `References/` is not part of the game. Crooked Galaxy's code, names, formulas, UI, and distributable assets must remain independently created.
