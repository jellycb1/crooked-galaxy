# Original visual asset register

Generated with the built-in OpenAI image-generation workflow. No reference image was supplied to the generator. Every prompt required a fully original composition and excluded text, logos, trademarks, recognizable third-party designs, and watermarks.

| Asset | Runtime context | Prompt summary |
| --- | --- | --- |
| `assets/backgrounds/bounty_office.png` | Board, briefing, hunt, incident, reward | Crooked frontier tavern/bounty office; timber and scrap; amber light over navy shadows; central shield plaque and quiet card area. |
| `assets/backgrounds/frontier_spaceport.png` | Galaxy map, career | Improvised spaceport town overlook; stacked towers and landing pads; teal twilight and broad low-detail sky. |
| `assets/backgrounds/arsenal_workshop.png` | Arsenal, equipment recovery | Ramshackle mechanic bay; tool racks, coils and armor stands around a dark central workbench; orange/cyan lighting. |
| `assets/backgrounds/frontier_arena.png` | Combat, victory | Empty landing-pad duel arena; scrap barricades, desert settlement and damaged freighter; violet dusk with warm hazard lights. |
| `assets/classes/orbit_gunslinger_character_v1.png` | Orbit Gunslinger class choice and dossier | Species-neutral space-western hunter; navy patched coat, mustard scarf, sealed cyan visor, compact ray pistol; bold ink and cel shading on genuine transparency. |

## Production constraints

- Portrait 9:16 composition for the 720×1280 logical viewport.
- Godot import limits every texture to a 1280-pixel longest edge, matching the logical viewport and avoiding oversized mobile residency.
- Hand-painted, satirical science-fiction environment style with an original design language.
- No embedded UI, text, letters, numbers, logos, trademarks, watermarks, or recognizable third-party characters.
- Environment detail remains near the frame; central contrast is controlled by `EnvironmentBackdrop` scrims.
- Source PNGs are tracked production content and must remain included in both desktop and Android pack inspection.
- Class illustrations use genuine transparency and remain separate from the player's modular species, appearance, and equipment portrait.
- The first class illustration is an intentional vertical slice. Unillustrated classes keep their original vector emblems until equivalent assets meet the same silhouette and readability bar.
