# Boiler, Records, and Final Deduction

Phase 7 completes the playable investigation route from the service valve wheel to the Nila cradle ending.

## Boiler and Records

- The pressure sequence is Bath, Radiator, Kitchen, Master Isolation (`1-2-3-4`).
- Shutdown routes steam to the Bathroom before disabling the damaged service line.
- The Kitchen extinguisher applies a `0.88` smoke-rate multiplier.
- Boiler shutdown applies a `0.58` multiplier; together they produce `0.5104`.
- Shutdown opens the records cabinet, reveals seven condensation handprints, and creates a fair checkpoint.

## Identity Deduction

The journal tracks exactly fourteen identity clues, two per child:

- Mira: Library photograph and Dormitory ribbon.
- Leela: drain shoe and bunk roster.
- Arun: borrowing card and star-projector slide.
- Dev: maintenance report and train wheel.
- Sana: Kitchen duty roster and labelled wet cloth.
- Kabir: punishment ledger and blue marble.
- Nila: laundry wage slip and seventh handprint.

Both clues unlock a numbered identity assignment when a registered doll is inspected. The final deduction requires all fourteen clues, six registered assignments, the house register, the mirror message, and the seventh handprint.

## Cradle and Pressure

During final deduction, inspecting a doll carries that choice to the central cradle. A wrong doll returns to its alcove and adds ninety seconds of smoke. Nila stops pressure progression and completes the current playable ending.

Smoke uses qualitative HUD feedback instead of a large countdown. Documents, journal, code panels, and pause UI stop pressure progression. Checkpoints preserve state, evidence, journal data, player position, and elapsed smoke.

Run the complete regression with `--boiler-final-slice-self-test`. Capture the room with `--capture-boiler-phase7 --boiler-benchmark`; add `--boiler-shutdown` for the solved state.
