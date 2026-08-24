# Reference placeholder register

These files are proprietary study material used only to prototype composition in local interactive editor runs. They are not tracked, imported by Godot, or permitted in Windows/Android exports. Every public build uses the original procedural backdrop when these files are unavailable.

| Context | Local source under `References/` | Prototype purpose | Replacement requirement |
| --- | --- | --- | --- |
| Contract board, briefing, hunt, incident, reward | `Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png` | Test a character-rich illustrated mission hub behind the card hierarchy | Original orbital bounty-office/station illustration |
| Galaxy map and career | `Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png` | Test a navigable illustrated world overview rather than an abstract list | Original crooked-galaxy route/spaceport tableau |
| Arsenal and workshop | `Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png` | Test a visually grounded upgrade location | Original ship workshop/scrapyard interior |
| Combat and victory | `Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png` | Test illustrated arena depth behind automatic combat | Original planet-specific bounty encounter scenes |

## Boundary rules

- `ReferencePlaceholderBackdrop` is the only runtime file allowed to name `res://References/` paths.
- Raw image loading is limited to editor-feature binaries with a non-headless display.
- `References/.gdignore` remains mandatory, so Godot never imports these assets.
- All export presets must exclude `References/*`.
- Exported packs are mounted in an isolated inspector and rejected if any known placeholder or `References` directory is present.
- Captures containing the visible `PLACEHOLDER INTERNO` watermark are internal composition evidence, never marketing material.
- Replacement art must be independently created; reference names, characters, layouts, text, code, data, and formulas are not production content.
