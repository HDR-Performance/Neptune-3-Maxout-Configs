# Simple Raspberry Pi 4 SSH installation

Use this route when Klipper, Moonraker, and Mainsail run on a normal Raspberry Pi 4 rather than a BIGTREETECH Pad 7. The same Neptune printer/controller packages are used, but `--host pi4` creates the safe Pi 4 variant during installation.

## 1. Connect through SSH

Find the Raspberry Pi's address in the router, then connect using the username chosen when MainsailOS or Raspberry Pi OS was installed:

```text
ssh YOUR_USER@RASPBERRY_PI_IP
```

## 2. Identify the printer controller

```text
ls -l /dev/serial/by-id/
```

Copy the complete `/dev/serial/by-id/...` path. SKR 3 EZ users supply this to `--mcu-id`. Robin Nano packages retain their model-specific controller connection from the supplied working configuration; verify it before restarting Klipper.

## 3. Download the HDR installer

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/install.sh -o hdr-neptune-install.sh
chmod +x hdr-neptune-install.sh
```

Optional but recommended source review:

```text
less hdr-neptune-install.sh
```

## 4. Run the Pi 4 installation

Stock Robin Nano example:

```text
./hdr-neptune-install.sh \
  --package neptune3max-robin \
  --host pi4 \
  --pad7-ui off \
  --pad7-theme off
```

SKR 3 EZ example:

```text
./hdr-neptune-install.sh \
  --package neptune3max-skr3ez \
  --host pi4 \
  --pad7-ui off \
  --pad7-theme off \
  --mcu-id /dev/serial/by-id/YOUR_ACTUAL_SKR_ID
```

Change `neptune3max` to `neptune3`, `neptune3pro`, or `neptune3plus` as appropriate. Never copy the example MCU identifier literally.

The installer backs up the existing configuration, preserves Moonraker/Mainsail host files, installs the complete nested macro/KAMP directory tree, and does not restart Klipper automatically.

## What the Pi 4 variant changes

`--host pi4` removes these Pad 7-only sections from the staged `printer.cfg`:

- `[mcu CB1]` or `[mcu CM4]`
- `[adxl345]`
- `[resonance_tester]`

The saved `[input_shaper]` values remain available. Do not run `SHAPER_CALIBRATE` until a real accelerometer has been separately wired and configured for the Pi 4.

## Optional Pi 4 ADXL345 example

The common Raspberry Pi SPI0/CE0 arrangement is shown only as a starting example:

```ini
[mcu host]
serial: /tmp/klipper_host_mcu

[adxl345]
cs_pin: host:gpio8
spi_bus: spidev0.0
axes_map: x,y,z

[resonance_tester]
accel_chip: adxl345
probe_points:
    100, 100, 20
```

Pin choice, probe point, and `axes_map` must match the actual printer, wiring, and sensor orientation. Build and enable Klipper's Linux host MCU as described in the [Pi 4/CM4 host guide](13-raspberry-pi4-cm4-klipper-host.md), then require a valid `ACCELEROMETER_QUERY` before calibration.

## Final review

Before **Save & Restart**:

1. Confirm the printer model and controller package.
2. Confirm the controller serial/connection.
3. Verify that no `[mcu CB1]`, `[mcu CM4]`, or Pad 7 `spidev1.1` line remains.
4. Read `HDR_Documentation/START_HERE.md` and follow the commissioning checklist.

Return to the [documentation index](README.md).
