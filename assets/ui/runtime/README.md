# Core UI runtime assets

Source: `Art Style Crooked Galaxy/ui/core/runtime` supplied by the project owner on 2026-08-30.

The PNG files in this directory are byte-identical copies of the reviewed source candidates. Runtime adaptation is handled in Godot code through 9-slice margins, minimum-size gates and procedural fallbacks; the source artwork has not been flattened or overwritten.

Integration contracts:

- confirmation modal: margins 64/56/64/56;
- success receipt: margins 72/64/72/64 with a navy fill behind the transparent opening;
- tooltip: margins 64/36/40/48, presented through the Android long-press layer;
- selected tab: margins 44/24/44/20;
- rarity frames: external artwork is used only at 72 physical pixels or larger; smaller equipment icons retain the procedural frame;
- portrait frames: external artwork is used only at 106 physical pixels or larger; smaller portraits retain the procedural frame;
- rarity tier 2 remains reserved for a future Uncommon tier.

All assets must continue to be checked in a 450×800 capture before APK publication.

Intake status for the 26-file source batch:

- 16 supplied assets are integrated (the 14 files here plus the dossier and supporting frames in the parent folder);
- the four painted button faces, danger panel and two opaque divider variants remain rejected and outside runtime export;
- checkbox, radio and toggle candidates remain outside runtime because they provide only one state each; these controls use the matching code-native state system instead.
