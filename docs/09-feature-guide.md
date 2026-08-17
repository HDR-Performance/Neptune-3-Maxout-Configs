# HDR Performance macro and feature guide

## Persistent speed profiles

`SPEED_PROFILE_NORMAL`, `SPEED_PROFILE_FAST`, and `SPEED_PROFILE_LUDICROUS`
are idle-only controls. Each selection creates and verifies a timestamped
`printer.cfg` backup, changes only `max_velocity`, `max_accel`, and
`square_corner_velocity` inside the marked `[printer]` speed block, records the
active profile, and restarts Klipper so the new limits become the configuration
defaults. Z limits, pins, driver current, TMC mode, input shaper, probe, heaters,
and all calibration values are left unchanged.

Normal uses the supported baseline for the selected printer/controller. Fast is
for controlled high-speed testing. Ludicrous is an experimental ceiling and is
recommended only with suitable motors, drivers, current, mechanics, input
shaping, and careful validation. These limits do not make slicer speeds safe.

## Print workflow

### `START_PRINT`

Validates slicer temperatures, homes the printer, optionally heat-soaks the bed, creates the KAMP mesh, smart-parks, finishes nozzle heating, and purges at a controlled travel speed.

### `END_PRINT`

Records maintenance totals, lifts within the configured Z limit, presents the part, clears the mesh, and turns heaters and fans off.

### Pause, resume, and cancel

The package provides bounded park moves and state cleanup. Use the package's `PAUSE`, `RESUME`, and `CANCEL_PRINT` buttons rather than adding another competing macro set.

### Home and release motors

KlipperScreen's **Move** panel places **Disable Motors** beside **Home**. Homing intentionally leaves the steppers energized so the machine retains its position. Use the protected Disable Motors button when you are finished, then home again before another controlled move. Do not append `M18`/`M84` to the homing macro automatically.

Pad 7 CB1 and CM4 owners receive the paired [screen and touchscreen rotation controls](15-pad7-display-touch-controls.md) automatically when the GitHub installer detects the Pad 7 hardware.

The Pad 7 CB1/CM4 UI installer keeps KlipperScreen's original **Macros** panel
on the main menu. It shows the standard searchable, scrolling list with the
normal parameter fields. Bed Level, Bed Mesh, Input Shaper, and Z Calibrate +
Clean stay in **More**. The underlying G-code macro names remain unchanged for
slicer and automation compatibility.

After every OTA update, run **Macros > POST OTA VERIFY**. Then run **More > Z
Calibrate + Clean**, confirm the
saved Z offset, and verify the reported input-shaper X/Y types and frequencies
belong to that physical printer before starting a print.

## Manual Z-offset calibration

Run:

```text
MANUAL_Z_OFFSET_ADJUST
```

The Pad 7 setup panel exposes an optional bed target and an adjustable nozzle
target. A bed target of `0` leaves bed heating disabled. When a bed target is
selected, the macro waits for the bed first and only then heats the nozzle for
the purge-and-clean sequence. The existing nozzle default remains `230 C`.

`G29` exposes `BED_TEMP` and `NOZZLE_TEMP` with defaults of `60 C` and `190 C`.
It waits for the bed, waits for the nozzle, and then runs a normal full-bed mesh.

The workflow:

1. Homes the printer.
2. If a bed target was selected, waits for the bed to reach it.
3. Heats the nozzle to the selected cleaning temperature.
4. Purges/cleans near the left side of the bed.
5. Turns the hotend heater off.
6. Moves to the configured calibration position.
7. Opens Klipper's `PROBE_CALIBRATE`/TESTZ controls immediately without waiting for cooldown.

Use the Mainsail or KlipperScreen up/down TESTZ controls, choose **Accept**, then **Save Config**. Klipper writes the new value to the active root `printer.cfg`. The next run reads the newly saved value.

On Pad 7 installations, use **More > Z Calibrate + Clean**. The installer intentionally disables the stock KlipperScreen Z-calibration shortcut because it starts `PROBE_CALIBRATE` directly and skips nozzle cleaning. The dedicated HDR setup panel lets the user select bed and nozzle targets, sends `MANUAL_Z_OFFSET_ADJUST`, and KlipperScreen then opens its TESTZ panel automatically when the cleaning macro reaches calibration mode.

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
