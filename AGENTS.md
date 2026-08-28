# Crooked Galaxy repository instructions

## Mandatory visual-asset gate

Before generating, editing, accepting, or integrating any raster visual asset, read
`Notes/ASSET_GENERATION_RULES.md` completely and follow it as a release gate.

These rules override broad or earlier permission to generate assets autonomously:

- Inspect at least three relevant local reference images and one current in-game capture or production asset before writing a prompt.
- Write down the specific reference traits being preserved and the traits being rejected. Style labels alone are not evidence.
- Generate one draft only. Store it outside runtime asset folders and treat it as rejected by default.
- Never expand a visual draft into a set, move it into `assets/`, wire it into runtime, commit it as production art, export it in an APK, or publish it until the user has seen that exact draft and explicitly approved its visual direction.
- After approval, validate the asset at the intended 450x800 Android presentation size and against the rejection checklist before integration.
- If any major rejection condition applies, reject the draft. Do not justify a mismatch because the file is technically polished.

Existing reference assets may be used as documented internal placeholders, but they must not be confused with newly approved original production art.

## Visual asset authorship boundary

Codex must not generate, draw, paint, edit, transform, or create visual assets for
this project. Visual assets are supplied by the user or an external artist.

Codex may:

- inventory and specify required assets;
- prepare code-native placeholders and procedural fallbacks;
- define filenames, dimensions, anchors, masks, budgets, and import contracts;
- inspect a supplied asset and report whether it meets the visual and technical gate;
- integrate an exact user-supplied asset only after the user asks for integration.

Preparing UI code, vector-like Godot drawing, layout, shaders, validation tools, and
asset manifests is not permission to create substitute production artwork. If an
implementation reaches a missing visual asset, preserve the existing fallback and
record the missing deliverable instead of generating it.
