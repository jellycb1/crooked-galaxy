# Original visual asset register

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

## Rejected experiments

The class illustrations introduced in versions 0.34.0-0.35.0 were rejected on 2026-08-26. Although original and technically valid, their sealed helmets, semi-realistic anatomy, tactical material detail, and serious mood contradicted the humorous caricature-led direction. They were removed from runtime and production assets; Git history retains them for postmortem comparison only. Vector class emblems remain the deliberate fallback until a replacement passes `Notes/ASSET_GENERATION_RULES.md`.
