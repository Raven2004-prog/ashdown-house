# Wet Service Slice

Phase 6 converts the Bathroom/Laundry and Kitchen into authored room scenes while preserving the house coordinates and persistent interaction IDs.

## Bathroom and Laundry

- Steam from the boiler reveals the `4-2-7` mirror sequence.
- The towel cabinet releases Sana's labelled cloth.
- The wall lever and classroom hook expose Leela's missing shoe in the drain.
- The laundry wringer requires the crank found in the Kitchen pantry.
- Operating the wringer exposes the Nila wage slip.

## Kitchen

- Four portion weights unlock the `5-3-2-5` pantry scale sequence.
- The pantry contains the duty roster, boiler valve wheel, and laundry wringer crank.
- The valve wheel opens the next boiler route.
- The room includes authored stove, sink, prep table, pantry, scale, dumbwaiter, service curtain, lights, and smoke dressing.

## Validation

Run the cross-room regression test with:

```text
--wet-service-slice-self-test
```

Capture flags are `--capture-wet-service-phase6` with either `--bathroom-benchmark` or `--kitchen-benchmark`. Add `--service-solved` to show the completed visual state.
