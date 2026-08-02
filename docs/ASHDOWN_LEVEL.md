# Ashdown House

Source design: `C:/Users/kusha/Downloads/Ashdown House_ Complete Three-Dimensional Pixel-Horror Level Plan.pdf`.

This milestone migrates the active 3D prototype from the earlier Ashdown Children Home blockout to the Ashdown House design. The new PDF is the source of truth where it conflicts with older documents. The omitted seventh child and final anchor is Nila.

Core baseline:

- Godot 4.7.x.
- HD-2D-inspired 3D pixel-horror presentation.
- `1280 x 720` native interface with independently nearest-scaled 3D world rendering.
- World presets: Performance `0.3333`, Balanced `0.5`, and Native `1.0`.
- One Godot unit equals one metre.
- `+X` is east, `-X` is west, `+Z` is north, `-Z` is south, `+Y` is up.
- Third-person player uses `CharacterBody3D`.
- Camera uses `SpringArm3D`.
- Interaction uses a camera-centred ray plus a forgiving nearby target fallback.

Current playable milestone:

- Primitive Ashdown House map: Vestibule, Main Hall, Library, Classroom, Dormitory, Boiler/Records, Bathroom/Laundry, Kitchen.
- D01-D11 door placements and requirement text.
- Seven new dolls: Mira, Leela, Arun, Dev, Sana, Kabir, Nila.
- Register trigger starts the fire phase and locks the exterior door.
- Library vertical slice:
  - Catalog sequence: Moon, Bird, Train.
  - Librarian desk rewards.
  - Sliding shelf sequence: 2, 5, 1.
  - Hidden Mira and boiler clues reveal after the shelf opens.

Library scale benchmark:

- The Library keeps its PDF footprint of `16 x 14 m`, with `3.4 m` walls and a fitted ceiling.
- `res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn` supplies handcrafted room content through the Library room's optional `content_scene` data field.
- The main route from D03 to D05 remains open while three double-sided shelf ranges create long, human-scale aisles.
- The close third-person camera uses a `2.65 m` spring arm, `1.48 m` pivot, shoulder offset, and `60` degree FOV.
- Authored interaction anchors bind the existing persistent placement IDs to visible props; gameplay falls back to a marker only when an authored anchor is absent.
- Optional Library observations are recorded separately from progression evidence and cannot unlock flags or inflate clue totals.
- Floating labels are hidden during normal play. `F3` toggles them for route and interaction testing.
- Current visual materials use nearest-with-mipmaps filtering to keep the low-resolution presentation stable at distance.
- The Library benchmark replaces all 396 old shelf-filler blocks with a Blender-authored, material-batched dressing layer containing 2,577 individual books.
- The player capsule remains as hidden collision/debug geometry; normal play uses the obscured investigator visual blockout and lantern light.

Deferred:

- Classroom fuse and seating puzzles.
- Dormitory music-box puzzle.
- Kitchen scale and extinguisher route.
- Bathroom mirror, drain, and wringer.
- Boiler pressure puzzle and smoke-rate changes.
- Full doll deduction, Nila cradle ending, audio, VFX, final assets, and cutscene.
