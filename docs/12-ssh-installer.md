# Easy SSH installation from GitHub

The HDR Performance installer downloads the selected package directly from GitHub and preserves its complete directory structure. Users do not need to create `custom`, `macros`, `kamp`, or `state` folders manually in Mainsail.

## What the installer does

1. Shows a menu for all eight printer/controller packages.
2. Downloads the selected portable ZIP from this repository.
3. Verifies the published SHA-256 checksum and checks the ZIP before extraction.
4. Creates a timestamped backup of the complete existing config.
5. Replaces only the HDR-managed `printer.cfg`, `KAMP_Settings.cfg`, and `custom` tree.
6. Preserves other host files such as `moonraker.conf`, `mainsail.cfg`, `crowsnest.conf`, and timelapse settings.
7. Copies the package guides into `config/HDR_Documentation` for viewing in Mainsail.
8. Offers to insert the SKR MCU serial when exactly one `/dev/serial/by-id/` device is detected.
9. Detects a Raspberry Pi CM4 and changes the Pad 7 host-MCU/ADXL settings from `CB1`/`spidev1.1` to `CM4`/`spidev0.1`.
10. Detects the physical Pad 7 display and BTT-HDMI7 touchscreen, then installs the tested four-orientation KlipperScreen controls automatically on either CB1 or CM4.
10. Does **not** restart Klipper automatically.
11. Downloads a restore helper and prints the exact backup path.

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

Valid host values are `auto`, `cb1`, and `cm4`. On CM4, the installer adapts the package to `[mcu CM4]`, `cs_pin: CM4:None`, and `spi_bus: spidev0.1`. The CM4 Linux host-MCU service and Pad 7 boot/display settings still need to be installed once by following the BIGTREETECH Pad 7 and Klipper host-MCU guides.

Pad 7 screen and touch controls use `--pad7-ui auto` by default. Auto mode requires the live 1024 x 600 Pad 7 display, KlipperScreen, and BTT-HDMI7 touchscreen before it changes the UI. Use `--pad7-ui on` to require the feature or `--pad7-ui off` to leave display settings untouched. See the [Pad 7 CB1/CM4 display and touchscreen guide](15-pad7-display-touch-controls.md).

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
