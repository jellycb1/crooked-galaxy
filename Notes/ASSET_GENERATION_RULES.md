# Visual asset generation gate

Status: mandatory. A generated image is a draft until the user explicitly approves the exact image and its direction.

## Why this gate exists

The first generated class trio was technically clean but visually wrong. It turned the intended humorous, caricature-led 2D RPG into serious semi-realistic tactical concept art. The work was integrated and published before the mismatch was challenged. This gate prevents that failure from recurring.

## Reference diagnosis

Relevant character, registration, tavern, and monster references consistently use:

- an immediately readable face, emotion, or comic attitude;
- exaggerated anatomy and intentionally uneven proportions;
- large silhouette-defining props and gestures;
- thick, confident dark contours and broad internal shapes;
- saturated color groups with simple, readable light and shadow;
- asymmetry, imperfection, personality, and visual jokes;
- enough detail to reward inspection without losing the character at phone size.

The rejected class trio instead used sealed helmets, near-realistic anatomy, military symmetry, dark tactical clothing, dense material scratches and rivets, anonymous poses, and dramatic concept-art lighting. It belongs to a different game.

## Required workflow

### 1. Establish evidence

Before composing a prompt:

1. Inspect at least three task-relevant images under `references/` with the image viewer.
2. Inspect at least one current in-game capture or accepted production asset in its real UI context.
3. Record a short style delta: what the references do, what the current game needs, and what the draft must avoid.
4. Decide the asset's actual on-phone display size and composition before choosing source dimensions.

Words such as `comic`, `cel shaded`, `space western`, `hand-painted`, or `inspired` are not a sufficient art direction by themselves.

### 2. Generate one draft

- Generate only one representative vertical-slice image, never a trio or content batch.
- Keep drafts outside `assets/` and all runtime resource paths.
- Do not change scripts, tests, import settings, release versions, or APK contents for an unapproved draft.
- Display the draft to the user next to a concise style assessment.
- Earlier generic permission to use or generate assets does not count as approval of a new visual direction.

### 3. Require explicit approval

Only the user's explicit approval of the displayed draft unlocks expansion. Approval of a concept, prompt, class name, or autonomous batch is not approval of an unseen image.

After approval, create at most the next coherent set in the approved language. If a later result drifts, stop the set and return to one draft.

### 4. Validate before integration

An approved image still must pass:

- transparent-alpha and edge inspection when applicable;
- silhouette readability at approximately 96-120 px character height;
- a physical 450x800 capture in its intended screen;
- legibility beside the real text, controls, and background;
- memory/import limits appropriate to its maximum display size;
- originality checks: no logos, text, franchise shapes, copied characters, or recognizable third-party designs.

Only then may it enter `assets/`, runtime code, automated pack tests, a commit, or an APK.

## Hard rejection checklist

Reject a draft if one or more major items apply:

- photorealistic or semi-realistic game concept art;
- generic tactical operator, space marine, or premium mobile sci-fi look;
- sealed helmet or hidden face used merely to avoid choosing a species;
- realistic heroic anatomy without comic exaggeration;
- symmetrical mannequin pose with no visible attitude;
- dense scratches, buckles, rivets, cables, or material noise carrying the design;
- muted military palette dominated by black, grey, and brown;
- cinematic glow or fog replacing clean shape separation;
- tiny props that cannot communicate class at phone size;
- polished rendering whose humor, silhouette, or personality does not match the references.

## Character acceptance target

A class or character illustration should normally have:

- a visible, expressive face or a deliberately expressive non-human equivalent;
- caricatured proportions and a memorable outline;
- one oversized class-defining prop, gesture, or costume mass;
- approximately four to six principal color groups;
- broad highlights and one or two clear shadow steps;
- strong contour hierarchy and restrained internal texture;
- an asymmetric detail or comic imperfection;
- a pose that tells a small story without UI text.

Class promotional art may use a representative species. It does not need to be species-neutral and must not be presented as the player's literal avatar. Player identity remains the job of the modular character portrait.

## Prompt construction rule

Prompts must describe the abstract visual grammar rather than request imitation of a named franchise. Include the subject's facial attitude, comic proportion, silhouette, major prop, restricted palette, contour treatment, shading simplicity, phone-size readability, transparent/background requirement, and the hard-rejection traits.

## Current decision

The three class images introduced in versions 0.34.0-0.35.0 are rejected and must not be used as style anchors. They are recoverable from Git history only for comparison and postmortem purposes.

