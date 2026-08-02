# Ashdown Release Polish

Phase 10 completes the first integrated production pass.

## Presentation

- Four room-local fire/smoke systems respond to the global fire phase and the
  classroom, kitchen, and boiler shutdown flags.
- Pressure drives smoke density while the existing native UI remains readable.
- Main Hall release wisps and cool light activate only when Nila is placed.
- Three restrained cool shafts add depth and obey the atmospheric-fog setting.
- Particle counts follow Performance, Balanced, and Native quality presets.
- Camera beats accompany fire, rejection, and release, and can be disabled with
  Reduce camera motion. Flicker can independently be disabled.

## Release Flow

- The title offers New Investigation, Continue from Checkpoint, Settings,
  Credits and Licenses, and Quit.
- Checkpoints persist as Godot Variant data in `user://ashdown_checkpoint.cfg`.
- Pause includes Resume and Main Menu.
- A Windows Desktop export preset writes to `builds/AshdownHouse.exe` when export
  templates are installed.

## Scope

This is the complete functional and presentation pipeline for the current
blockout/art-pass release. It does not claim final commissioned character art,
full voice acting, or a cinematic rendered ending. Those can replace the stable
interfaces established here without changing puzzle progression.
