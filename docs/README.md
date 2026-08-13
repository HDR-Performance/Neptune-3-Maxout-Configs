# HDR Performance Neptune 3 documentation

This documentation consolidates the useful material from the two original HDR Performance repositories and rewrites it around the current packages in this repository.

## Start here

1. [Choose the correct package](01-choose-the-correct-package.md)
2. Install with either method:
   - [Easy SSH installer from GitHub](12-ssh-installer.md)
   - [Manual configuration package installation](02-install-a-package.md)
3. Read the firmware guide for your controller:
   - [Robin Nano firmware](03-robin-nano-firmware.md)
   - [SKR 3 EZ firmware and controller conversion](04-skr3ez-conversion.md)
4. [Commission the printer safely](05-commissioning-checklist.md)
5. [Configure KAMP](06-kamp-setup.md)
6. [Calibrate input shaper with the Pad 7](07-input-shaper.md)
7. [Configure the slicer](08-slicer-gcode.md)
8. [Learn the added macros and controls](09-feature-guide.md)
9. Choose the matching host guide:
   - [Raspberry Pi 4 or generic CM4 Klipper host](13-raspberry-pi4-cm4-klipper-host.md)
   - [BIGTREETECH Pad 7 with CM4 host setup](14-pad7-cm4-klipperscreen.md)
   - [Pad 7 CB1/CM4 display and touchscreen controls](15-pad7-display-touch-controls.md)

## Upgrade and repair guides

- [Neptune 3 Max X/Y stepper-motor upgrade](10-stepper-motor-upgrade.md)
- [Moonraker recovery and general troubleshooting](11-troubleshooting.md)
- [Pad 7 CM4 motor-release and screen-rotation controls](14-pad7-cm4-klipperscreen.md)
- [Pad 7 CB1/CM4 display rotation and touchscreen mapping](15-pad7-display-touch-controls.md)

## What changed from the legacy guides

The original instructions were valuable working notes, but several details needed clearer boundaries or technical corrections:

- Robin Nano and SKR 3 EZ firmware are now separate guides.
- A connector is never declared compatible from its shape alone. Voltage, polarity, pin order, and current must be verified.
- The SKR 3 MCU may be an STM32H723 or STM32H743; the physical chip marking decides the build target.
- PB9 is not used as the overhead-light output. The SKR packages use the board's controlled fan outputs.
- `stealthchop_threshold: 0` is used for spreadCycle performance. A very large threshold enables stealthChop rather than disabling it.
- TMC5160 current values are documented as RMS current, and separate hold-current reductions are not used.
- A single accelerometer must be moved between the toolhead and bed when calibrating a bed-slinger's X and Y axes.
- Moonraker recovery now preserves the existing installation and begins with logs and service status instead of replacing the whole configuration blindly.

The original projects remain available for historical reference:

- [Neptune Maxout - SKR 3 EZ with TMC5160 Pro drivers](https://github.com/HDR-Performance/Neptune-Maxout-SKR-3-EZ-with-TMC5160-Pro-Drivers)
- [Neptune 3 Max - BIGTREETECH Pad 7](https://github.com/HDR-Performance/Neptune-3-Max-bigtreetech-pad-7-)

Documentation and package integration by **HDR Performance**.
