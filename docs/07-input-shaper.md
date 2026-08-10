# BTT Pad 7 input-shaper calibration

The packages include the Pad 7 host-MCU and ADXL345 configuration used by the HDR setup. Input-shaper values are machine-specific and must be measured after belts, motors, toolhead mass, bed mounting, or frame hardware changes.

## Before testing

- Tighten the frame, toolhead, bed, pulleys, and motor mounts.
- Set belts to a reasonable, even tension.
- Remove loose tools and filament spools that can rattle.
- Make sure the accelerometer mount is rigid.
- Turn part-cooling and other noisy fans off during measurement.
- Confirm the nozzle and bed cannot hit clips, clamps, or the sensor cable.

Test communication:

```text
ACCELEROMETER_QUERY
```

The response should contain changing X/Y/Z acceleration values. Resolve any invalid ADXL ID or SPI error before continuing.

## Correct sensor position on a bed slinger

Neptune 3 printers are bed slingers. With one accelerometer:

- Measure X with the sensor rigidly mounted to the toolhead.
- Measure Y with the sensor rigidly mounted to the bed.

Power the printer down before reconnecting or relocating a wired sensor. Secure the cable so it cannot snag during the test.

## Recommended two-stage calibration

### X axis

Mount the accelerometer on the toolhead, restart the printer, and run:

```text
ACCELEROMETER_QUERY
SHAPER_CALIBRATE AXIS=X
SAVE_CONFIG
```

### Y axis

Power down, move the accelerometer to the bed, secure the cable, restart, and run:

```text
ACCELEROMETER_QUERY
SHAPER_CALIBRATE AXIS=Y
SAVE_CONFIG
```

Klipper can save after calibrating each axis. Review the console recommendations and confirm the resulting settings in the SAVE_CONFIG section.

## About `CALIBRATE_SHAPER`

The package macro runs `SHAPER_CALIBRATE` without an axis, then saves. That is convenient when two correctly configured accelerometers are permanently installed or when the sensor arrangement accurately measures both moving assemblies. With one movable Pad 7 sensor on a bed slinger, the two-stage per-axis method above is more physically correct.

## After calibration

1. Inspect the printer for anything loosened by the resonance sweep.
2. Run a conservative ringing test print.
3. Verify surface quality and dimensional behavior.
4. Recalibrate after meaningful changes to motors, belts, toolhead, bed mass, or frame rigidity.

Do not auto-calibrate before every print. Resonance tests intentionally create strong vibration and add unnecessary mechanical wear when repeated frequently.

Official reference: [Klipper measuring resonances](https://www.klipper3d.org/Measuring_Resonances.html)

Return to the [documentation index](README.md).
