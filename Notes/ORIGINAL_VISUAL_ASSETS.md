# Original visual asset register

Status: provenance record for assets already accepted into production. It does not authorize Codex to create or edit visual assets; current authorship rules live in `AGENTS.md`.

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
| `assets/ui/panel_frame_space.png` | Focused dossiers and previews; reusable `StyleBoxTexture` source | Generated from an original Crooked Galaxy navy/steel/brass/coral/cyan specification after inspecting local UI study references. Reference roles were limited to dark-center hierarchy, thin warm trim, hand-painted edge rhythm, and corner restraint; no fantasy vine, thorn, wood, ornament, exact frame path, text, logo, or reference asset was copied. The displayed direction was explicitly approved on 2026-08-26. The approved draft was then processed deterministically to remove only the exterior black connected to the canvas edge, crop the frame, preserve the opaque navy center, and resize it to 660×124 RGBA. |

Technical validation: genuine transparent corners, 9-slice margins of 48/20/48/20 logical pixels, shared immutable factory styles, and complete 450×800 captures for class detail, mandatory onboarding previews, selected mandate, contract briefing, hunter profile, universal arsenal kit, active hangar transport, hunt incident, victory, normal/Rift reward, chapter conclusion, career summary, and current/locked Rift dossiers. Supporting cards, repeated rows, settings, and commerce retain code-native navy/steel styling so the illustrated frame remains a focused hierarchy marker.

## Rejected experiments

The class illustrations introduced in versions 0.34.0-0.35.0 were rejected on 2026-08-26. Although original and technically valid, their sealed helmets, semi-realistic anatomy, tactical material detail, and serious mood contradicted the humorous caricature-led direction. They were removed from runtime and production assets; Git history retains them for postmortem comparison only. Vector class emblems remain the deliberate fallback until a replacement passes `Notes/ASSET_GENERATION_RULES.md`.
