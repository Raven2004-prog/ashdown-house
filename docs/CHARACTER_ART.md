# Ashdown Character Art Slice

Phase 8 replaces the close-camera capsule and Main Hall doll spheres without
changing the gameplay bodies underneath them.

## Investigator

- Obscured adult silhouette: dark coat, boots, hat, satchel, and lantern.
- The visible model is scaled to `0.84`; the `CharacterBody3D` collision remains
  unchanged so doors, camera compression, and interaction distances keep their
  tested behavior.
- Animation is intentionally sampled at 10 frames per second. Locomotion and
  interaction poses are driven by `InvestigatorVisual`, not by the level script.
- Implemented poses: idle, walk, sprint, crouch, inspect, pickup, door, valve,
  lantern raise, stumble, and ending.
- Footstep events are emitted from stepped locomotion and are ready for Phase 9
  surface audio.

## Dolls

The seven doll visuals are authored in `MainHallContent.tscn` and bind to the
existing persistent interaction IDs. Their positions and `Area3D` collisions are
unchanged.

- Mira: faded red cloth, red ribbon, reaching arms, face crack.
- Leela: violet cloth, seated pose, missing left shoe, covered-mouth posture.
- Arun: dark-blue coat, brass star, upward-leaning posture.
- Dev: mustard cloth, kneeling posture, soot hands, train wheel.
- Sana: washed teal cloth, extended folded cloth, whistle cord.
- Kabir: moss cloth, crouched posture, blue marble, scraped knee.
- Nila: uncoloured cloth, blank tag, seven beads, raised counting hand.

The old sphere meshes are removed by authored-anchor binding at startup. Debug
labels remain available through `F3`, but they are not part of normal presentation.
