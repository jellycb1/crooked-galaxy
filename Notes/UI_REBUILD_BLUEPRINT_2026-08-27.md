# UI reconstruction blueprint

Status: prepared for implementation. This document replaces the assumption that the current dashboard composition can be fixed through spacing and decoration alone.

## Honest diagnosis

The current interface is functionally broad but visually wrong for the intended game. At the 450x800 Android target it compresses labels, progress bars, currencies, selectors, tutorial copy and the main action into the upper half of the screen while leaving the lower scene unused. It reads as a telemetry dashboard rather than a humorous illustrated space RPG.

The technical reason reinforces the visual diagnosis: the logical canvas is 720x1280 and is shown at 450x800, a scale of 0.625. A 9-13 px logical label becomes roughly 6-8 physical pixels. A 46-64 px logical button becomes roughly 29-40 physical pixels. Those measurements cannot be rescued by a more attractive frame.

## Non-negotiable reconstruction rules

1. Every screen is a scene, not a stack of cards.
2. One visual subject dominates the stage: target, hunter, item, transport, planet or duel.
3. The default screen exposes one primary decision and at most three simultaneous primary choices.
4. Supporting information is grouped into no more than three visible surfaces. Detail, tutorial and history move to a secondary sheet.
5. No runtime text is smaller than 18 logical pixels; ordinary body text starts at 21.
6. No touch action is shorter than 72 logical pixels; primary actions use 88.
7. Navigation uses stable large destinations and never competes with the current subject.
8. Decorative borders identify focal objects only. Repeated rows use quiet surfaces rather than nested frames.
9. Cyan, gold, coral and lime communicate meaning. They are not simultaneous decoration.
10. Every migrated screen is captured and judged at 450x800 before the next screen begins.

## Canonical mobile shell

The rebuild keeps the 720x1280 logical canvas and reserves four explicit regions:

- identity header: at most 112 logical pixels;
- illustrated stage: the flexible central region and largest area;
- contextual actions: attached to the stage, not a detached dashboard;
- primary navigation: 104 logical pixels including safe-area breathing room.

The reusable measurements live in `scripts/ui_design_system.gd`. Rebuilt screens use `scene_title`, `readable_body`, `readable_caption`, `primary_action`, `secondary_action` and `focal_scene_panel` from `scripts/ui_factory.gd`. Existing screens intentionally remain unchanged until migrated, avoiding an uncontrolled global reflow.

## First vertical slice: Caçadas

The current board is the correct first reconstruction because it is the repeat loop and currently demonstrates every failure at once.

### Default state

- Compact header: hunter portrait/name/level on the left; currencies behind one ledger action on the right.
- Large target stage: target portrait or documented placeholder, name, planet and one concise danger/reward line.
- Three mission offers: presented as large selectable posters/tickets. Only the selected offer expands; none carries paragraph text.
- Primary action: `ANALISAR ABORDAGENS` directly beneath the selected target.
- Secondary detail sheet: tutorial, mastery, exact probability, travel breakdown and extended rewards.
- Bottom navigation: large icon and readable label; no 9 px captions.

### Information removed from the default board

- full tutorial sentences;
- multiple resource rows;
- detailed mastery explanation;
- exact travel decomposition;
- repeated status labels already expressed by color or selection;
- decorative progress bars without an immediate decision attached.

Nothing is deleted from the game systems. It is moved behind deliberate detail access.

## Migration order

1. Caçadas default board and briefing.
2. Caçador: character, equipment and attributes as one readable scene.
3. Arsenal and inventory using the same universal slot layout for every class.
4. Hangar with transport as the main illustrated subject and travel savings as the payoff.
5. Combat, victory and rewards.
6. Login and character creation.
7. Galaxy, career, market, settings and secondary ledgers.

## Acceptance gate for each screen

- captured at exactly 450x800;
- readable without zoom;
- primary action identifiable in under two seconds;
- minimum touch targets pass the design-system checks;
- no more than three visible support surfaces;
- no major empty region unless it contains or frames the visual subject;
- consistent with “clean, organized, 2D space RPG, Shakes & Fidget inspired” at the level of hierarchy and playfulness, without copying protected artwork;
- no new raster asset enters runtime without the mandatory `ASSET_GENERATION_RULES.md` approval gate.

## Explicitly rejected direction

Do not continue the current pattern of adding another compact label, chip, progress strip or bordered card whenever a system needs exposure. Functional completeness is not permission to display every datum simultaneously. The game state may remain deep; the default view must remain simple.
