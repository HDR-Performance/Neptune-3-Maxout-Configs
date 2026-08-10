# Slicer start and end G-code

The Klipper macros own homing, optional bed heat soak, KAMP meshing, smart parking, final nozzle heating, and the purge line. Keep the slicer G-code short so those actions do not run twice.

## OrcaSlicer

Start G-code:

```text
START_PRINT BED_TEMP=[bed_temperature_initial_layer_single] EXTRUDER_TEMP=[nozzle_temperature_initial_layer]
```

End G-code:

```text
END_PRINT
```

If the installed OrcaSlicer version uses different placeholder names, insert its first-layer bed and nozzle variables with the slicer's variable browser. Keep the Klipper parameter names `BED_TEMP` and `EXTRUDER_TEMP` unchanged.

Enable object labeling/exclude-object output so KAMP can determine the actual print area.

## Cura

Start G-code:

```text
START_PRINT BED_TEMP={material_bed_temperature_layer_0} EXTRUDER_TEMP={material_print_temperature_layer_0}
```

End G-code:

```text
END_PRINT
```

Enable the object-labeling or Moonraker preprocessing workflow supported by the installed Cura/Moonraker versions when adaptive meshing is expected.

## Material profile

Append a material only when you want the printer's persistent pressure-advance profile to override the current value:

```text
START_PRINT BED_TEMP=... EXTRUDER_TEMP=... MATERIAL=PETG
```

Supported package profiles are PLA, PETG, and TPU. Calibrate pressure advance for the actual material, temperature, nozzle, and acceleration before saving a profile.

## Per-print heat-soak override

Force the soak off:

```text
START_PRINT BED_TEMP=... EXTRUDER_TEMP=... SOAK=0
```

Force it on for five minutes:

```text
START_PRINT BED_TEMP=... EXTRUDER_TEMP=... SOAK=1 SOAK_MINUTES=5
```

The saved default is controlled from Mainsail with `ENABLE_HEAT_SOAK` and `DISABLE_HEAT_SOAK`.

## Remove duplicated commands

Do not place these in slicer start G-code when using the package macro:

- `G28`
- `BED_MESH_CALIBRATE`
- `BED_MESH_PROFILE LOAD=...`
- `LINE_PURGE`
- A separate purge-line sequence
- A second final nozzle-heating wait

Duplicating those steps can cause extra probing, stale meshes, double purges, or surprising travel.

Return to the [documentation index](README.md).
