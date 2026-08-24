# Reference placeholder register

## Prototype class content

The current Quebra-Mandados, Pistoleiro Orbital, and Hacker de Contratos trio is mechanical prototype content. Names, descriptions, themes, and eventual visual identities are not final. Each definition carries `prototype: true`, while its effect values remain data-driven test scaffolding; replacing the roster must preserve save-ID migration explicitly rather than silently reassigning existing hunters.

These files are proprietary study material that was used only to prototype composition in local interactive editor runs. They are not tracked, imported by Godot, or permitted in Windows/Android exports. All four studied contexts now use independently generated original production art, so the placeholder adapter has no active mappings.

| Context | Local source under `References/` | Prototype purpose | Original replacement |
| --- | --- | --- | --- |
| Contract board, briefing, hunt, incident, reward | `Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png` | Test a character-rich illustrated mission hub behind the card hierarchy | `assets/backgrounds/bounty_office.png` |
| Galaxy map and career | `Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png` | Test a navigable illustrated world overview rather than an abstract list | `assets/backgrounds/frontier_spaceport.png` |
| Arsenal and workshop | `Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png` | Test a visually grounded upgrade location | `assets/backgrounds/arsenal_workshop.png` |
| Combat and victory | `Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png` | Test illustrated arena depth behind automatic combat | `assets/backgrounds/frontier_arena.png` |

## Boundary rules

- `ReferencePlaceholderBackdrop` is retained as the only runtime file allowed to name `res://References/` paths, but currently exposes no contexts.
- Raw image loading is limited to editor-feature binaries with a non-headless display.
- `References/.gdignore` remains mandatory, so Godot never imports these assets.
- All export presets must exclude `References/*`.
- Exported packs are mounted in an isolated inspector and rejected if any known placeholder or `References` directory is present.
- Captures containing the visible `PLACEHOLDER INTERNO` watermark are internal composition evidence, never marketing material.
- Replacement art must be independently created; reference names, characters, layouts, text, code, data, and formulas are not production content.
