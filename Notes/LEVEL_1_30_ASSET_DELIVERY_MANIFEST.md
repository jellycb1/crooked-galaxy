# Level 1–30 asset delivery manifest

Status: active production handoff generated from the runtime catalog. This document defines order; `scripts/visual_asset_catalog.gd` defines exact paths and technical contracts.

The 151 final visual deliveries are produced in five closed batches:

1. `style_lock` — 17 files: Quebra-Mandados class promotion, the complete 12-file Terran modular set, the three-file Dustball Prime environment set and Gloop. Nothing expands until these files work together in real 450×800 captures.
2. `identity` — 86 files: the remaining two classes and seven complete 12-file species sets.
3. `worlds` — 38 files: the remaining 23 level 1–30 targets and five complete three-file planet sets.
4. `transports` — 4 vehicle illustrations.
5. `rift` — the first 6 enemy portraits from the Alfândega do Universo Morto.

Species and planet sets are atomic: partial files may be reviewed outside runtime, but their fallback remains active until the complete set passes intake and integrated capture validation. Every candidate remains rejected by default under `ASSET_GENERATION_RULES.md`.

Print the prioritized missing manifest:

```powershell
godot --headless --path . --script res://tools/export_release_asset_manifest.gd -- --missing
```

Limit it to the pilot batch:

```powershell
godot --headless --path . --script res://tools/export_release_asset_manifest.gd -- --batch=style_lock --missing
```

Add `--json` for a machine-readable handoff. The manifest records the exact runtime path, atomic set, canvas, intended phone presentation, transparency and anchor for every delivery.

## External candidate preflight

Keep work-in-progress candidates outside `assets/`. The review folder mirrors the contents of `res://assets/`; for example, `<candidate-root>/characters/classes/warrant_breaker.png` maps to the eventual runtime path without being copied there.

Validate every present pilot candidate without requiring the batch to be finished:

```powershell
godot --headless --path . --script res://tools/preflight_release_asset_candidates.gd -- --candidate-root="D:\CrookedGalaxyCandidates" --batch=style_lock
```

When all 17 files are delivered, add `--require-complete`. The preflight rejects missing or unreadable PNGs, incorrect canvas, oversized imports, absent required transparency, unexpected habitat transparency and misaligned modular canvases. Passing it is only the technical gate; reference evidence, manual style review and integrated 450×800 captures remain mandatory before any file enters runtime.
