# Crooked Galaxy visual direction

## Promise

Crooked Galaxy is a clean, organized 2D space RPG with the immediacy and character-led readability of a browser comic RPG. It should feel handmade, crooked, funny, and adventurous rather than sterile, photorealistic, or like a generic neon dashboard.

The interface is the frame around a cast of memorable hunters, targets, merchants, vehicles, and locations. Large illustrated personalities carry fantasy; compact technical UI carries decisions.

## Three visual layers

1. **Illustrated fantasy** — bold ink, caricatured proportions, flat color blocks, two-step cel shading, restrained material texture, strong silhouettes.
2. **Frontier setting** — painterly scrap-built environments with warm practical lights, deep navy shadows, and readable quiet space beneath UI.
3. **Interface system** — dark blue panels, cyan navigation, gold identity and rewards, lime confirmation, coral danger. Panels stay organized, compact, and secondary to the illustrated subject.

These layers may differ in detail, but they must share navy shadows, warm worn metals, cyan technology, and visible imperfection.

## Character rules

- A character must remain recognizable at roughly 120 px tall.
- Silhouette communicates class before small equipment details do.
- Anatomy may be caricatured, but poses and held objects remain readable.
- Clothing and armor are patched, asymmetrical, worn, and practical.
- Faces or visors need one clear emotional read; avoid blank mannequin poses.
- Use one dominant hue, one supporting hue, and one restrained luminous accent.
- No embedded text, insignia, franchise shapes, or ornamental detail that disappears on a phone.

Class illustration and personal avatar have different jobs. Class art sells an archetype and stays species-neutral where possible. The modular portrait shows the player's chosen race, appearance, and equipped items. A fixed class illustration must never replace personal identity in the hunter sheet.

## Class silhouette targets

- **Quebra-Mandados** — low center of gravity, broad armor mass, breach tool or reinforced gauntlets, coral danger accent.
- **Pistoleiro Orbital** — tall coat-and-hat silhouette, visible sidearm, agile asymmetry, mustard gold and cyan targeting accent.
- **Hacker de Contratos** — narrow layered silhouette, articulated tech rig, projected intrusion tools, cyan with acidic lime accent.

The Orbit Gunslinger established the production vertical slice. Warrant Breaker and Contract Hacker now complete the initial trio at the same runtime scale: broad/coral, tall/gold and narrow/cyan silhouettes remain distinguishable before details are read. Vector emblems remain intentional fallbacks for future classes or unavailable raster resources.

## UI composition

- One dominant illustrated subject per screen region.
- One primary action per screen; secondary actions use outlined treatment.
- Keep persistent navigation predictable and keep long information inside scrollers.
- Prefer a clear dossier with grouped facts over many equally weighted chips.
- Use environment art as atmosphere, not as a competitor for text.
- At 450×800 physical captures, primary labels, character silhouette, and action must remain identifiable without zooming.

## Asset and performance contract

- Runtime art is original production content; study references stay outside runtime.
- Portrait textures use alpha, no baked panel or background.
- Imported raster art is capped to the smallest resolution that survives its maximum display size; the current class slice is capped at 1024 px on its longest edge.
- Load large class art only on screens that display it, reuse Godot's resource cache, and keep procedural/vector fallbacks.
- New art enters one vertical slice first, is captured on the 720×1280 logical viewport, and must pass mobile layout, text resilience, and Android pack checks before expansion.
