# Moonraker recovery and troubleshooting

This guide replaces the older one-size-fits-all Moonraker fix with a safer diagnostic sequence. Preserve a working installation whenever possible.

## Collect evidence first

In Mainsail, download `klippy.log` and `moonraker.log`. Over SSH:

```text
systemctl status moonraker --no-pager
journalctl -u moonraker -n 100 --no-pager
ls -la ~/printer_data/config
```

Back up the data directory before editing:

```text
cp -a ~/printer_data/config ~/printer_data/config-backup
```

## Moonraker configuration file not found

Modern MainsailOS/Fluidd-style installations commonly use:

```text
~/printer_data/config/moonraker.conf
```

Confirm the service launch arguments and log message before creating files. Do not paste an old, broad `moonraker.conf` over a modern working installation.

If the file is truly missing:

1. Restore it from the printer backup when available.
2. Otherwise use the Pad 7 image's supported repair method or KIAUH to repair Moonraker.
3. If rebuilding manually, start with Moonraker's current sample/minimum configuration and add only the required local sections.
4. Check for duplicate section names; Moonraker parses them strictly.
5. Restart Moonraker and read the new log before making another change.

Official references:

- [Moonraker configuration](https://moonraker.readthedocs.io/en/stable/configuration/)
- [Moonraker installation](https://moonraker.readthedocs.io/en/latest/installation/)

## MCU not found

- Confirm the firmware was built for the actual controller and MCU.
- On SKR 3, confirm H723/H743, 128 KiB bootloader, 25 MHz crystal, and USB PA11/PA12.
- On Robin Nano, confirm the F401 build, expected bootloader, filename, and physical serial interface.
- Check whether the SD card flash completed.
- Run `ls /dev/serial/by-id/` and copy the exact stable ID.
- Inspect `klippy.log` rather than guessing the serial path.

## TMC SPI error

Power down before touching a driver.

- Verify driver orientation and voltage selection.
- Reseat the affected driver.
- Confirm CS pins PD5, PD0, PE1, and PC6.
- Confirm shared software SPI PE15/PE13/PE14.
- Do not test motion until `DUMP_TMC` succeeds for every installed driver.

## Axis moves incorrectly

Verify the two motor coil pairs first. A motor that only vibrates or moves weakly commonly has a mispaired coil. Once wiring is correct, invert or remove `!` from the axis `dir_pin` if direction is reversed.

## Endstop or probe state does not change

Run:

```text
QUERY_ENDSTOPS
QUERY_PROBE
```

Check signal voltage, ground, pin order, and pull-up requirements. Pro/Plus/Max SKR packages use PC0 through Z-STOP. The standard Neptune 3 strain-gauge SKR conversion uses PC13 only after the interface is electrically verified.

## Heater or thermistor error

Stop heating and disconnect power if temperature rises uncontrollably.

- Confirm hotend thermistor on PA2/TH0 for the SKR package.
- Confirm bed thermistor on PA1/THB.
- Verify the configured sensor type against the installed thermistor.
- Confirm the heater and sensor did not get crossed.
- Re-run PID after changing hotend, heater, thermistor, fan duct, or bed assembly.

## KAMP does not adapt

- Confirm `[exclude_object]` is loaded.
- Confirm `[file_manager] enable_object_processing: True` in Moonraker.
- Confirm the slicer emits object labels.
- Confirm `KAMP_Settings.cfg` and every included file exist.
- Confirm the slicer calls only the packaged `START_PRINT` sequence.

## Input-shaper errors or poor results

- Run `ACCELEROMETER_QUERY` first.
- Rigidly mount the sensor to the toolhead for X and the bed for Y.
- Turn fans off during measurement.
- Secure the cable and remove rattling objects.
- Inspect the machine for loose parts after the sweep.
- Do not reuse another machine's saved shaper frequencies.

## When to stop

Shut the printer down for smoke, hot connectors, abnormal driver temperature, uncontrolled motion, rising temperature without a heat command, an endstop that is ignored, or a probe that cannot be verified. Configuration experimentation is not a substitute for correcting an electrical fault.

Return to the [documentation index](README.md).
