# BTT Pi V1.2 with a standard HDMI touchscreen

This host option is for a standalone BIGTREETECH BTT Pi V1.2 connected to a
normal HDMI/USB touchscreen. It is not a Pad 7 and must not inherit the Pad 7's
onboard ADXL345, screen rotation, touchscreen mapping, theme-audio, or speaker
configuration.

BIGTREETECH documents that the BTT Pi uses the same OS image and configuration
family as the CB1. For that reason, host auto-detection may report a standalone
BTT Pi as a CB1. Always pass `--host btt-pi` explicitly for this installation.

Official references:

- [BIGTREETECH BTT Pi repository](https://github.com/bigtreetech/BTT-Pi)
- [BIGTREETECH Pi V1.2 user manual](https://github.com/bigtreetech/BTT-Pi/blob/master/BIGTREETECH%20Pi%20V1.2%20User%20Manual.pdf)

## Neptune 3 Pro stock-controller installation

After installing Klipper, Moonraker, and Mainsail on the BTT Pi, connect over
SSH and run the dedicated installer:

```bash
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/install-btt-pi-neptune3pro.sh -o install-btt-pi-neptune3pro.sh
less install-btt-pi-neptune3pro.sh
chmod +x install-btt-pi-neptune3pro.sh
./install-btt-pi-neptune3pro.sh
```

This wrapper fixes the selection to Neptune 3 Pro + stock Robin Nano and forces
`--host btt-pi`, `--pad7-ui off`, `--pad7-theme off`, `--skr-usb off`, and
`--moonraker-updater off`. It still
uses the normal confirmation, checksum, backup, ZIP-safety, installation, and
restore workflow.

If KlipperScreen is installed, the universal **Bed Screw Location** panel is
added. It asks whether physical adjusters exist and accepts 4, 5, or 6. A stock
fixed-bed Neptune 3 Pro must answer No; a converted machine can teach the probe
positions interactively instead of inheriting guessed coordinates.

Do not use this dedicated wrapper if the printer controller has also been
replaced. Choose the package matching that controller through the main installer.

## What the BTT Pi adaptation changes

Before installing the staged configuration, it removes:

- the Pad 7 `[mcu CB1]` or `[mcu CM4]` host-MCU block;
- the Pad 7 `[adxl345]` block;
- the associated `[resonance_tester]` block;
- the `CALIBRATE_SHAPER` macro that would otherwise call missing ADXL hardware.

It retains the package's saved `[input_shaper]` values so the printer can start.
Those values are only a baseline; input shaping should eventually be measured
on the user's actual modified machine.

## Update policy

This BTT Pi option is manual SSH-install only during its initial testing period.
It does not register `Neptune-Maxout-Configs` in Moonraker Update Manager. Host-
specific OTA updates remain limited to the tested Pad 7 CB1/CM4 platforms.
Re-run the reviewed SSH installer when a future BTT Pi package explicitly says
that the update applies to this hardware.

The BTT Pi does provide a dedicated connector for an optional external
ADXL345. The manual also warns that its SPI resources can conflict with other
SPI peripherals. To add the accelerometer later, create a separate host-specific
file after confirming the sensor wiring, enabled BoardEnv SPI overlay, bus,
chip-select pin, and host MCU service. Do not copy the Pad 7 `spidev1.1`
configuration onto a standalone BTT Pi.

## Standard 7-inch display

`--pad7-ui off` and `--pad7-theme off` leave the existing HDMI resolution,
touch mapping, KlipperScreen installation, audio, and theme unchanged. Display
rotation is controlled by the BTT Pi image and the particular HDMI/USB display;
the tested Pad 7 rotation matrices are not appropriate for generic screens.

## Organized macros

Package macros are stored under:

```text
~/printer_data/config/custom/macros/
```

Each macro formerly embedded in `printer.cfg` has its own named `.cfg` file.
The main file retains only explicit include lines plus the physical printer
configuration. This makes individual functions easier to inspect, replace, or
troubleshoot without editing board pins and heater settings.

## Bed leveling terminology

- `BED_MESH_CALIBRATE` probes the surface and creates a compensation mesh.
- `SCREWS_TILT_CALCULATE` requires a correct `[screws_tilt_adjust]` section and
  physical adjustment screws at the configured coordinates.

The main installer never assumes that a Neptune 3 or Neptune 3 Pro has manual
adjusters. Before saving each location, visually confirm that the probe—not
merely the nozzle—is centered above the physical adjuster.
