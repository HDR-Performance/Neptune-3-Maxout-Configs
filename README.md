# Neptune 3 Maxout Configs

Klipper upgrade packages for the Elegoo Neptune 3 series, built and maintained
by **HDR Performance**. These packages organize the printer configuration,
integrate KAMP, add guided maintenance and filament workflows, and support the
BTT Pad 7 accelerometer for input-shaper calibration.

> [!WARNING]
> Download only the package matching your exact printer model. The standard,
> Pro, Plus, and Max use different motion limits, probes, homing positions,
> meshes, fan pins, and bed geometry. Installing the wrong `printer.cfg` can
> cause unsafe movement or heater behavior.

## Download the correct package

| Printer | Package | Important model-specific behavior |
|---|---|---|
| Neptune 3 | [Download](Neptune3-HDR-Performance-Pad7-Complete-Guide.zip) | Strain-gauge probe with automatic tare; no unverified screw-tramming coordinates |
| Neptune 3 Pro | [Download](Neptune3Pro-HDR-Performance-Pad7-Complete-Guide.zip) | Pro probe, mesh, homing position, and 235 mm XY motion envelope |
| Neptune 3 Plus | [Download](Neptune3Plus-HDR-Performance-Pad7-Complete-Guide.zip) | Plus-sized geometry and guided six-screw bed tramming |
| Neptune 3 Max | [Download](Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip) | Max-sized geometry, seven-point tramming workflow, and Max-specific homing |

Every ZIP includes a model-specific **`START_HERE.md`**. Read that file before
copying anything to the printer.

## Main features

- Safe KAMP adaptive meshing, smart parking, and bounded purge movement
- BTT Pad 7 ADXL345 input-shaper calibration
- Guided manual Z-offset calibration with nozzle cleaning
- Filament load, unload, color-change, and runout recovery controls
- Ten-minute unattended runout-pause hotend safety cooldown
- Optional persistent bed heat soak before KAMP
- Persistent PLA, PETG, and TPU pressure-advance profiles
- Bed and nozzle PID-tuning controls with temperature validation
- Print and maintenance counters
- Model-specific bed-tramming support where verified coordinates are available
- Organized `custom/` configuration folders instead of a crowded config root

## Requirements

- The correct Elegoo Neptune 3-series model with a compatible Robin Nano board
- A working Klipper, Moonraker, and Mainsail installation
- BTT Pad 7 host MCU available at `/tmp/klipper_host_mcu`
- Pad 7 ADXL345 available on `spidev1.1`
- KAMP installed
- Object processing enabled in `moonraker.conf`
- **Label objects** enabled in OrcaSlicer or another compatible slicer

Required Moonraker setting:

```ini
[file_manager]
enable_object_processing: True
```

## Quick installation

1. Download a complete configuration backup from Mainsail.
2. Download the ZIP matching the exact printer model.
3. Extract it and read its `START_HERE.md`.
4. Open the packaged `config/` folder.
5. Upload the **contents** of that folder into the printer's active `/config`
   directory.
6. Replace only the files identified by the model-specific guide.
7. Preserve host-service files such as `moonraker.conf`, `mainsail.cfg`,
   `KlipperScreen.conf`, and the updater-managed `KAMP/` folder.
8. Select **Save & Restart** in Mainsail.
9. Stop immediately if Klipper reports a configuration error.

## Recommended OrcaSlicer G-code

Enable **Label objects** and use this machine start G-code:

```gcode
M117
START_PRINT BED_TEMP=[bed_temperature_initial_layer_single] EXTRUDER_TEMP=[nozzle_temperature_initial_layer] MATERIAL=PETG
```

Change `MATERIAL` to `PLA`, `PETG`, or `TPU` as appropriate. Machine end
G-code:

```gcode
END_PRINT
```

Remove slicer-generated homing, bed-mesh, and purge-line commands when they
duplicate the `START_PRINT` workflow.

## First startup checks

Keep a hand near Emergency Stop during initial physical testing.

1. Confirm the hotend and bed temperatures look reasonable at room temperature.
2. Run `G28` and watch the entire model-specific homing sequence.
3. Run `SMART_PARK` and verify that Z lifts before XY travel.
4. Run `ACCELEROMETER_QUERY` and confirm live acceleration readings.
5. Heat the nozzle and run `LINE_PURGE`; confirm it remains on the bed.
6. Print a small center-bed model with heat soak disabled.

## Input-shaper calibration

Secure the BTT Pad 7 accelerometer firmly to the toolhead, clear the printer,
and run:

```gcode
CALIBRATE_SHAPER
```

The macro homes the printer, tests both axes at the model-specific calibration
point, saves the recommended values, and restarts Klipper. Never run it during
a print.

## Common controls

| Command | Purpose |
|---|---|
| `MANUAL_Z_OFFSET_ADJUST` | Clean the nozzle and open the Mainsail TESTZ workflow |
| `MANUAL_BED_TRAMMING` | Probe verified screw locations on supported Plus and Max packages |
| `SET_MATERIAL MATERIAL=PETG` | Select and persist a material profile |
| `LOAD_FILAMENT` | Heat, load, purge, and optionally cool down |
| `UNLOAD_FILAMENT` | Heat, form a tip, unload, and optionally cool down |
| `M600` | Start a guided color change |
| `RUNOUT_RESUME` | Complete runout or color-change recovery and resume |
| `TOGGLE_HEAT_SOAK` | Toggle the persistent five-minute bed heat soak |
| `HEAT_SOAK_STATUS` | Display the saved heat-soak state |
| `G29` | Home and create a runtime adaptive mesh |
| `M420` | Load the saved default mesh manually |
| `BED_PID_TUNE TEMP=60` | Tune and save bed PID values |
| `NOZZLE_PID_TUNE TEMP=230` | Tune and save hotend PID values |
| `MAINTENANCE_STATUS` | Show completed-print and service counters |

## Safety and support

- Back up before installing or changing any configuration.
- Do not move or heat the printer while Klipper reports an error.
- Confirm the exact printer model and controller before copying `printer.cfg`.
- Test one feature at a time before beginning a long print.
- Configuration files are provided as community upgrades; the installer is
  responsible for verifying wiring, hardware, and safe operation.

For detailed installation, calibration, parameters, and recovery instructions,
open `START_HERE.md` and `FEATURE_GUIDE.md` inside the downloaded package.

## Credits

Package integration, organized workflows, safety-focused macros, documentation,
and Neptune 3-series upgrade work by **HDR Performance**.

This project builds on [Klipper](https://www.klipper3d.org/) and
[Klipper Adaptive Meshing & Purging](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging).
Those projects retain their respective authorship and licenses.
