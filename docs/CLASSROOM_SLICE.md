# Classroom Slice

The authored Classroom implements the PDF's east-wing sequence while preserving
the original room bounds and door coordinates.

## Progression

1. The Library brass key opens D04.
2. The player reads the blackboard sums and collects the 5A, 8A, and 13A fuses.
3. The fuse panel accepts `5, 8, 13` for lights, projector, and heater.
4. The powered projector reveals Arun's star slide and the seventh-desk shadow.
5. Six name cards are arranged as Mira, Arun, Dev / Leela, Sana, Kabir.
6. The teacher drawer opens, revealing the attendance sheet, bathroom key,
   hooked pointer, and dormitory symbol code.
7. The doorway extinguisher clears D08 and opens the Kitchen route.

The seventh desk remains visible before the projection but cannot be recorded as
evidence until the projected shadow gives it context. Puzzle furniture stays
visible while unavailable; only contained rewards are hidden.

## Authored Content

`ClassroomContent.tscn` contains the room shell, eight desks and chairs, teacher
zone, projector and screen, fuse cabinet, name-card board, cubbies, clock,
lighting, doorway fire, smoke, all clue props, interaction anchors, and the new
interactable areas that were not present in the historical house blockout.

The legacy Classroom desk meshes are hidden at runtime while their tested
collision remains active.
