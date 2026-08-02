# Ash Dormitory Asset Decisions

This folder is for assets approved for live game references.

- `art/_staging/fonts/thin_sans`: staged, but the direct itch download produced an HTML download page instead of a usable TTF in this environment. Not approved yet.
- `art/_staging/fonts/kenney_fonts`: staged and previewed. Readable enough for headings, but not approved for body/UI text because the current default font is clearer.
- `art/_staging/environment/opengameart_horror_tile_set`: staged and previewed. Not approved for room art because the sheet is side-view and does not match the top-down dormitory layout.

Current first slice uses restrained procedural room art only.

## Burning Nursery 2.5D pass

- `art/_staging/kenney_2_5d_pass`: staged Kenney Roguelike Indoors, Kenney Roguelike Characters, and Kenney Light Masks for inspection. Their license files state Creative Commons Zero (CC0).
- `art/_staging/kenney_2_5d_pass/previews`: generated contact sheets for visual review.
- `art/approved/nursery_2_5d`: approved live sprite slice for the Burning Nursery pass. These are project-specific pixel PNGs generated to match the nursery scale, muted palette, and current hitboxes. The live scene references only this approved folder, not `_staging`.
- Kenney Roguelike Indoors and Characters remain useful reference/candidate material, but the first live pass avoids dropping in the full sheets because they read more like a general roguelike object library than a haunted nursery.
- Kenney Light Masks remain staged for later lighting polish; this pass uses a simple approved fire glow sprite.
