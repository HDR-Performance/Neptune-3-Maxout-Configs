# Slicer start and end G-code

The Klipper macro owns homing, optional heat soak, KAMP meshing, smart parking, final nozzle heating, and the purge line. Do not duplicate those operations in the slicer.

## OrcaSlicer

Start G-code:

```text
START_PRINT BED_TEMP=[bed_temperature_initial_layer_single] EXTRUDER_TEMP=[nozzle_temperature_initial_layer]
```

End G-code:

```text
END_PRINT
```

Enable object labeling/exclude-object output in the printer profile so KAMP can determine the actual print area. If your Orca release uses different temperature placeholder names, use its variable browser to insert the first-layer bed and nozzle variables; keep the Klipper parameter names `BED_TEMP` and `EXTRUDER_TEMP` unchanged.

To select a persistent pressure-advance profile from start G-code, append `MATERIAL=PLA`, `MATERIAL=PETG`, or `MATERIAL=TPU`.

## Cura

Start G-code:

```text
START_PRINT BED_TEMP={material_bed_temperature_layer_0} EXTRUDER_TEMP={material_print_temperature_layer_0}
```

End G-code:

```text
END_PRINT
```

Enable labeled objects in the post-processing or Moonraker workflow if adaptive meshing is expected.

## Per-print heat-soak override

- Force off: add `SOAK=0`
- Force on for five minutes: add `SOAK=1 SOAK_MINUTES=5`

The saved default is controlled with `ENABLE_HEAT_SOAK` and `DISABLE_HEAT_SOAK` in Mainsail.

