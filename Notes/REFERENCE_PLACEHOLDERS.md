# Reference placeholder register

## Prototype class content

The current Quebra-Mandados, Pistoleiro Orbital, and Hacker de Contratos trio is mechanical prototype content. Names, descriptions, themes, and eventual visual identities are not final. Each definition carries `prototype: true`, while its effect values remain data-driven test scaffolding; replacing the roster must preserve save-ID migration explicitly rather than silently reassigning existing hunters.

These files are proprietary study material used as temporary composition placeholders. They are never tracked or imported by Godot. The four documented images may be staged into the separate `Android Internal References` profile for testing on our own device; public Windows/Android builds retain the independently generated original production art and exclude every reference file.

| Context | Local source under `References/` | Prototype purpose | Original replacement |
| --- | --- | --- | --- |
| Contract board, briefing, hunt, incident, reward | `Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png` | Test a character-rich illustrated mission hub behind the card hierarchy | `assets/backgrounds/bounty_office.png` |
| Galaxy map and career | `Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png` | Test a navigable illustrated world overview rather than an abstract list | `assets/backgrounds/frontier_spaceport.png` |
| Arsenal and workshop | `Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png` | Test a visually grounded upgrade location | `assets/backgrounds/arsenal_workshop.png` |
| Combat and victory | `Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png` | Test illustrated arena depth behind automatic combat | `assets/backgrounds/frontier_arena.png` |

## Boundary rules

- `ReferencePlaceholderBackdrop` is the only runtime file allowed to name `res://References/` paths and maps exactly the four registered contexts.
- Raw image loading is limited to interactive editor runs or builds carrying the explicit `reference_placeholders` feature.
- `References/.gdignore` remains mandatory, so Godot never imports these assets.
- Public export presets must exclude `References/*`; the internal Android profile stages only the four registered PNGs as Git-ignored raw bytes.
- Exported public packs reject reference content, while the internal pack inspector requires and decodes all four staged placeholders.
- Builds and captures containing the visible `PLACEHOLDER INTERNO · SUBSTITUIR` watermark are internal test material, never release or marketing material.
- Replacement art must be independently created; reference names, characters, layouts, text, code, data, and formulas are not production content.
