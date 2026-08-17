# Easy SSH installation from GitHub

The HDR Performance installer downloads the selected package directly from GitHub and preserves its complete directory structure. Users do not need to create `custom`, `macros`, `kamp`, or `state` folders manually in Mainsail.

## What the installer does

The installer also adds the standalone `hdr-speed-profile.service`. This uses
Klipper's supported remote-method API; it does not patch Klipper or Moonraker.
The service is shared by Pad 7 CB1, Pad 7 CM4, Raspberry Pi 4, and BTT Pi V1.2
hosts. Initial installation needs normal `sudo` access. Later profile changes
are made from the Klipper macro buttons while the printer is idle.

1. Shows a menu for all eight printer/controller packages.
2. Downloads the selected portable ZIP from this repository.
3. Verifies the published SHA-256 checksum and checks the ZIP before extraction.
4. Creates a timestamped backup of the complete existing config.
5. Replaces only the HDR-managed `printer.cfg`, `KAMP_Settings.cfg`, and `custom` tree.
6. Preserves other host files such as `moonraker.conf`, `mainsail.cfg`, `crowsnest.conf`, and timelapse settings.
7. Copies the package guides into `config/HDR_Documentation` for viewing in Mainsail.
8. Offers to insert the SKR MCU serial when exactly one `/dev/serial/by-id/` device is detected.
9. Detects a Raspberry Pi 4 and removes Pad 7-only host-MCU/ADXL sections so the configuration starts safely without nonexistent Pad hardware.
10. Detects a Raspberry Pi CM4 and changes the Pad 7 host-MCU/ADXL settings from `CB1`/`spidev1.1` to `CM4`/`spidev0.1`.
11. Detects the physical Pad 7 display and BTT-HDMI7 touchscreen, then installs the tested four-orientation KlipperScreen controls automatically on either CB1 or CM4.
12. Installs and selects the Neptune Maxout KlipperScreen theme by default when Pad 7 hardware is detected.
13. Does **not** restart Klipper automatically.
14. Downloads a restore helper and prints the exact backup path.

If the Pad 7 has Moonraker/Mainsail configuration but no `printer.cfg` yet, the installer explicitly reports **fresh install** mode. It backs up the existing host files and then creates the missing printer configuration and nested directories.

## Recommended installation

SSH into the Pad 7 or Raspberry Pi:

```text
ssh biqu@PAD7_IP_ADDRESS
```

Download the installer:

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/install.sh -o hdr-neptune-install.sh
```

Review it before running:

```text
less hdr-neptune-install.sh
```

Run the interactive menu:

```text
chmod +x hdr-neptune-install.sh
./hdr-neptune-install.sh
```

Select the exact printer model and controller, then type `INSTALL` when the summary is correct.

> [!WARNING]
> Robin Nano and SKR 3 EZ packages are not interchangeable. The installer cannot electrically verify wiring, probe voltage, thermistor type, heater load, motor direction, or the physical MCU.

## Test without changing files

Use dry-run mode to verify downloading and extraction:

```text
./hdr-neptune-install.sh --package neptune3max-skr3ez --dry-run --yes
```

Package IDs:

```text
neptune3-robin
neptune3pro-robin
neptune3plus-robin
neptune3max-robin
neptune3-skr3ez
neptune3pro-skr3ez
neptune3plus-skr3ez
neptune3max-skr3ez
```

List them at any time:

```text
./hdr-neptune-install.sh --list
```

## Non-interactive package selection

The package can be selected on the command line while retaining the final confirmation:

```text
./hdr-neptune-install.sh --package neptune3max-robin
```

For an SKR board, an exact serial may be supplied:

```text
./hdr-neptune-install.sh \
  --package neptune3max-skr3ez \
  --mcu-id /dev/serial/by-id/usb-Klipper_stm32h743xx_EXAMPLE-if00
```

Copy the actual result from `ls /dev/serial/by-id/`; never copy the example value.

The Pad host is detected automatically. It may also be selected explicitly:

```text
./hdr-neptune-install.sh \
  --package neptune3max-skr3ez \
  --host cm4 \
  --mcu-id /dev/serial/by-id/usb-Klipper_stm32h723xx_EXAMPLE-if00
