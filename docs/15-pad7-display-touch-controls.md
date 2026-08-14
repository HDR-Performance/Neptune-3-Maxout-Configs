# Pad 7 display and touchscreen controls (CB1 and CM4)

This feature supports both versions of the BIGTREETECH Pad 7:

- the stock Pad 7 with its original CB1
- a Pad 7 upgraded to a Raspberry Pi CM4

The HDR package installer enables these controls automatically when it detects KlipperScreen, the Pad 7's 1024 x 600 display, and the BTT-HDMI7 touchscreen. Other Klipper hosts are left unchanged.

## What the automatic setup adds

- A top-level **Macros** button in KlipperScreen
- **Disable Motors** in the Move panel through KlipperScreen's protected `M18` control
- Four fixed screen-orientation choices under **More > Screen Rotation**
- Matching X11 touchscreen calibration for every orientation
- Persistent selection across KlipperScreen and Pad restarts
- Automatic installation of the optional [Neptune Maxout visual theme](16-neptune-maxout-klipperscreen-theme.md) through the main package installer

The four choices are explicit. Selecting the same orientation twice keeps that orientation; it does not rotate another 90 degrees.

| KlipperScreen choice | Display angle | Effective touch angle | Expected desktop |
|---|---:|---:|---:|
| Original Landscape | 0 | 0 | 1024 x 600 |
| Portrait Right | 90 | 270 | 600 x 1024 |
| Inverted Landscape | 180 | 180 | 1024 x 600 |
| Portrait Left | 270 | 90 | 600 x 1024 |

Physical Pad 7 testing established that both landscape positions use the normal touch mapping. Both portrait positions require an additional 180-degree digitizer correction. The installer therefore stores:

```text
HDR_PAD7_LANDSCAPE_TOUCH_OFFSET="0"
HDR_PAD7_PORTRAIT_TOUCH_OFFSET="180"
```

## Default package installation

The normal GitHub installer uses `--pad7-ui auto` by default:

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/install.sh -o hdr-neptune-install.sh
chmod +x hdr-neptune-install.sh
./hdr-neptune-install.sh
```

`auto` installs the controls only after finding the real Pad 7 display and touchscreen. This works with either the CB1 or CM4 host board. On the first installation, **Original Landscape** is the default. Reinstalling preserves the last explicitly selected orientation.

Optional installer controls:

```text
# Require the Pad 7 UI setup; stop with an error if its display stack is unavailable
./hdr-neptune-install.sh --package neptune3max-robin --pad7-ui on

# Install printer configuration without changing KlipperScreen or display settings
./hdr-neptune-install.sh --package neptune3max-robin --pad7-ui off

# Keep the display controls but leave the current visual theme unchanged
./hdr-neptune-install.sh --package neptune3max-robin --pad7-theme off
```

## Install or repair only the Pad 7 controls

This does not replace `printer.cfg` and is safe to use after a normal package installation:

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/tools/install-pad7-ui.sh -o install-pad7-ui.sh
chmod +x install-pad7-ui.sh
./install-pad7-ui.sh
```

If you want only rotationâ€”without the Maxout macro/menu additionsâ€”use the dedicated [standalone rotation installer](19-pad7-rotation-only.md).

The implementation is published for review:

- [`tools/install-pad7-ui.sh`](../tools/install-pad7-ui.sh) detects the display and touchscreen, creates the services, and adds the KlipperScreen menu entries.
- [`tools/hdr-pad7-rotate`](../tools/hdr-pad7-rotate) composes the display rotation with the correct landscape or portrait touch offset.

## Use the controls

On the Pad 7:

1. Open **More**.
2. Open **Screen Rotation**.
3. Choose the exact orientation wanted.
4. Allow KlipperScreen a few seconds to restart.
5. Test all four touchscreen corners.

To release energized steppers after homing, open **Move**, tap **Disable Motors**, and confirm. Releasing the motors clears Klipper's trusted position, so home again before moving or printing.

## SSH recovery and verification

Reset to the factory landscape orientation:

```text
sudo hdr-pad7-rotate 0
```

Select a known orientation directly:

```text
sudo hdr-pad7-rotate 0
sudo hdr-pad7-rotate 90
sudo hdr-pad7-rotate 180
sudo hdr-pad7-rotate 270
```

Inspect the active display and touch mappings:

```text
DISPLAY=:0 xrandr --query
DISPLAY=:0 xinput list-props "BIQU BTT-HDMI7"
cat /etc/hdr-pad7-rotation.state
cat /etc/default/hdr-pad7-rotation
```

The setup changes only KlipperScreen, X11 display/touch calibration, and its four orientation services. It does not change printer MCU pins, heaters, homing, motion limits, or stepper currents.

Return to the [documentation index](README.md).
