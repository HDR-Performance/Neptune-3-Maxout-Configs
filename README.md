# Neptune 3 Maxout Configs

![Neptune Maxout by HDR Performance](assets/neptune-maxout-banner.png)

Klipper upgrade packages for the Elegoo Neptune 3, Neptune 3 Pro, Neptune 3 Plus, and Neptune 3 Max, built and maintained by **HDR Performance**.

This repository consolidates the working packages and guides previously spread across:

- [Neptune Maxout — SKR 3 EZ with TMC5160 Pro drivers](https://github.com/HDR-Performance/Neptune-Maxout-SKR-3-EZ-with-TMC5160-Pro-Drivers)
- [Neptune 3 Max — BIGTREETECH Pad 7](https://github.com/HDR-Performance/Neptune-3-Max-bigtreetech-pad-7-)

The older wiring, firmware, KAMP, slicer, Moonraker, troubleshooting, and motor-upgrade information has been preserved where useful and corrected where board limits or current Klipper behavior required it.

> [!CAUTION]
> Download only the package matching both the printer model and controller. Robin Nano and SKR 3 EZ configurations are not interchangeable. Installing the wrong `printer.cfg`, wiring a connector by shape alone, or exceeding a heater output's current rating can damage hardware or cause uncontrolled motion/heating.

## Documentation

The legacy tutorials have been rebuilt as a structured, corrected documentation set:

- **[Open the complete documentation index](docs/README.md)**
- **[Install directly from GitHub over SSH](docs/12-ssh-installer.md)**
- **[Set up a Raspberry Pi 4 or generic CM4 host](docs/13-raspberry-pi4-cm4-klipper-host.md)**
- **[Set up a Pad 7 CM4, motor controls, and screen rotation](docs/14-pad7-cm4-klipperscreen.md)**
- **[Set up tested Pad 7 CB1/CM4 display and touchscreen controls](docs/15-pad7-display-touch-controls.md)**
- **[Install the Neptune Maxout KlipperScreen theme](docs/16-neptune-maxout-klipperscreen-theme.md)**
- **[Enable Pad 7 CM4/CB1 speaker audio and Maxout laser feedback](docs/17-pad7-sound.md)**
- [Choose the correct printer/controller package](docs/01-choose-the-correct-package.md)
- [Install a package safely](docs/02-install-a-package.md)
- [Build Robin Nano firmware](docs/03-robin-nano-firmware.md)
- [Convert to SKR 3 EZ and TMC5160 Pro](docs/04-skr3ez-conversion.md)
- [Follow the commissioning checklist](docs/05-commissioning-checklist.md)
- [Install and configure KAMP](docs/06-kamp-setup.md)
- [Calibrate input shaper with the BTT Pad 7](docs/07-input-shaper.md)
- [Set up OrcaSlicer or Cura](docs/08-slicer-gcode.md)
- [Use the HDR macro features](docs/09-feature-guide.md)
- [Upgrade the Neptune 3 Max X/Y motors](docs/10-stepper-motor-upgrade.md)
- [Repair Moonraker and troubleshoot the printer](docs/11-troubleshooting.md)

## Quick SSH installer

The installer preserves every nested config directory, creates a timestamped backup, and does not restart Klipper automatically:

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/install.sh -o hdr-neptune-install.sh
less hdr-neptune-install.sh
chmod +x hdr-neptune-install.sh
./hdr-neptune-install.sh
```

Choose the exact printer and controller from the interactive menu. See the [complete SSH installation and restore guide](docs/12-ssh-installer.md) before running it.

## Choose the controller family

### Stock Robin Nano + BTT Pad 7

These packages retain each model's supplied working Robin Nano hardware mapping and add the organized HDR macro/KAMP feature suite.

| Printer | Download |
|---|---|
| Neptune 3 | [Robin Nano package](Neptune3-HDR-Performance-Pad7-Complete-Guide.zip) |
| Neptune 3 Pro | [Robin Nano package](Neptune3Pro-HDR-Performance-Pad7-Complete-Guide.zip) |
| Neptune 3 Plus | [Robin Nano package](Neptune3Plus-HDR-Performance-Pad7-Complete-Guide.zip) |
| Neptune 3 Max | [Robin Nano package](Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip) |

### HDR Maxout — SKR 3 EZ + TMC5160 Pro EZ + BTT Pad 7

These are full controller-conversion packages. The common baseline is four TMC5160 Pro EZ drivers, a 42×60 mm / 2.1 A Y motor, the original Y motor moved to X, both Z motors on one driver, and BTT Pad 7 input shaping.

| Printer | Download | Status and important difference |
|---|---|---|
| Neptune 3 | [SKR Maxout package](Neptune3-SKR3EZ-TMC5160Pro-HDR-Performance.zip) | Engineering conversion; stock strain-gauge interface must be electrically verified at PC13 |
| Neptune 3 Pro | [SKR Maxout package](Neptune3Pro-SKR3EZ-TMC5160Pro-HDR-Performance.zip) | Pro geometry, inductive probe through PC0, stock-hotend 250 °C limit |
| Neptune 3 Plus | [SKR Maxout package](Neptune3Plus-SKR3EZ-TMC5160Pro-HDR-Performance.zip) | Plus geometry; verify bed current and use an external MOSFET when required |
| Neptune 3 Max | [SKR Maxout package](Neptune3Max-SKR3EZ-TMC5160Pro-HDR-Performance.zip) | Consolidated working Max build; 0.4 mm CHT/FlowTech baseline and Max geometry |

Every ZIP contains `START_HERE.md`, a model-specific installation sequence, wiring and firmware instructions, slicer G-code, troubleshooting, feature documentation, and the complete organized `config/` tree.

## What is included

- KAMP adaptive meshing, smart parking, and a bounded 100 mm/s purge-position move
- BTT Pad 7 ADXL345 input-shaper calibration
- Known-good upgraded Neptune 3 Max baseline: EI at X 50.0 Hz and Y 40.2 Hz
- Friendly manual Z-offset calibration with nozzle pre-cleaning
- Filament load, unload, color change, and runout recovery
- Ten-minute unattended runout hotend cooldown
- Persistent optional bed heat soak before KAMP
- Persistent PLA, PETG, and TPU pressure-advance profiles
- Maintenance counters and guided PID tuning
- Model-specific homing, mesh, motion envelope, and screw locations
- Organized `custom/kamp`, `custom/macros`, and `custom/state` directories
- Automatic Pad 7 CB1/CM4 screen rotation with the tested matching touchscreen matrix
- Neptune Maxout Pad 7 theme with branded background, red/charcoal controls, a printer badge, and original retro laser button feedback on CM4 or CB1

## Corrected SKR 3 EZ details

- The SKR 3 may contain an STM32H723 or STM32H743. Inspect the physical chip and build for the exact processor with a 128 KiB bootloader, 25 MHz crystal, and USB on PA11/PA12.
- PB9 is FDCAN transmit, not the overhead-light output. The packages use controlled FAN0/PB7 for the optional 24 V LED, FAN1/PB6 for part cooling, and FAN2/PB5 for the hotend fan.
- `stealthchop_threshold: 999999` enables stealthChop for almost all movement. The Maxout packages use `0` for spreadCycle performance.
- Klipper documents TMC current as RMS amps and discourages separate hold-current reductions. The old hold-current entries have been removed.
- BIGTREETECH rates the SKR 3 heated-bed output at 10 A. Plus and Max installers must verify the actual bed load and use a correctly rated external MOSFET when necessary.
- A harness is not assumed plug-and-play merely because its connector fits. Voltage, polarity, coil pairs, and pin order must be checked.

## Quick install outline

1. Back up all of `~/printer_data/config` and the existing SAVE_CONFIG values.
2. Extract only the ZIP matching the printer and controller.
3. Read `START_HERE.md` and, for SKR builds, `WIRING_AND_FIRMWARE.md` completely.
4. Copy the **contents** of the packaged `config/` directory into `~/printer_data/config`, preserving its folders. Keep `printer.cfg` in the root.
5. For SKR builds, replace `REPLACE_WITH_YOUR_SKR3_EZ_ID` with the exact result of `ls /dev/serial/by-id/`.
6. Verify thermistors, endstops, TMC SPI, each motor direction, probe state, fans, and heaters before the first `G28`.
7. Calibrate PID, Z offset, mesh, extrusion rotation distance, pressure advance, and input shaper.
8. Put only the packaged `START_PRINT ...` and `END_PRINT` calls in the slicer.

## Common controls

| Command | Purpose |
|---|---|
| `MANUAL_Z_OFFSET_ADJUST` | Clean the nozzle and open Klipper's TESTZ calibration controls |
| `MANUAL_BED_TRAMMING` | Probe verified screw locations on supported models |
| `ENABLE_HEAT_SOAK` / `DISABLE_HEAT_SOAK` | Persistently enable or disable the pre-KAMP soak |
| `SET_MATERIAL MATERIAL=PETG` | Select a persistent material pressure-advance profile |
| `LOAD_FILAMENT` / `UNLOAD_FILAMENT` | Guided filament handling |
| `M600` / `RUNOUT_RESUME` | Color-change and runout recovery |
| `CALIBRATE_SHAPER` | Quick two-axis calibration; bed-slingers with one movable sensor should follow the per-axis documentation |
| `BED_PID_TUNE TEMP=60` | Tune and save the bed PID |
| `NOZZLE_PID_TUNE TEMP=230 FAN_SPEED=0` | Tune and save the hotend PID |
| `MAINTENANCE_STATUS` | Show print and service counters |

KlipperScreen's **Move** panel also includes **Disable Motors** beside **Home**. Releasing the motors clears the trusted position, so home again before moving or printing.

## Validation

All four SKR ZIPs were extracted after creation and checked for missing includes, duplicate Klipper sections, legacy hold-current/stealthChop values, MCU placeholders, required TMC sections, and accidental machine-specific SAVE_CONFIG blocks. Structural validation cannot replace electrical inspection or a controlled commissioning test on each physical printer.

## Credits

Package integration, Maxout hardware baseline, motor-upgrade workflow, feature design, guides, and project maintenance by **HDR Performance**.

This project builds on [Klipper](https://www.klipper3d.org/), [BIGTREETECH SKR 3](https://github.com/bigtreetech/SKR-3), and [Klipper Adaptive Meshing & Purging](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging). Those projects retain their own authorship and licenses.

These are community modification packages, not official Elegoo, BIGTREETECH, Klipper, Micro Swiss, Mainsail, or KAMP releases.

## License

This repository is distributed under the [GNU General Public License v3.0](LICENSE). Third-party projects and bundled components retain their own authorship and license terms.
