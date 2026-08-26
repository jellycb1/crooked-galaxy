# Reference study register — archived

## Runtime status — 2026-08-26

No asset from `References/` is active in Crooked Galaxy or included in its Android/Windows exports. The former thirteen-image test allowlist, runtime loader, feature flag, watermark, staging step, and public-build exception were removed in version 0.28.0.

Their independently created replacements are:

- `assets/backgrounds/bounty_office.png` for contracts;
- `assets/backgrounds/frontier_spaceport.png` for world, career, classes, and onboarding;
- `assets/backgrounds/arsenal_workshop.png` for arsenal, market, and hangar;
- `assets/backgrounds/frontier_arena.png` for combat and the Fenda;
- `scripts/class_icon.gd` for all three class emblems;
- `scripts/portrait_frame.gd` for hunter and archive portrait framing;
- an original styled separator in `scripts/main.gd` for the board hub.

`References/.gdignore` remains mandatory so Godot never imports the local study library. Both export presets exclude `References/*`; Android has no custom reference feature and no staged include filter. The pack inspector rejects raw paths and every former `internal_reference_assets/*.png.bin` path.

The material may still be consulted locally for high-level flow and usability analysis. Production implementation must continue using independently written code, copy, data, characters, iconography, and visual composition.
