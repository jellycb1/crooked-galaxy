# Crooked Galaxy

Mobile-first comedic sci-fi idle RPG built with Godot 4 and GDScript.

## Current playable slice

The prototype implements the product's central test:

`BOUNTY → APPROACH → HUNT / INCIDENT → AUTOMATIC COMBAT → REWARD → LOOT → EQUIP → STRONGER BOUNTY`

It currently includes four complete four-target chapters: Dustball Prime, the frozen corporate world Congelária S.A., the fungal network planet Micélia 404, and the mechanical scrapyard Ferro-Velho Ômega. Each destination has an original visual theme, escalating targets, boss, hunt incidents, and equipment family. Finishing chapters unlocks persistent galaxy-map travel, while local captures reveal harder warrants independently. A capped eight-hour AFK patrol grants credits and scrap on return, while consecutive captures build a capped credit-paying streak that is lost on defeat or abandonment. A career screen summarizes planets, lifetime patrol earnings, claimable milestones, and a persistent sixteen-target wanted archive. Rare equipment can carry build-relevant power or integrity modifications, while the workshop compares effective stats, filters, sorts, protects valuable pieces, manages two persistent loadouts, safely bulk-recycles, and upgrades equipment. The slice also includes three risk/reward approaches per contract, AFK-safe hunt resolution, scalable procedural portraits, runtime-synthesized sound effects, planet-themed automatic combat, XP and level progression, simulation-backed risk estimates, content validation, versioned save migration, and local persistence.

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
godot --headless --path . --script res://tests/test_save_migrations.gd
godot --headless --path . --script res://tests/test_equipment_presentation.gd
godot --headless --path . --script res://tests/test_career_rules.gd
godot --headless --path . --script res://tests/test_audio.gd
godot --headless --path . --script res://tests/test_content.gd
godot --headless --path . --script res://tests/test_mobile.gd
```

Capture the bounty boards, AFK return, career, galaxy map, unlocked boss, contract briefing, hunt incident, combat, victory, reward, arsenal filters, and chapter-completion states for visual review:

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
