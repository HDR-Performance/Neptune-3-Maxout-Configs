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
   - [Pad 7 CM4/SKR USB recovery and package-specific OTA updates](19-skr-cm4-usb-and-ota-updates.md)
4. [Commission the printer safely](05-commissioning-checklist.md)
5. [Configure KAMP](06-kamp-setup.md)
6. [Calibrate input shaper with the Pad 7](07-input-shaper.md)
7. [Configure the slicer](08-slicer-gcode.md)
8. [Learn the added macros and controls](09-feature-guide.md)
9. Choose the matching host guide:
   - [Raspberry Pi 4 or generic CM4 Klipper host](13-raspberry-pi4-cm4-klipper-host.md)
   - [Simple Raspberry Pi 4 SSH installation](18-raspberry-pi4-ssh-install.md)
   - [BIGTREETECH Pad 7 with CM4 host setup](14-pad7-cm4-klipperscreen.md)
   - [Pad 7 CB1/CM4 display and touchscreen controls](15-pad7-display-touch-controls.md)
   - [Neptune Maxout KlipperScreen theme](16-neptune-maxout-klipperscreen-theme.md)
   - [Pad 7 CM4/CB1 sound and Maxout laser feedback](17-pad7-sound.md)

## Upgrade and repair guides

- [Neptune 3 Max X/Y stepper-motor upgrade](10-stepper-motor-upgrade.md)
- [Moonraker recovery and general troubleshooting](11-troubleshooting.md)
- [Pad 7 CM4 motor-release and screen-rotation controls](14-pad7-cm4-klipperscreen.md)
- [Pad 7 CB1/CM4 display rotation and touchscreen mapping](15-pad7-display-touch-controls.md)
- [Neptune Maxout branded KlipperScreen theme](16-neptune-maxout-klipperscreen-theme.md)
- [Pad 7 CM4/CB1 speaker audio and themed button sounds](17-pad7-sound.md)
- [Standalone Pad 7 rotation installer for CB1 and CM4](19-pad7-rotation-only.md)
- [Safe Raspberry Pi 4 host adaptation and SSH install](18-raspberry-pi4-ssh-install.md)

## What changed from the legacy guides

The original instructions were valuable working notes, but several details needed clearer boundaries or technical corrections:

- Robin Nano and SKR 3 EZ firmware are now separate guides.
- A connector is never declared compatible from its shape alone. Voltage, polarity, pin order, and current must be verified.
- The SKR 3 MCU may be an STM32H723 or STM32H743; the physical chip marking decides the build target.
- PB9 is not used as the overhead-light output. The SKR packages use the board's controlled fan outputs.
- The Neptune 3 Max SKR 3 EZ package uses the quieter, printer-tested TMC5160 StealthChop settings from the CB1 Pad 7 configuration. High-speed limits still require mechanical testing.
- TMC5160 run and hold currents are documented as RMS current and match the proven Maxout motor configuration.
- A single accelerometer must be moved between the toolhead and bed when calibrating a bed-slinger's X and Y axes.
- Moonraker recovery now preserves the existing installation and begins with logs and service status instead of replacing the whole configuration blindly.

The original projects remain available for historical reference:

- [Neptune Maxout - SKR 3 EZ with TMC5160 Pro drivers](https://github.com/HDR-Performance/Neptune-Maxout-SKR-3-EZ-with-TMC5160-Pro-Drivers)
- [Neptune 3 Max - BIGTREETECH Pad 7](https://github.com/HDR-Performance/Neptune-3-Max-bigtreetech-pad-7-)

Documentation and package integration by **HDR Performance**.
