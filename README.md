# Crooked Galaxy

Mobile-first comedic science-fiction idle RPG built with Godot 4 and GDScript.

The current playable loop is:

`WARRANT → APPROACH → ASYNCHRONOUS HUNT → INCIDENT → AUTOMATIC COMBAT → REWARD → EQUIPMENT → STRONGER WARRANT`

Crooked Galaxy is Android-first, fully playable in Portuguese and English, and currently device-authoritative. `International 1` is the stable identity of the future global server, but this build does not claim authentication, cloud synchronization, remote economy authority, billing, PvP, rankings, or syndicates.

## Current product state

- Mandatory resumable onboarding: language, server, local login, class, race, cosmetic appearance, and a validated hunter name.
- Three initial classes: Quebra-Mandados, Pistoleiro Orbital, and Hacker de Contratos.
- Eight cosmetic-only races with 81 appearance recipes each; race never changes mechanics.
- Five attributes: Strength, Vitality, Dexterity, Intelligence, and Cunning.
- One universal nine-slot equipment model for every current and future class.
- Nineteen modular mission worlds through level 160, containing 76 targets and 38 incidents.
- Three deterministic interplanetary warrant offers after the guided first capture.
- Wall-clock hunts that continue while navigating other interfaces, suspending, closing, or reopening the game.
- Permanent transports that reduce travel time only; fuel cost remains tied to base route length.
- Automatic combat with class signatures, enemy profiles, build odds, tactical equipment, and persisted evidence.
- Procedural item instances, three active rarities, planet kits, traits, workshop investment, two loadouts, protection, recycling, pagination, and a 1,220-series collection.
- Daily objectives, weekly Operations, target mastery, capture streaks, career milestones, and an eight-hour AFK patrol cap.
- Two keyed Fenda Clandestina realities with twelve enemies each and one global entry per UTC day.
- Local monetization simulation using Credits, Scrap, and Warp Chips; no real-money billing is integrated.
- Versioned atomic saves, backups, recovery, migrations, interrupted-phase restoration, and an explicit future server-revision boundary.

Detailed product authority is indexed in [Notes/README.md](Notes/README.md). The accumulated implementation history lives in [Notes/AUDIT_2026-08-23.md](Notes/AUDIT_2026-08-23.md); historical entries are not current instructions.

## Product invariants

- Accepted enemies never scale from currently equipped power. Equipment must make an existing accepted warrant genuinely easier.
- New planets enter the permanent rotating mission network; they do not restore a mandatory linear campaign.
- The board offers different destinations when at least three worlds are available.
- Hunt deadlines are authoritative timestamps. Ignoring an incident has no consequence and does not pause travel.
- Classes share inventory; races are visual and narrative only.
- Monetization may sell bounded time reduction or additional choices, never levels, attributes, victory, combat probability, exclusive superior gear, Fenda attempts, advertisements, or a season pass.
- Device-local state must never be described as online, authenticated, synchronized, or server-authoritative.
- Visual assets are supplied by the user or an external artist. Codex preserves code-native fallbacks and does not create substitute artwork.

## Architecture

| Path | Responsibility |
| --- | --- |
| `project.godot` | Project metadata, autoloads, localization, and display configuration. |
| `scenes/` | Godot scenes. |
| `scripts/` | State, deterministic rules, presentation, and UI. |
| `scripts/content/packs/` | One validated canonical content pack per mission world. |
| `tests/` | Headless deterministic, UI, persistence, localization, and mobile tests. |
| `tools/` | Gates, simulations, benchmarks, captures, exports, and publishing helpers. |
| `assets/` | Accepted production assets only. |
| `Notes/` | Product vision, active contracts, asset specifications, and historical audits. |
| `References/` | Local study library; Git-ignored, Godot-ignored, and export-excluded. |
| `builds/` | Regenerable local exports and QA captures; only `.gdignore` is tracked. |

`scripts/content/content_pack_registry.gd` is the single deterministic composition point for planets, targets, incidents, and item catalogs. `scripts/content_db.gd` preserves the stable public facade consumed by gameplay and saves.

`scripts/game_state.gd` owns device-authoritative transactions and persistence. Account, character, locale, shard, ownership, revision, and synchronization claims remain separate so a future backend can replace authority without heuristic save merging.

## Run locally

Open the editor or run the game:

```powershell
godot --path . --editor
godot --path .
```

The repository checker automatically performs a one-time headless import when a clean checkout does not yet contain Godot's global script-class cache.

## Validation

Fast development gate, including the exhaustive semantic persistence matrix and representative durable file round-trips:

```powershell
.\tools\check_fast.ps1
```

Complete commit/release gate (currently the same behavioral authority under a release-oriented profile):

```powershell
.\tools\check_project.ps1
```

The complete gate also verifies repository hygiene, document authority, reference isolation, clean boot, PT/EN parity, Android-safe layout, touch scrolling, lifecycle timers, economy, content, progression, and save migration.

Run an individual suite when isolating a failure:

```powershell
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_mission_rules.gd
godot --headless --path . --script res://tests/test_mobile.gd
godot --headless --path . --script res://tests/test_persistence_matrix.gd
```

## Simulations and audits

```powershell
godot --headless --path . --script res://tools/simulate_balance.gd
godot --headless --path . --script res://tools/simulate_campaign.gd
godot --headless --path . --script res://tools/audit_year_one_pacing.gd
godot --headless --path . --script res://tools/audit_rift_realities.gd
godot --headless --path . --script res://tools/audit_visual_asset_readiness.gd -- --missing
```

Campaign simulation accepts `CG_CAMPAIGN_BUILD`, `CG_CAMPAIGN_STRATEGY`, `CG_CAMPAIGN_CAREERS`, `CG_CAMPAIGN_MARKET=active|off`, and `CG_CAMPAIGN_TRANSPORT=active|off` for focused comparisons.

## Visual QA

Generate the current 450×800 UI matrix and the procedural portrait lineup with a graphical renderer:

```powershell
godot --path . --script res://tools/capture_ui.gd
godot --path . --script res://tools/capture_portraits.gd
```

Captures are written under `builds/` and are intentionally not retained as source. If the renderer cannot expose a viewport image, the capture process fails instead of recording an empty review.

Before inspecting a supplied raster for acceptance or integrating it, follow `AGENTS.md`, [Notes/ASSET_GENERATION_RULES.md](Notes/ASSET_GENERATION_RULES.md), and [Notes/UI_ASSET_INVENTORY_PT.md](Notes/UI_ASSET_INVENTORY_PT.md). Raw study references never enter production exports.

## Exports

Build and smoke-test Windows:

```powershell
.\tools\check_windows_export.ps1
```

Build and inspect the ARM64 Android test APK:

```powershell
.\tools\check_android_export.ps1
```

Publish a newly verified APK to the stable internal-testing release:

```powershell
.\tools\publish_android_latest.ps1
```

Permanent team-test links:

- APK: <https://github.com/jellycb1/crooked-galaxy/releases/download/latest/CrookedGalaxy.apk>
- SHA-256: <https://github.com/jellycb1/crooked-galaxy/releases/download/latest/CrookedGalaxy.apk.sha256>

The ignored local test key preserves update compatibility for direct installs and must never be reused for a store release. Store distribution requires a separate private signing workflow and server-authoritative billing infrastructure.
