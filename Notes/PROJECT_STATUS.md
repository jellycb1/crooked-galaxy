# Crooked Galaxy — current project status

Status: active handoff. Updated 31 August 2026 after repository-wide organization and consistency audit.

This is the concise starting point for a new task. Product details remain authoritative in the contracts indexed by `Notes/README.md`; measurable behavior remains authoritative in code and tests.

## Product

- Android-first Portuguese/English comedic space-fantasy idle RPG.
- Mandatory local onboarding covers locale, `International 1`, login, class, race, appearance and hunter name.
- Three mechanical classes, eight cosmetic races, five attributes and one universal nine-slot inventory.
- The permanent mission network contains 35 worlds, 140 targets and 70 incidents through level 320.
- Timed hunts continue during navigation, suspension and application closure.
- Daily objectives, weekly Operations, mastery, career milestones, collection, transports and three keyed twelve-enemy Rift realities provide the current retention structure.
- Monetization is simulated with Warp Chips and contains no advertisements or season pass. Real billing is not active.

## Runtime and online boundary

- Project version is `0.99.1`, Android version code `169`.
- The normal game remains device-authoritative and boots offline.
- The pinned Nakama/PostgreSQL staging stack and authoritative hunt/build transaction have passed loopback, public-TLS Windows and Android-emulator probes.
- Endpoint, client key, account/profile/economy activation, billing, PvP, rankings and Bounty Agencies remain disabled in the ordinary APK.
- Local progress is never imported or merged into the future online economy; the approved cutover archives it and starts a pristine remote character.

## Visual state

- The complete visual catalog currently records 443 required deliverables, 21 available runtime-core assets and 422 missing character, destination, enemy, transport or icon deliveries. Mechanically complete content must not be described as visually complete.
- The executable level 1–30 gate isolates 151 final art deliveries from that annual catalog: 3 classes, 96 modular species units, 24 targets, 18 world assets, 4 transports and 6 Rift enemies. Its mechanical scope passes; the current visual result is 0/151, measured independently by `tools/audit_release_readiness.gd` while functional fallbacks remain active.
- The 17-file `style_lock` pilot now has a read-only external-folder preflight that checks completeness, PNG readability, exact modular/world canvases, alpha requirements and mobile budgets before any candidate is copied into runtime.
- The approved focal dossier, supporting panel and fourteen specialized runtime UI assets are integrated.
- The reviewed 26-file core UI batch therefore has 16 integrated assets.
- Four painted button faces, one danger panel and two opaque dividers were rejected at phone size.
- Checkbox, radio and toggle candidates contained only one state; their complete code-native replacements are active in settings, language selection and inventory protection.
- The remaining ten raster candidates stay outside runtime exports until corrected under `AGENTS.md` and `Notes/ASSET_GENERATION_RULES.md`.
- Codex is authorized to create, correct, transform, optimize and integrate visual assets after the mandatory quality gate.

## Verified baseline

- `tools/check_project.ps1 -Fast` passes repository, documentation, reference, backend, gameplay, persistence, localization, UI, mobile and clean-boot gates.
- `tools/check_android_export.ps1` produces the ARM64/API-24+ package and inspects its content, version, signature and reference boundary.
- The current verified local APK after this cleanup contains the complete UI-control batch and excludes all ten held candidates.
- Physical Android touch latency, vendor lifecycle, thermal and storage behavior remain unverified because no personal Android device is currently available; the Android Studio emulator is the current device-level evidence.

## Recommended next work

1. Prove the visual language with the atomic 17-file `style_lock` pilot defined in `LEVEL_1_30_ASSET_DELIVERY_MANIFEST.md`; keep every fallback active until the complete pilot passes integrated 450×800 captures.
2. Only then complete the identity, worlds, transports and Rift batches that bring the level 1–30 gate from 0/151 to 151/151.
3. Correct and re-review held UI candidates only when they materially support that slice.
4. Exercise the seven-day physical Android gate before changing XP, prices or weekly targets from preference alone.
5. Keep ordinary online capabilities disabled until the real-device lifecycle/cutover evidence is available; do not add more horizontal systems meanwhile.

## Repository organization

- Historical audits and completed implementation blueprints were removed from the working tree; Git history remains their archive.
- Active contracts, current art briefs, operational staging evidence and reproducible simulation documents remain under `Notes/`.
- Dependency and hash scans found no orphan runtime scripts and no duplicate tracked files.
- `scripts/game_state.gd` and `scripts/main.gd` remain the largest code concentrations; future extraction should follow tested feature boundaries rather than cosmetic file splitting.
- `References/`, `builds/`, `.godot/` and `artifacts/` are local/ignored data with distinct ownership and are not source documentation.
- The obsolete `assets/ui/panel_frame_space.png` was removed because no runtime, tool or active contract consumed it.
