# Install a configuration package

## Before copying files

1. Download only the ZIP matching the exact printer and controller.
2. In Mainsail, download a complete backup of `~/printer_data/config`.
3. Record the current Z offset, PID values, rotation distances, pressure advance, input shaper, and any custom pin changes.
4. Read the package's `START_HERE.md` before replacing anything.

> [!CAUTION]
> Do not merge two `printer.cfg` files line by line. Duplicate sections and stale SAVE_CONFIG values can leave the printer in an unsafe or confusing state.

## Copy the package

1. Extract the ZIP on the computer.
2. Open the package's `config` directory.
3. Copy the **contents** of that directory into `~/printer_data/config`.
4. Preserve the included directory structure, especially `custom/kamp`, `custom/macros`, and `custom/state`.
5. Keep `printer.cfg` and `KAMP_Settings.cfg` in the root of the printer's config directory.
6. For an SKR package, replace `REPLACE_WITH_YOUR_SKR3_EZ_ID` with the exact output from:

   ```text
   ls /dev/serial/by-id/
   ```

7. Select **Save & Restart** in Mainsail.

## First restart

A successful restart only proves that Klipper parsed the configuration and connected to the MCU. It does not prove that motors, heaters, fans, endstops, or the probe are wired correctly.

Complete the [commissioning checklist](05-commissioning-checklist.md) before homing or heating.

## Existing calibration values

The packages intentionally avoid carrying another printer's machine-specific SAVE_CONFIG block. Recalibrate on the actual machine:

1. Heater PID
2. Extruder rotation distance
3. Probe/Z offset
4. Bed tramming
5. Bed mesh
6. Pressure advance
7. Input shaper

Keep the original backup until the new configuration has completed several controlled prints.

Return to the [documentation index](README.md).
