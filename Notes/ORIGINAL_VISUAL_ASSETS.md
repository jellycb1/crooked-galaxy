# Original visual asset register

Status: provenance record for assets already accepted into production. Creation and editing authority, validation and preservation requirements live in `AGENTS.md`.

Generated with the built-in OpenAI image-generation workflow. No reference image was supplied to the generator. Every prompt required a fully original composition and excluded text, logos, trademarks, recognizable third-party designs, and watermarks.

| Asset | Runtime context | Prompt summary |
| --- | --- | --- |
| `assets/backgrounds/bounty_office.png` | Board, briefing, hunt, incident, reward | Crooked frontier tavern/bounty office; timber and scrap; amber light over navy shadows; central shield plaque and quiet card area. |
| `assets/backgrounds/frontier_spaceport.png` | Galaxy map, career | Improvised spaceport town overlook; stacked towers and landing pads; teal twilight and broad low-detail sky. |
| `assets/backgrounds/arsenal_workshop.png` | Arsenal, equipment recovery | Ramshackle mechanic bay; tool racks, coils and armor stands around a dark central workbench; orange/cyan lighting. |
| `assets/backgrounds/frontier_arena.png` | Combat, victory | Empty landing-pad duel arena; scrap barricades, desert settlement and damaged freighter; violet dusk with warm hazard lights. |

## Production constraints

- Portrait 9:16 composition for the 720×1280 logical viewport.
- Godot import limits every texture to a 1280-pixel longest edge, matching the logical viewport and avoiding oversized mobile residency.
- Hand-painted, satirical science-fiction environment style with an original design language.
- No embedded UI, text, letters, numbers, logos, trademarks, watermarks, or recognizable third-party characters.
- Environment detail remains near the frame; central contrast is controlled by `EnvironmentBackdrop` scrims.
- Source PNGs are tracked production content and must remain included in both desktop and Android pack inspection.

## Reference-informed original interface asset

| Asset | Runtime context | Production record |
| --- | --- | --- |
| `assets/ui/main-dossier-frame-runtime-512x384.png` | Focused dossiers and previews; reusable `StyleBoxTexture` source | Exact user-supplied runtime asset from the Crooked Galaxy art pipeline. It passed the mandatory intake gate and was explicitly approved for integration on 2026-08-31. The file is preserved byte-for-byte; runtime 9-slice margins are 79/61/98/68 pixels. |
| `assets/ui/supporting-panel-runtime-candidate-v1.png` | Section-level supporting information panels | Exact user-supplied runtime asset from the Crooked Galaxy art pipeline. It passed isolated and integrated 450×800 validation at full and half width and was explicitly approved for integration on 2026-08-31. The file is preserved byte-for-byte; runtime 9-slice margins are 48/44/48/44 pixels, code supplies the opaque content fill, and safe content margins are at least 40 horizontal/36 vertical pixels. |
| `assets/ui/runtime/*.png` | Confirmation, success receipts, selected tabs, long-press help, dividers, slider handles, equipment rarity and portrait relationships | Fourteen byte-identical user-supplied runtime candidates accepted on 2026-08-31 after individual source, alpha, 9-slice and 450×800 validation. Adaptive factory gates preserve procedural borders below 72 physical pixels for equipment and 106 physical pixels for portraits. Tier 2 remains reserved for a future Uncommon rarity. Exact contracts and source location are recorded in `assets/ui/runtime/README.md`. |
| `assets/ui/panel_frame_space.png` | Superseded illustrated-panel frame | Previous production frame retained temporarily for visual regression comparison. It is no longer referenced by the runtime catalog or UI factory. |

Technical validation for the active focal frame: 512×384 RGBA, genuine transparent interior and corners, 9-slice margins of 79/61/98/68 source pixels, and a byte-identical copy of the approved source. Shared immutable factory styles apply it only to illustrated focal panels. The approved supporting frame is limited to section-level information panels with at least 112 logical pixels of height. Repeated rows, chips, settings and commerce remain code-native navy/steel so hierarchy stays legible.

## Rejected experiments

The class illustrations introduced in versions 0.34.0-0.35.0 were rejected on 2026-08-26. Although original and technically valid, their sealed helmets, semi-realistic anatomy, tactical material detail, and serious mood contradicted the humorous caricature-led direction. They were removed from runtime and production assets; Git history retains them for postmortem comparison only. Vector class emblems remain the deliberate fallback until a replacement passes `Notes/ASSET_GENERATION_RULES.md`.
