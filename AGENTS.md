# Crooked Galaxy repository instructions

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

## Mandatory supplied-asset gate

Before accepting or integrating any user- or artist-supplied raster asset, read
`Notes/ASSET_GENERATION_RULES.md` completely and follow its intake gate.

- Inspect at least three relevant local references and one current in-game capture or production asset.
- Record the concrete traits to preserve and reject; style labels alone are not evidence.
- Review one supplied candidate at a time and treat it as rejected by default.
- Never modify or expand a supplied candidate. Never wire, commit, export, or publish it until the user explicitly asks to integrate that exact file.
- Validate approved files at the intended 450×800 Android presentation size and against the rejection checklist.
- Reject major visual or technical mismatches even when the source file is polished.

Existing reference assets may be consulted locally or used as documented internal
placeholders when explicitly required. They must remain distinguishable from
production art and outside Git and runtime exports under the current reference
boundary.
