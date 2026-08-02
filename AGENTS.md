# Ashdown House Project Guide

## Identity

- Project: Ashdown House
- Engine: Godot 4.7.x
- Genre: third-person 3D pixel-horror investigation
- Active scene: `res://scenes/levels/ashdown/AshdownLevel.tscn`
- Authoritative design: `C:/Users/kusha/Downloads/Ashdown House_ Complete Three-Dimensional Pixel-Horror Level Plan.pdf`

The newer Ashdown House PDF supersedes earlier Ash Dormitory, Burning Nursery, and Ashdown Children's Home documents when they conflict. The omitted seventh child is Nila.

## Stable Baseline

- Use a 1280 x 720 root viewport with native-resolution CanvasItem UI.
- Render the 3D world independently with nearest scaling. Balanced is 0.5, Performance is 0.3333, and Native is 1.0.
- Preserve fullscreen, 16:9 presentation, and nearest-style filtering for pixel-textured assets.
- Preserve `CharacterBody3D`, `SpringArm3D`, camera-centred interaction, nearby line-of-sight fallback, and UI input locking.
- Extend the existing InventoryManager, JournalManager, LevelStateController, InteractionManager, and CheckpointManager rather than consolidating gameplay back into one script.
- Keep progression evidence separate from optional environmental observations.
- Preserve persistent placement IDs when replacing blockout props with authored scenes.

## Current Milestone

The Library is the scale benchmark and lives in `res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn`. Its architecture, furniture, collisions, lights, atmosphere, and interaction anchors are serialized editor-visible nodes. Imported furniture remains instanced from its source scenes to avoid nested-node naming collisions. `library_benchmark.gd` controls only gameplay state such as the sliding shelf; it must not rebuild permanent geometry at runtime.

The complete house blockout is serialized in `res://scenes/levels/ashdown/AshdownHouseBlockout.tscn` and instanced by the main level. Room floors, walls, blockers, doors, dolls, clue markers, labels, and collisions are visible in the editor. Other rooms remain visually simple blockouts until the Library scale and camera presentation are accepted.

The editor-authored conversion is complete through Phase 5. The player's visible placeholder is lowered independently of its collision body, and the Library uses a 4.2 m visual shell with ceiling fixtures and lights aligned to the raised ceiling. Permanent geometry must remain editor-authored; runtime scripts are controllers and validators only.

## Current Production Direction

Ashdown is moving toward an HD-2D-inspired pixel-horror presentation: authored low-poly 3D rooms, pixel-controlled materials, native-resolution interface text, modern lighting, and restrained effects. This is an original visual language and must not copy proprietary assets or compositions.

Blender source files live in `assets/source/blender`; approved exports live under `assets/hd2d`. Follow `docs/ASSET_PIPELINE.md` and `docs/ART_BIBLE.md` for naming, scale, collision, texture, and lighting rules.

## Next Work

1. Establish sharp native-resolution UI and independent nearest-scaled 3D rendering.
2. Replace the Library prototype kit with the final benchmark asset set.
3. Propagate the accepted shared kit room by room without changing persistent gameplay IDs.
4. Build player, dolls, sound, fire VFX, and release lighting in their dedicated phases.

## Verification

Run a normal project launch and the Library benchmark self-test after relevant changes. The self-test command-line argument is `--library-benchmark-self-test`. Use `F3` for temporary floating debug labels; normal play should not show them.

Do not commit `.godot`, `art/_staging`, generated captures, exported builds, or backup archives.
