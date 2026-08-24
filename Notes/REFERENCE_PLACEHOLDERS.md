# Reference placeholder register

## Prototype class content

The current Quebra-Mandados, Pistoleiro Orbital, and Hacker de Contratos trio is mechanical prototype content. Names, descriptions, themes, and eventual visual identities are not final. Each definition carries `prototype: true`, while its effect values remain data-driven test scaffolding; replacing the roster must preserve save-ID migration explicitly rather than silently reassigning existing hunters.

These files are proprietary study material used as temporary composition placeholders. They are never tracked or imported by Godot. The thirteen documented images are staged into the single Android APK used on our own test device. Windows remains reference-free; Android also retains the independently generated original production art as its fallback.

| Context | Local source under `References/` | Prototype purpose | Original replacement |
| --- | --- | --- | --- |
| Contract board, briefing, hunt, incident, reward | `Shakes and Fidget Assets/StreamingAssets/tavern/tavern_back.png` | Test a character-rich illustrated mission hub behind the card hierarchy | `assets/backgrounds/bounty_office.png` |
| Galaxy map and career | `Shakes and Fidget Assets/StreamingAssets/town/bg_town_day.png` | Test a navigable illustrated world overview rather than an abstract list | `assets/backgrounds/frontier_spaceport.png` |
| Arsenal and workshop | `Shakes and Fidget Assets/StreamingAssets/locations/bg_fort_0.png` | Test a visually grounded upgrade location | `assets/backgrounds/arsenal_workshop.png` |
| Market | `Shakes and Fidget Assets/StreamingAssets/dealer/default/dealer_day.png` | Give the equipment shop a recognizable merchant silhouette instead of reusing the arsenal | Original Crooked Galaxy frontier dealer |
| Transport hangar | `Shakes and Fidget Assets/StreamingAssets/stable/stable_Tag_good_2k.png` | Test an immediately recognizable vehicle showroom composition | Original Crooked Galaxy orbital hangar |
| Combat and victory | `Shakes and Fidget Assets/StreamingAssets/locations/location_battle_0.png` | Test illustrated arena depth behind automatic combat | `assets/backgrounds/frontier_arena.png` |
| Class-selection surface | `Shakes and Fidget Assets/StreamingAssets/ui/sf_4k_UI-BG-navi.png` | Test an ornamental portrait panel with stronger section framing | Original Crooked Galaxy sci-fi navigation frame |
| Quebra-Mandados prototype icon | `Shakes and Fidget Assets/StreamingAssets/registration/icon_warrior_active.png` | Test immediate heavy-class recognition inside cards and the attribute profile | Original class emblem after the placeholder roster is finalized |
| Pistoleiro Orbital prototype icon | `Shakes and Fidget Assets/StreamingAssets/registration/icon_hunter_active.png` | Test immediate precision-class recognition inside cards and the attribute profile | Original class emblem after the placeholder roster is finalized |
| Hacker de Contratos prototype icon | `Shakes and Fidget Assets/StreamingAssets/registration/icon_mage_active.png` | Test immediate technology-class recognition inside cards and the attribute profile | Original class emblem after the placeholder roster is finalized |
| Career surface | `Shakes and Fidget Assets/StreamingAssets/ui/sf_4k_UI-BG-navi-login.png` | Test a dedicated long-form career ledger instead of reusing the galaxy-map surface | Original Crooked Galaxy career/archive frame |
| Important portrait frame | `Shakes and Fidget Assets/StreamingAssets/z_shared/portrait_glow_border_300.png` | Test visual priority around hunter and current-mastery portraits | Original modular portrait frame |
| Board hub divider | `Shakes and Fidget Assets/StreamingAssets/ui/frame_top.png` | Test a lightweight boundary between secondary destinations and the active contract | Original sci-fi board divider |

## Boundary rules

- `ReferencePlaceholderBackdrop` is the only runtime file allowed to name `res://References/` paths and maps eight composition surfaces plus five interface textures.
- Raw image loading is limited to interactive editor runs or builds carrying the explicit `reference_placeholders` feature.
- The adapter retains only the current decoded placeholder. Changing or leaving a context drops the previous texture, and the production backdrop is unloaded while a placeholder is visible.
- `References/.gdignore` remains mandatory, so Godot never imports these assets.
- Every export preset excludes raw `References/*`; the single Android profile stages only the thirteen registered PNGs as Git-ignored raw bytes.
- The Android pack inspector requires and decodes all thirteen staged placeholders; the Windows inspector remains reference-free.
- Builds and captures containing the visible `PLACEHOLDER INTERNO · SUBSTITUIR` watermark are test material, never release or marketing material.
- Replacement art must be independently created; reference names, characters, layouts, text, code, data, and formulas are not production content.
