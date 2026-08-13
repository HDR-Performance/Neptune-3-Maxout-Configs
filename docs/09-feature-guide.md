# HDR Performance macro and feature guide

## Print workflow

### `START_PRINT`

Validates slicer temperatures, homes the printer, optionally heat-soaks the bed, creates the KAMP mesh, smart-parks, finishes nozzle heating, and purges at a controlled travel speed.

### `END_PRINT`

Records maintenance totals, lifts within the configured Z limit, presents the part, clears the mesh, and turns heaters and fans off.

### Pause, resume, and cancel

The package provides bounded park moves and state cleanup. Use the package's `PAUSE`, `RESUME`, and `CANCEL_PRINT` buttons rather than adding another competing macro set.

### Home and release motors

KlipperScreen's **Move** panel places **Disable Motors** beside **Home**. Homing intentionally leaves the steppers energized so the machine retains its position. Use the protected Disable Motors button when you are finished, then home again before another controlled move. Do not append `M18`/`M84` to the homing macro automatically.

Pad 7 CM4 owners can also install the paired [screen and touchscreen rotation controls](14-pad7-cm4-klipperscreen.md).

## Manual Z-offset calibration

Run:

```text
MANUAL_Z_OFFSET_ADJUST
```

The workflow:

1. Homes the printer.
2. Heats only the nozzle to the selected cleaning temperature.
3. Purges/cleans near the left side of the bed.
4. Turns the hotend heater off.
5. Moves to the configured calibration position.
6. Opens Klipper's `PROBE_CALIBRATE`/TESTZ controls immediately without waiting for cooldown.

Use the Mainsail or KlipperScreen up/down TESTZ controls, choose **Accept**, then **Save Config**. Klipper writes the new value to the active root `printer.cfg`. The next run reads the newly saved value.

The macro does not heat the bed.

## Filament controls

```text
LOAD_FILAMENT TEMP=240
UNLOAD_FILAMENT TEMP=240
M600
RUNOUT_RESUME
ABORT_RUNOUT
```

An unattended runout pause keeps the requested hotend temperature available for ten minutes. It then shuts the hotend off while remembering the resume temperature. `RUNOUT_RESUME` reheats before continuing.

Never reach into the printer while motion can resume automatically.

## Heat soak

```text
ENABLE_HEAT_SOAK
DISABLE_HEAT_SOAK
BED_HEAT_SOAK BED_TEMP=70 MINUTES=5
```

Enable/disable is persistent through `save_variables`. It is intentionally presented as a macro control rather than a fake hardware switch in Mainsail's sensor row.

## Material profiles

Select a profile:

```text
SET_MATERIAL MATERIAL=PETG
```

Save calibrated values:

```text
SAVE_MATERIAL_PROFILE MATERIAL=PETG PA=0.056 LOAD_TEMP=240
```

Values persist through restarts. Treat the packaged values as starting points only.

## Maintenance and tuning

```text
MAINTENANCE_STATUS
RECORD_NOZZLE_CHANGE
RESET_MAINTENANCE TOTAL=1 NOZZLE=1
BED_PID_TUNE TEMP=60
NOZZLE_PID_TUNE TEMP=230 FAN_SPEED=0
MANUAL_BED_TRAMMING
```

PID macros validate the requested temperature and save the result. Re-run the appropriate tuning after changing a heater, thermistor, hotend, bed assembly, or cooling arrangement.

Bed-tramming coordinates are model-specific. The standard Neptune 3 package does not invent unverified screw coordinates.

Return to the [documentation index](README.md).
