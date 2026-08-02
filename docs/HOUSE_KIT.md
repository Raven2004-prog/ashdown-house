# Ashdown House Kit

The Vestibule and Main Hall establish the reusable authored-room language for the
rest of Ashdown House. Permanent room content is serialized in `.tscn` scenes and
is visible in Godot's 3D editor. The generated blockout remains responsible for
route collision until each room slice replaces it deliberately.

## Shared Language

- Architecture: 3.4 m shell, smoke-green lower panels, aged ivory upper walls,
  dark walnut skirting and picture rails, and worn dark timber floors.
- Furniture: walnut structure, worn oak contact surfaces, tarnished brass,
  blackened iron, aged paper, and restrained dusty fabric.
- Lighting: warm practical pools define routes; cool fill marks exits and service
  routes; fire-state light adds low orange pressure without recoloring the UI.
- Interactions: authored props retain the persistent IDs from level data through
  `ashdown_interaction_anchor` markers. Collected props hide immediately.
- Atmosphere: room-local state controllers react to level flags. They never own
  puzzle progression or checkpoint data.

## Authored Scenes

- `VestibuleContent.tscn`: door and chain, reception table, lantern, torn plan,
  waiting furniture, coat storage, trim, fixtures, and three interaction anchors.
- `MainHallContent.tscn`: cradle, register lectern, alarm assembly, benches,
  consoles, memorial frames, chandelier, wall sconces, soot, smoke, fire glow,
  and four interaction anchors.

Future room slices should use the same five branches: `Architecture`, `Furniture`,
`InteractionAnchors`, `Lighting`, and `Atmosphere`.
