# BIGTREETECH Pad 7 with Raspberry Pi CM4

This section is specifically for a BTT Pad 7 whose original CB1 has been replaced by a Raspberry Pi CM4. Generic Raspberry Pi 4/CM4 host instructions are kept in [their own guide](13-raspberry-pi4-cm4-klipper-host.md).

The tested screen-rotation and touchscreen controls now support both the original CB1 and a CM4. Their shared installation, mapping table, source-code links, and recovery instructions are in the dedicated [Pad 7 display and touchscreen guide](15-pad7-display-touch-controls.md).

## Pad 7 CM4 baseline

The HDR CM4 setup uses:

- Native Pad 7 panel at 1024 x 600 and 60 Hz
- `KlipperScreen.service` on X11 display `:0`
- BTT-HDMI7 USB-HID touchscreen
- Linux Klipper host MCU at `/tmp/klipper_host_mcu`
- Pad 7 ADXL345 through the CM4 host as `spidev0.1`
- LCD backlight on GPIO14
- Pad 7 built-in speaker through the CM4 HDMI0 audio device

The package installer adapts `[mcu CB1]`, `CB1:None`, and `spidev1.1` to the CM4 equivalents. The one-time operating-system setup still must be completed on the Pad.

The Neptune Maxout theme installer also enables HDMI audio and installs original laser-style button feedback. On CM4 it now reproduces the hardware-tested PipeWire/WirePlumber setup: HDMI0 is selected, the sink is set to full volume, and HDMI suspension is disabled so short button sounds play immediately. CM4 and CB1 audio behavior, verification, and recovery are documented in the dedicated [Pad 7 sound guide](17-pad7-sound.md).

## Motor controls after homing

Stepper motors normally remain energized after `G28`. Holding current keeps the gantry and bed from drifting, so this is expected and is not a failed homing cycle.

KlipperScreen already provides a protected release control in the same **Move** panel:

1. Open **Move**.
2. Use **Home**, then **Home All**.
3. Return to the Move panel if the homing selector is still open.
4. Tap **Disable Motors**, the motor-off icon beside **Home**.
5. Confirm the warning.

KlipperScreen sends `M18`. Releasing a stepper invalidates the trusted position. Always home again before a controlled move or print. Do not add `M18` automatically to the end of `G28`; that would make the homing result unusable and can allow Z to drift.

## Install screen and touchscreen rotation

The HDR rotation add-on rotates the X11 display and the digitizer calibration matrix together. It also creates timestamped backups before replacing an existing HDR rotation file.

Physical testing of the BTT-HDMI7/Xorg combination shows that its landscape layouts need no additional digitizer correction, while its portrait layouts need a 180-degree correction. The installer stores `HDR_PAD7_LANDSCAPE_TOUCH_OFFSET="0"` and `HDR_PAD7_PORTRAIT_TOUCH_OFFSET="180"`, then composes the applicable value with the selected display rotation. A 90-degree clockwise display therefore uses a 270-degree touch matrix, while Original Landscape uses the identity matrix.

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/tools/install-pad7-ui.sh -o install-pad7-ui.sh
less install-pad7-ui.sh
chmod +x install-pad7-ui.sh
./install-pad7-ui.sh
```

After installation, use:

```text
More > Screen Rotation
```

Choose **Original Landscape**, **Portrait Right**, **Inverted Landscape**, or **Portrait Left**. These are explicit settings: selecting Portrait Right again keeps the screen at 90 degrees instead of advancing it another 90 degrees. **Original Landscape** always restores the factory screen orientation. KlipperScreen restarts so it can change between landscape and portrait layouts. This does not restart Klipper or move the printer.

The installer keeps KlipperScreen's original **Macros** button and standard
searchable, scrolling macro list. Macro parameter fields and KlipperScreen's
normal macro settings remain available. Stable commands such as
`MANUAL_Z_OFFSET_ADJUST`, `LOAD_FILAMENT`, and `SPEED_PROFILE_NORMAL` keep their
original identifiers for slicer compatibility. Calibration features already
available in **More** remain there.

Under **More**, the installer hides KlipperScreen's stock **Z Calibrate** shortcut and replaces it with **Z Calibrate + Clean**. The replacement uses its own menu ID so it cannot inherit the stock `panel: zcalibrate` action and accidentally bypass `MANUAL_Z_OFFSET_ADJUST`. It runs the homing, nozzle-heating, left-side purge/wipe, heater shutdown, and positioning sequence first. When the macro enters manual-probe mode, KlipperScreen automatically opens the normal TESTZ adjustment panel.

To force a known orientation over SSH:

```text
sudo hdr-pad7-rotate 0
sudo hdr-pad7-rotate 90
sudo hdr-pad7-rotate 180
sudo hdr-pad7-rotate 270
```

The tool writes:

- `/etc/X11/xorg.conf.d/90-hdr-pad7-monitor.conf`
- `/etc/X11/xorg.conf.d/91-hdr-pad7-touchscreen.conf`
- `/etc/hdr-pad7-rotation.state`
- `/etc/systemd/system/hdr-pad7-rotate-{0,90,180,270}.service`
- a marked custom menu block before KlipperScreen's auto-generated section in `~/printer_data/config/KlipperScreen.conf`

## Verify rotation over SSH

```text
DISPLAY=:0 xrandr --query
DISPLAY=:0 xinput list-props "BIQU BTT-HDMI7"
cat /etc/hdr-pad7-rotation.state
```

At display rotation 0, the output should be 1024 x 600 and **Coordinate Transformation Matrix** should be the identity matrix. At display rotation 90, X11 reports a 600 x 1024 desktop and the touch matrix uses 270 degrees. At display rotation 180, both the display and touch matrix use 180 degrees. The add-on uses one Xorg `TransformationMatrix`; it removes the older HDR udev calibration rule to prevent conflicting or ineffective transformations.

## Recovery if touch or picture orientation is wrong

SSH still works even if the local touchscreen is inconvenient. Reset both display and touch to normal landscape:

```text
sudo hdr-pad7-rotate 0
```

If KlipperScreen does not return:

```text
sudo systemctl restart KlipperScreen
systemctl status KlipperScreen --no-pager
```

The rotation feature changes only the Pad display stack. It does not alter the printer MCU, stepper settings, heaters, or homing configuration.

Return to the [documentation index](README.md).
