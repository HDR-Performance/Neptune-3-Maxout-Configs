# Standalone Pad 7 screen rotation for CB1 and CM4

This installer adds the four tested Pad 7 display orientations and matching touchscreen mappings without installing or replacing any printer configuration.

Supported hosts:

- stock BIGTREETECH Pad 7 with CB1 (`BQ-H616`)
- Pad 7 upgraded to Raspberry Pi CM4

It installs only the rotation helper, four explicit KlipperScreen choices, persistent boot restoration, and X11 display/touch calibration. It does not install KAMP, printer macros, a theme, audio changes, MCU firmware, or `printer.cfg`.

## Install over SSH

Connect to the Pad, then run:

```bash
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/tools/install-pad7-rotation.sh -o install-pad7-rotation.sh
chmod +x install-pad7-rotation.sh
./install-pad7-rotation.sh
```

The installer detects the connected X11 display and BTT-HDMI7 touchscreen, makes timestamped backups, and preserves the currently saved HDR orientation when reinstalling. A first-time installation starts in Original Landscape; select another orientation from KlipperScreen afterward.

## Use

Open **More > Screen Rotation** and select one explicit position:

- Original Landscape
- Portrait Right
- Inverted Landscape
- Portrait Left

Selecting an entry twice keeps that orientation. It does not rotate another 90 degrees.

The tested Pad 7 mapping uses a normal touch offset in landscape and a 180-degree layout correction in portrait. The installer also avoids applying the portrait matrix twice on CB1, which otherwise makes touch appear mirrored and vertically flipped.

## SSH recovery

If touch alignment makes the menu difficult to use, SSH into the Pad and run one of:

```bash
sudo hdr-pad7-rotate 0
sudo hdr-pad7-rotate 90
sudo hdr-pad7-rotate 180
sudo hdr-pad7-rotate 270
```

Verify the active state:

```bash
cat /etc/hdr-pad7-rotation.state
DISPLAY=:0 xrandr --query
DISPLAY=:0 xinput list-props "BIQU BTT-HDMI7"
```

Project and testing credit: **HDR Performance / Neptune Maxout**.
