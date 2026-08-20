# Ashdown House

Ashdown House is a third-person 3D pixel-horror investigation game built with Godot 4.7. The player explores a fire-damaged children's home, connects environmental evidence to seven dolls, and reconstructs the identity of an omitted child.

The project is currently a playable mechanics and scale prototype. The Library is the first handcrafted room benchmark; the remaining rooms still use functional blockout geometry.

## Current Build

- Third-person `CharacterBody3D` movement with sprinting and crouching.
- Close spring-arm camera with camera-centred interaction targeting.
- Eight-room Ashdown House blockout with persistent doors and progression flags.
- Data-driven dolls, clues, puzzles, journal entries, and inventory evidence.
- Library catalog and sliding-shelf investigation sequence.
- Handcrafted 16 x 14 metre Library benchmark with full-height architecture, shelf aisles, reading area, lighting, optional inspections, and authored interaction anchors.
- Fullscreen 640 x 360 internal rendering with integer scaling and nearest-style 3D materials.
- Mechanics self-test for Library progression and collected-prop cleanup.

## Controls

- `WASD`: move
- Mouse: camera
- `Shift`: sprint
- `Ctrl`: crouch
- `E`: interact
- `J`: journal
- `Esc`: release mouse or close an overlay
- `F3`: toggle debug labels

## Run

1. Open this folder in Godot 4.7.x.
2. Run the project.
3. The active scene is `res://scenes/levels/ashdown/AshdownLevel.tscn`.

The Godot executable is not included in the repository.

## Project Structure

- `scenes/levels/ashdown/`: active house and authored room scenes.
- `scripts/`: player, interaction, level-state, journal, inventory, and checkpoint systems.
- `data/levels/level_ashdown_house.json`: room, door, doll, and placement data.
- `assets/`: approved active 3D assets and materials.
- `art/approved/`: small retained art set from earlier prototypes; unused source packs and staged downloads are ignored.
- `docs/ASHDOWN_LEVEL.md`: implementation notes.
- `docs/CREDITS.md`: third-party asset and licence ledger.