```

Valid host values are `auto`, `cb1`, `cm4`, `pi4`, and `btt-pi`. On a Pad 7 CM4, the installer adapts the package to `[mcu CM4]`, `cs_pin: CM4:None`, and `spi_bus: spidev0.1`. With `--host pi4` or `--host btt-pi`, it removes the Pad 7 host-MCU, ADXL345, resonance-tester block, and unavailable `CALIBRATE_SHAPER` macro while retaining the saved input-shaper values. This lets a normal Pi 4 or standalone BTT Pi installation start without pretending the Pad 7's built-in accelerometer exists. See the [simple Raspberry Pi 4 SSH guide](18-raspberry-pi4-ssh-install.md) or [BTT Pi V1.2 guide](20-btt-pi-v12-standard-display.md).

Because the BTT Pi uses the CB1 software-image family, it may identify itself
as CB1 during automatic detection. Use `--host btt-pi` explicitly; do not rely
on `--host auto` for a standalone BTT Pi.

For a normal Raspberry Pi 4, the recommended one-command selection is:

```text
./hdr-neptune-install.sh --package neptune3max-robin --host pi4 --pad7-ui off --pad7-theme off
```

For a Neptune 3 Pro with its stock Robin Nano controller, a standalone BTT Pi
V1.2, and a standard HDMI touchscreen:

```bash
./hdr-neptune-install.sh --package neptune3pro-robin --host btt-pi --pad7-ui off --pad7-theme off
```

Replace the package ID with the exact printer/controller combination. SKR users must also provide their real `--mcu-id` value.

Pad 7 screen and touch controls use `--pad7-ui auto` by default. Auto mode requires the live 1024 x 600 Pad 7 display, KlipperScreen, and BTT-HDMI7 touchscreen before it changes the UI. Use `--pad7-ui on` to require the feature or `--pad7-ui off` to leave display settings untouched. See the [Pad 7 CB1/CM4 display and touchscreen guide](15-pad7-display-touch-controls.md).

The branded theme similarly uses `--pad7-theme auto`. Theme installation includes the Pad 7 speaker setup and original Maxout laser button feedback on both CM4 and CB1. A CM4 may require the one reboot reported by the installer after HDMI audio is enabled. Use `--pad7-theme off` to retain the Pad's current theme and sound behavior, read the [Neptune Maxout theme guide](16-neptune-maxout-klipperscreen-theme.md), or use the dedicated [Pad 7 sound guide](17-pad7-sound.md).

Moonraker Update Manager registration uses `--moonraker-updater auto` by default
for every supported printer/controller package. The installed entry records the
package selected during installation, so later updates refresh that exact
Neptune model and board application instead of guessing from bed dimensions or
pin names. Use `--moonraker-updater off` to skip registration or
`--moonraker-updater on` to require it and stop if Moonraker cannot be configured

`--bed-screw-ui auto` installs the interactive KlipperScreen setup whenever
KlipperScreen is detected. Use **Bed Screw Location** and answer Yes only when
the printer physically has 4, 5, or 6 manual adjusters. Stock Neptune 3/3 Pro
fixed beds must answer No.

## OTA updates and printer.cfg replacement

Normal OTA updates preserve the current `printer.cfg` while refreshing the
selected package's managed macros, KAMP settings, documentation, Pad 7 controls,
theme, and optional panels. Use `--replace-printer-cfg` only when the exact
printer, controller, drivers, and hardware match the selected package.

The advanced replacement path displays a Klipper hardware warning, requires the
phrase `REPLACE PRINTER.CFG`, creates a complete timestamped configuration backup,
and verifies that the old `printer.cfg` in that backup is byte-for-byte identical
before overwriting anything. SKR packages retain a valid existing
`/dev/serial/by-id` MCU path when possible. Local calibration and hardware edits
may still need to be restored from the reported backup.

After every OTA update:

1. Restart Klipper only after reviewing the staged files.
2. Run **Macros > Maintenance & Setup > Post-Update Safety Check**.
3. Run **More > Z Calibrate + Clean** and verify the saved Z offset.
4. Confirm the reported input-shaper X/Y settings match this printer.
5. Home and perform a controlled low-speed movement test before printing.

## After installation

The script intentionally leaves Klipper untouched until the user reviews the files.

1. Open `printer.cfg` in Mainsail.
2. Verify the package header names the correct printer and controller.
3. For SKR, confirm the MCU serial and every board pin/wire.
4. Open `HDR_Documentation/START_HERE.md`.
5. Select **Save & Restart** only after the review.
6. Follow the [controlled commissioning checklist](05-commissioning-checklist.md).

## Restore the backup

The installer places the helper at:

```text
~/hdr-neptune-restore.sh
```

It prints the exact backup path at completion. Restore with:

```text
bash ~/hdr-neptune-restore.sh ~/printer_data/config_backups/BACKUP_DIRECTORY
```

The restore helper creates another safety backup, requires the word `RESTORE`, replaces the complete config with the selected backup, and does not restart Klipper automatically.

A backup made before a fresh install may intentionally contain no `printer.cfg`. Restoring it returns the Pad 7 to that original unconfigured state.

## Manual SSH method

Users who do not want to run the installer can still preserve the folders with ordinary shell tools:

```text
cd /tmp
curl -fLO https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip
unzip Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip
cp -a ~/printer_data/config ~/printer_data/config-manual-backup
cp -a Neptune3Max-HDR-Performance-Pad7-Complete-Guide/config/. ~/printer_data/config/
```

Replace the ZIP and extracted folder names with the exact package selected from the repository. The automated installer is safer because it verifies the expected package layout and manages the backup path consistently.

Return to the [documentation index](README.md).
