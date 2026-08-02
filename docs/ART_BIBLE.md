# Ashdown House Art Bible

## North Star

Ashdown House is an intimate, close-camera pixel-horror diorama. It combines authored low-poly 3D spaces with deliberate pixel-scale surfaces, modern lighting, and clear full-resolution interface text. The aim is a polished independent production inspired by HD-2D principles, not an imitation of another game's assets or compositions.

The house should feel inhabited before it feels haunted. Every room needs evidence of routine, ownership, wear, repair, and interruption.

## Scale And Proportions

- One Blender unit and one Godot unit equal one metre.
- Adult investigator: 1.72 m visual height.
- Interior doors: 1.2 m wide by 2.2 m high unless the level plan specifies otherwise.
- Standard ceilings: 3.4 m. Feature rooms may rise to 4.2 m when authored in the level scene.
- Primary route clearance: at least 1.5 m. Secondary aisles: at least 1.2 m.
- Furniture uses believable human dimensions. Stylization comes from silhouette, texture, and stepped motion, not toy-like scale.

## Shape Language

- Architecture: tall, narrow, slightly severe; repeated vertical trim and deep reveals.
- Furniture: sturdy institutional construction softened by repairs, rounded wear, and mismatched personal objects.
- Player: obscured adult silhouette, long dark coat, boots, satchel, lantern, hidden face.
- Dolls: handmade fabric-and-wood bodies with one shared base and seven unmistakable silhouettes.
- Interactive props: readable silhouette first, controlled accent color second, highlight only while targeted.

## Palette

Use multiple restrained families rather than a single monochrome wash.

- Aged ivory: plaster, paper, labels.
- Oxidized green: institutional paint, tile, cabinets.
- Smoke blue: moonlight, cold metal, distant rooms.
- Muted burgundy: fabric, warning accents, old upholstery.
- Charcoal: soot, iron, deep recesses.
- Warm amber: lantern, desk lamps, safe-memory beats.

Saturation belongs on story evidence, fire, and child-specific objects. Large surfaces remain subdued but must retain readable color separation.

## Texture Language

- Target texel density: approximately 128 pixels per metre for hero rooms, 64 pixels per metre for background architecture.
- Texture dimensions remain powers of two and normally stop at 1024 px per atlas.
- Use nearest filtering with mipmaps for 3D textures. Mipmaps reduce shimmer; nearest sampling preserves the authored edge language.
- Surface detail is broad and intentional: plank seams, plaster variation, chipped paint, soot, fingerprints, labels, and fabric weave.
- Avoid photographic noise, excessive grunge, smooth plastic materials, and tiny contrast that disappears at Balanced resolution.
- Accepted generated imagery is repainted, tiled, palette-controlled, and packed into an atlas before entering the game.

## Library Benchmark

- Books are recognizable books, not uninterrupted colored blocks.
- Use 8-12 silhouette families: thin, standard, broad, ledger, damaged, leaning, horizontal stack, pamphlet, cloth-bound, and missing-volume gap.
- Vary height, depth, lean, grouping, faded spine label, and occasional bookend.
- Merge or instance shelf clusters. Only puzzle books become separate interactive nodes.
- Every long aisle needs a foreground, middle distance, and lit destination.
- Dust and clutter support composition; they may not obscure navigation or prompts.

## Lighting

- Lighting directs attention and mood; it does not replace readable albedo values.
- Prefer restrained warm practical lights against cool exterior or corridor fill.
- Dynamic lights are reserved for lantern, fire, puzzle response, and major narrative effects.
- Static architecture uses baked or authored static lighting where practical.
- Contact shadows and shallow occlusion ground props. Pure black crush is avoided around required interactions.
- Gameplay depth of field and FXAA remain disabled. Depth of field is reserved for controlled inspection or cutscene framing.

## Damage And Haunting

- Damage follows construction: plaster cracks radiate from stress, soot rises, water gathers low, and fabric frays at contact edges.
- Supernatural effects enter through local exceptions: impossible shadow direction, ash moving against airflow, repeated child marks, and selective color memory.
- Smoke, fog, and bloom may deepen pressure but never hide required text, silhouettes, or exits.

## UI

- UI renders at display resolution, independently from world resolution.
- Atkinson Hyperlegible Next is the primary interface typeface.
- Body copy targets 20-24 px at 720p; prompts 22 px; subtitles 24 px; headings 30-36 px.
- Text has no decorative pixel treatment. It uses clean spacing, strong contrast, and modest shadow or panel backing.
- Menus and documents use responsive containers and safe margins, not fixed 640 x 360 coordinates.

## Animation

- Character animation uses deliberate stepped playback while camera and UI remain smooth.
- Motion must preserve weight: planted feet, readable anticipation, and short follow-through.
- Environmental loops stay subtle and desynchronized.
- Interaction animations prioritize hand placement and prop contact over flourish.

## Acceptance Rule

An asset is approved only when it reads at Balanced world resolution, matches the palette and scale, has predictable collision, and improves the room without weakening navigation or evidence readability.
