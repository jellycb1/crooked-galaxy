# UI identity completion audit — 2026-08-26

## Status

Archived completion snapshot. It records the 2026-08-26 validation pass; current visual authority lives in `VISUAL_DIRECTION.md`, `UI_ASSET_INVENTORY_PT.md`, and the executable UI tests.

No new raster was generated in this pass. The explicitly approved `assets/ui/panel_frame_space.png` is reused as a 9-slice focal frame, while supporting components remain code-native.

## Enforced hierarchy

| Layer | Visual contract | Current coverage |
| --- | --- | --- |
| Focal dossier | Near-black navy center, blue-steel lip, aged-brass inner line, restrained cyan/coral corner fittings | Login and character-creation previews, selected mandate, briefing target, hunter profile, class detail, universal equipment sheet, active transport, incident, victory, normal/Rift reward, chapter conclusion, career summary, Rift state |
| Bespoke focal surface | Dark technical field with a material brass boundary | Automatic-combat arena; the battle visualization remains unobscured by the illustrated frame |
| Supporting card | Semantic navy/tint with one-pixel steel edge | Route choices, attributes, inventory, transports, market stock, settings, receipts, alerts, progress and archive rows |
| Primary action | Solid semantic color, dark readable copy, bounded dark edge | Confirmation, contract entry, reward claim and chapter continuation |
| Secondary action | Calm navy surface with two-pixel semantic edge | Back, compare, edit, filter, transaction and optional incident actions |
| Persistent navigation | Navy structure with aged-brass shell; color belongs to icon and active edge | Five-destination Android dock across all gameplay hubs |

## Screen-family result

- Mandatory entry: login, class, species, appearance and name use one preview dossier and fixed confirmation.
- Core loop: three compact offers control one selected mandate; briefing, hunt, optional incident, combat, victory and reward each preserve a single dominant decision surface.
- Character and equipment: hunter, class, arsenal, inventory, loadouts, market and hangar distinguish identity panels from repeated management rows.
- Long-term progression: galaxy, career, wanted archive, Fenda, defeat recovery, chapter conclusions, AFK return and save recovery retain the same palette and component roles.
- Preferences and service menus intentionally use supporting cards rather than ornamental focal frames.

## Physical and automated evidence

- `tools/capture_ui.gd` currently produces 99 reachable UI-state captures; `tools/capture_portraits.gd` owns the separate portrait diagnostic sheet.
- The generated directory contains 100 `ui_*.png` files and every file is exactly 450×800.
- The capture tool removes the obsolete `ui_arsenal_settings.png` artifact from the former prototype settings surface without deleting unrelated captures.
- PT/EN rendering, 125% text expansion, mobile safe areas, scrolling, Android Back, focus restoration and touch targets remain covered by the project suite.
- Focal identity is asserted as `StyleBoxTexture` in renderer/integration tests. The combat arena separately asserts its two-pixel material edge.
- A local 32.02 MB ARM64 inspection APK included the approved UI frame and required original art, excluded proprietary study references, and passed package/version/API/signature validation. That regenerable inspection artifact is intentionally not retained.

## Performance result

- Identical support, button, illustrated-frame and navigation styles now share immutable `StyleBox` resources for the lifetime of the UI host.
- The selected Galaxy destination duplicates its shared style before applying a destination-specific border, preventing cache contamination.
- In the local first-visit profiler, representative Arsenal entry improved from approximately 27.1 ms to 24.4 ms. The cold Market sample improved from approximately 36.1 ms to the 29.5–31.0 ms range. Normal warm hub renders remain around one interaction frame or below on this desktop profile.
- Combat estimates, background decode and transactional persistence remain the larger one-time/mobile variables. Their existing caches, incremental warmup and atomic guarantees are unchanged.

## Remaining physical-only checks

The code and capture gate is complete. A physical Android session should still compare first and repeated entry into Arsenal, Market and Career; exercise long translated names with the device font stack; and verify that touch feedback feels immediate under real thermal/storage conditions. These checks may tune timing or density but do not reopen the visual hierarchy unless they expose a concrete failure.
