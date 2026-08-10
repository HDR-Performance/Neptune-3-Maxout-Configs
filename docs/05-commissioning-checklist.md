# Controlled commissioning checklist

Use this checklist after installing a package, flashing firmware, rewiring, or changing motors. Keep a hand on emergency stop throughout first motion and heating tests.

## 1. Visual inspection with power off

- No loose strands, exposed conductors, pinched wires, or unsupported terminals
- Correct input voltage and polarity
- Correct fan-voltage jumper
- Driver orientation and cooling verified
- Motor coil pairs verified with a meter
- Heater and bed wiring sized for their measured load
- Probe voltage and pin order verified
- Toolhead and bed move freely by hand
- Belts are aligned and snug, not overtightened

## 2. Controller connection

Start Klipper and confirm the MCU is connected. Resolve all configuration or TMC errors before continuing.

For SKR/TMC builds:

```text
DUMP_TMC STEPPER=stepper_x
DUMP_TMC STEPPER=stepper_y
DUMP_TMC STEPPER=stepper_z
DUMP_TMC STEPPER=extruder
```

## 3. Temperature sensors

At room temperature, the hotend and bed readings should be believable and stable. Warm each sensor gently by hand and confirm the correct graph rises.

Stop if a reading is implausible, reversed, open-circuit, or responds on the wrong channel.

## 4. Endstops and probe

Run `QUERY_ENDSTOPS`. Manually operate X and Y switches and confirm only the matching state changes.

Run `QUERY_PROBE` and activate the probe without allowing the nozzle to reach the bed. The standard Neptune 3 strain-gauge conversion requires special attention to its interface voltage and signal behavior.

Do not use `G28` until these tests pass.

## 5. Individual motor tests

Keep the carriage and bed near their centers. Test one motor at a time:

```text
STEPPER_BUZZ STEPPER=stepper_x
STEPPER_BUZZ STEPPER=stepper_y
STEPPER_BUZZ STEPPER=stepper_z
```

Heat the nozzle to the filament's safe extrusion temperature before testing the extruder.

If an axis moves the wrong direction after coil pairs are confirmed, correct the corresponding `dir_pin` inversion in `printer.cfg`. Never use configuration to hide a mispaired coil.

## 6. First homing sequence

1. Move X and Y away from their endstops by hand with power off.
2. Power on and home one axis at a time if the configuration permits.
3. Verify travel direction and stop response.
4. Raise Z before the first probe-based Z home.
5. Place a finger near emergency stop and trigger the probe by hand during the first Z approach.
6. Run full `G28` only after every individual check succeeds.

## 7. Fan and heater tests

- Command the part fan at low and full speed.
- Confirm the hotend fan starts at its configured threshold.
- If fitted, test the light separately.
- Heat the hotend to a low target and verify only the hotend graph rises.
- Heat the bed to a low target and verify only the bed graph rises.

Shut down immediately if temperature rises without being commanded or the wrong sensor responds.

## 8. Calibration order

1. Hotend and bed PID
2. Extruder rotation distance
3. Manual bed tramming
4. Probe/Z offset using `MANUAL_Z_OFFSET_ADJUST`
5. Bed mesh/KAMP
6. Pressure advance for the actual material
7. Input shaper with the accelerometer in the correct location
8. Conservative first-layer test
9. Conservative calibration print

Do not begin at the package's maximum velocity or acceleration ceilings. Increase speed only after controlled prints prove the mechanics, current, cooling, and calibration are reliable.

Return to the [documentation index](README.md).
