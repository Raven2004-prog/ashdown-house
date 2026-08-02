# Ashdown House Project Guide

## Identity

- Project: Ashdown House
- Engine: Godot 4.7.x
- Genre: third-person 3D pixel-horror investigation
- Active scene: `res://scenes/levels/ashdown/AshdownLevel.tscn`
- Authoritative design: `C:/Users/kusha/Downloads/Ashdown House_ Complete Three-Dimensional Pixel-Horror Level Plan.pdf`

The newer Ashdown House PDF supersedes earlier Ash Dormitory, Burning Nursery, and Ashdown Children's Home documents when they conflict. The omitted seventh child is Nila.

## Stable Baseline

- Keep the internal viewport at 640 x 360.
- Preserve fullscreen, viewport stretch, aspect keep, integer scaling, and nearest-style filtering.
- Preserve `CharacterBody3D`, `SpringArm3D`, camera-centred interaction, nearby line-of-sight fallback, and UI input locking.
- Extend the existing InventoryManager, JournalManager, LevelStateController, InteractionManager, and CheckpointManager rather than consolidating gameplay back into one script.
- Keep progression evidence separate from optional environmental observations.
- Preserve persistent placement IDs when replacing blockout props with authored scenes.

## Current Milestone

The Library is the scale benchmark and lives in `res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn`. Its architecture, furniture, collisions, lights, atmosphere, and interaction anchors are serialized editor-visible nodes. `library_benchmark.gd` controls only gameplay state such as the sliding shelf; it must not rebuild permanent geometry at runtime.

Other rooms remain functional blockouts until the Library scale and camera presentation are accepted.

## Next Work

1. Convert the remaining generated house blockout into an editor-visible scene while preserving placement IDs.
2. Remove obsolete permanent-geometry construction and add authored-content validation.
3. Lower the visible player/camera presentation slightly.
4. Raise the Library ceiling, correct shifted props, and confirm D03-D05 traversal.
5. Manually play the catalog, desk, shelf, hidden-clue, and classroom-key sequence before authoring the next detailed room.

## Verification

Run a normal project launch and the Library benchmark self-test after relevant changes. The self-test command-line argument is `--library-benchmark-self-test`. Use `F3` for temporary floating debug labels; normal play should not show them.

Do not commit `.godot`, `art/_staging`, generated captures, exported builds, or backup archives.
