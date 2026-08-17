# Neptune 3 Max — HDR Performance SKR 3 EZ Maxout build

This is the consolidated version of the supplied working Max package and both earlier HDR Performance GitHub guides. It targets the SKR 3 EZ, four TMC5160 Pro EZ drivers, BTT Pad 7, the documented upgraded motors, one shared Z driver, KAMP, and the friendly macro suite.

## Model baseline

- Configured travel: X 0–430, Y -6–430, Z -4–506 mm
- Probe-centered Z home: nozzle X241 Y193
- Mesh: 33,16 to 397,397; 11×9 base grid
- Direct-drive extruder rotation distance: 6.9 mm
- Nozzle diameter: 0.4 mm, matching the current hardened CHT nozzle
- Hotend configuration ceiling: 305 °C; do not command above the hotend's 300 °C rating
- Inductive probe: PC0 through Z-STOP, offset X-28.5 Y22
- Filament switch: PC2
- Both Z motors: one TMC5160 driver through the proven shared harness
- Maxout motors: 42×60 mm / 2.1 A Y motor and the original Y motor moved to X
- Motion ceilings: 800 mm/s velocity and 5000 mm/s² acceleration; these are firmware limits, not recommended slicer speeds

## Install

1. Read `WIRING_AND_FIRMWARE.md` completely. Measure the large bed load and use an external MOSFET if it can exceed the SKR's 10 A bed-output rating.
2. Back up the entire current `~/printer_data/config` directory, including the current SAVE_CONFIG block.
3. Build and flash firmware for the exact H723/H743 chip printed on the SKR.
4. Copy the contents of this package's `config` directory into `~/printer_data/config`, preserving the folders. Keep `printer.cfg` in the root.
5. Replace the MCU placeholder with the result of `ls /dev/serial/by-id/`.
6. Perform every controlled first-power test before the first home.
7. Run `NOZZLE_PID_TUNE`, `BED_PID_TUNE`, `MANUAL_Z_OFFSET_ADJUST`, `MANUAL_BED_TRAMMING`, and a mesh. The package starts with the known-good upgraded Maxout input-shaper baseline of EI / X 50.0 Hz / Y 40.2 Hz; run `CALIBRATE_SHAPER` to replace it after any mechanical change or if your machine differs from the documented build.
8. Calibrate extruder rotation distance and pressure advance for the installed FlowTech/hardened CHT nozzle and actual filament.
9. Add only the start and end macro calls in `SLICER_GCODE.md` to the slicer.

The old per-printer saved mesh, Z offset, and PID values were intentionally removed from the public package. The input-shaper exception is the recent known-good result from this exact documented upgraded Maxout machine: EI at X 50.0 Hz and Y 40.2 Hz. Treat it as a safe starting profile, not a substitute for measuring a mechanically different printer.
