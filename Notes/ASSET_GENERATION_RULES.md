# Visual asset intake gate

Status: mandatory for creating, altering, accepting or integrating raster art. The legacy filename is retained because repository instructions and tooling already reference it.

`AGENTS.md` is authoritative: the project owner authorizes Codex to create, edit, transform, retouch, resize, remove backgrounds from, optimize and integrate visual assets. This document governs how that authorization is exercised safely and consistently.

## Why this gate exists

The first generated class trio was technically clean but visually wrong. It turned the intended humorous, caricature-led 2D RPG into serious semi-realistic tactical concept art and entered runtime before the mismatch was challenged. A polished file is not acceptable merely because it is technically valid.

## Visual evidence

Relevant character, registration, tavern and monster references consistently use:

- an immediately readable face, emotion or comic attitude;
- exaggerated anatomy and intentionally uneven proportions;
- large silhouette-defining props and gestures;
- thick, confident dark contours and broad internal shapes;
- saturated color groups with simple, readable light and shadow;
- asymmetry, imperfection, personality and visual jokes;
- enough detail to reward inspection without losing the subject at phone size.

The rejected class trio instead used sealed helmets, near-realistic anatomy, military symmetry, dark tactical clothing, dense material scratches and rivets, anonymous poses and dramatic concept-art lighting. It belongs to a different game and must not be used as a style anchor.

## Required intake workflow

### 1. Establish evidence before judging a candidate

1. Inspect at least three task-relevant images under `References/`.
2. Inspect at least one current 450×800 capture or accepted production asset in its real UI context.
3. Record a short style delta: traits to preserve, traits to reject and the role the new asset must perform.
4. Record the intended on-phone display size, crop, anchor points, transparency requirement and import budget.

Labels such as `comic`, `cel shaded`, `space western`, `hand-painted` or `inspired` are not sufficient evidence by themselves.

### 2. Review a candidate or identified batch

- Prove a new visual direction with one representative file before processing a large batch. Once the direction is established, an identified batch may be reviewed and processed together.
- Keep the candidate outside `assets/` and all runtime paths.
- Treat it as unapproved until its evidence and intended role are recorded.
- Show or identify the exact candidate being assessed and report concrete matches and mismatches.
- Preserve the original candidate or a reproducible source before destructive edits.

### 3. Establish integration authority

A direct request to process a named file, folder, archive or reviewed batch permits creation, correction and runtime integration within that scope. Standing authorization may cover subsequent technical variants derived from those files.

Codex may crop, recolor, retouch, composite, repair transparency, resize, optimize and create derived states. Material visual changes must be documented, and the untouched source must be retained outside the runtime path or remain reproducible from version history.

### 4. Validate before integration

The supplied candidate must pass:

- file integrity, format and alpha inspection where applicable;
- silhouette readability at its intended 96–160 px presentation size;
- a real 450×800 capture in the target interface;
- legibility beside localized text, controls and background;
- correct crop, anchors, masks and occlusion behavior;
- memory/import limits appropriate to maximum display size;
- absence of embedded text, logos, watermarks, franchise shapes or recognizable third-party designs;
- the rejection checklist below.

Only then may the exact supplied asset enter `assets/`, runtime code, pack tests, a commit, an APK or a published build.

## Hard rejection checklist

Reject a candidate if one or more major items apply:

- photorealistic or semi-realistic game concept art;
- generic tactical operator, space marine or premium-mobile sci-fi appearance;
- sealed helmet or hidden face used merely to avoid choosing a race;
- realistic heroic anatomy without comic exaggeration;
- symmetrical mannequin pose with no visible attitude;
- dense scratches, buckles, rivets, cables or material noise carrying the design;
- muted military palette dominated by black, grey and brown;
- cinematic glow or fog replacing clean shape separation;
- tiny props that cannot communicate the role at phone size;
- polished rendering whose humor, silhouette or personality does not match the project;
- technical defects that cannot be repaired without destroying the intended design or provenance.

## Character acceptance target

A class or character illustration should normally have:

- a visible expressive face or deliberately expressive non-human equivalent;
- caricatured proportions and a memorable outline;
- one oversized class-defining prop, gesture or costume mass;
- approximately four to six principal color groups;
- broad highlights and one or two clear shadow steps;
- strong contour hierarchy and restrained internal texture;
- an asymmetric detail or comic imperfection;
- a pose that tells a small story without UI text.

Class promotional art may use a representative race. It is not the player's literal avatar; personal identity remains the job of the modular portrait.

## External art brief rule

Codex may specify or create an asset using abstract visual grammar: role, facial attitude, comic proportion, silhouette, major prop, restricted palette, contour treatment, shading simplicity, phone-size readability, file format, transparency, anchors and rejection traits. The brief or generation request must not request imitation of a living artist or a named franchise's exact protected style.

## Current decision

The three class images introduced in versions 0.34.0–0.35.0 remain rejected. Git history retains them only for postmortem comparison. Vector class emblems remain the intentional fallback until externally supplied replacements pass this gate.
