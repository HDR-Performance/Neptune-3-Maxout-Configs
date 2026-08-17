# HDR Performance feature guide

## Print workflow

- `START_PRINT`: validates requested temperatures, homes, optionally heat-soaks the bed, creates a KAMP mesh, smart-parks, heats the nozzle, and purges at a controlled travel speed.
- `END_PRINT`: records maintenance totals, lifts within the configured Z limit, presents the part, clears the mesh, and shuts down.
- `PAUSE`, `RESUME`, and `CANCEL_PRINT`: bounded park moves with heater and state cleanup.

## Friendly manual Z-offset calibration

Run `MANUAL_Z_OFFSET_ADJUST`. It homes, heats only the nozzle to the selected cleaning temperature, purges at the left side, shuts the heater off, moves to the calibration position, and immediately opens Klipper's probe-calibration workflow. Use the Mainsail or KlipperScreen TESTZ controls, then choose Accept and Save Config. Klipper writes the new value to the active `printer.cfg` SAVE_CONFIG block, and the next calibration starts from that saved value.

The bed is not heated by this macro. The nozzle does not wait to cool after cleaning.

## Filament controls

- `LOAD_FILAMENT TEMP=...`
- `UNLOAD_FILAMENT TEMP=...`
- `M600`
- `RUNOUT_RESUME`
- `ABORT_RUNOUT`

An unattended runout pause keeps the hotend available for ten minutes, then shuts it off while preserving the requested resume temperature. `RUNOUT_RESUME` reheats before restoring the print.

## Heat soak

- `ENABLE_HEAT_SOAK`: persistently enables the default pre-mesh soak.
- `DISABLE_HEAT_SOAK`: persistently disables it.
- `BED_HEAT_SOAK BED_TEMP=70 MINUTES=5`: run it directly.

The feature is a macro setting, not a Mainsail hardware toggle; placing it in the sensor row would misleadingly look like a physical device.

## Material profiles

- `SET_MATERIAL MATERIAL=PLA|PETG|TPU`
- `SAVE_MATERIAL_PROFILE MATERIAL=PETG PA=0.056 LOAD_TEMP=240`

Values persist through `save_variables`. Pressure advance still needs calibration for the actual filament, nozzle, temperature, and acceleration.

## Maintenance and tuning

- `MAINTENANCE_STATUS`
- `RESET_MAINTENANCE TOTAL=1 NOZZLE=1`
- `RECORD_NOZZLE_CHANGE`
- `BED_PID_TUNE TEMP=60`
- `NOZZLE_PID_TUNE TEMP=230 FAN_SPEED=0`
- `CALIBRATE_SHAPER`
- `MANUAL_BED_TRAMMING` on models with screw locations

After changing motors, belt tension, toolhead mass, nozzle, heater, or bed mounting, recalibrate the relevant values rather than copying them from another machine.

