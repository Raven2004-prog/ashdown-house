# Ashdown Audio System

Phase 9 establishes the complete routing and gameplay contract for sound.

## Buses

- Master
- Music
- Ambience
- SFX
- UI
- Voice

Every bus has a persistent linear volume setting. The native-resolution pause
panel exposes all six levels plus master mute. Essential dialogue remains in
subtitles and never depends on the Voice bus.

## Runtime Layers

- Continuous house tone changes pitch by room.
- Fire pressure fades in after the register and intensifies with smoke.
- Boiler machinery is positional and stops after shutdown.
- Footsteps choose wood, tile, or metal from the player's room coordinates.
- Doors, paper, puzzle confirms, the alarm, whispers, smoke surges, and release
  use short positional or interface cues.
- Investigator animation emits the footstep events. Room and puzzle scripts do
  not own audio players.

The current cue set is project-original and procedurally synthesized by
`AudioManager`. These restrained placeholders are safe to replace with approved
recordings later because interaction code addresses cue IDs rather than files.

## Future Recording Manifest

Any imported recording must add its asset name, creator, source URL, license,
modifications, and cue ID to `docs/CREDITS.md`. Full voice acting remains outside
the first release scope; positional whispers can be replaced independently.
