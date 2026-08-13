# Pad 7 CM4/CB1 sound and Neptune Maxout laser feedback

The Neptune Maxout theme includes an original short retro toy-laser chirp for KlipperScreen button presses. It supports both Pad 7 host choices:

- **CM4:** audio is sent through HDMI to the Pad 7 display controller, then to its built-in amplifier and speaker.
- **CB1:** the installer keeps the CB1 system's normal default speaker output.

The normal GitHub installer enables this automatically whenever it detects a Pad 7 and installs the Neptune Maxout theme. The change does not affect Klipper motion, MCU pins, heaters, or printer wiring.

## Standalone installation

On an already configured Pad 7:

```text
cd ~
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/tools/install-pad7-audio.sh -o install-pad7-audio.sh
less install-pad7-audio.sh
chmod +x install-pad7-audio.sh
./install-pad7-audio.sh
```

The installer:

1. Requires an existing KlipperScreen installation and `aplay` from `alsa-utils`.
2. Installs `maxout-laser.wav` under `/usr/local/share/neptune-maxout/sounds/`.
3. Installs a non-blocking player at `/usr/local/bin/hdr-maxout-sound`.
4. Creates a timestamped backup of `KlippyGtk.py` and hooks its central button factory, so standard buttons and macro buttons use the same feedback.
5. On CM4 only, backs up the active boot config and changes `hdmi_drive=1` to `hdmi_drive=2` so the Pad 7 HDMI audio path is enabled.
6. Compiles the modified Python file before restarting KlipperScreen.

If the CM4 HDMI mode changed, reboot the Pad once:

```text
sudo reboot
```

## Test and troubleshoot

Play the sound directly:

```text
/usr/local/bin/hdr-maxout-sound
```

Confirm the CM4 HDMI playback device:

```text
aplay -l
```

The CM4 result should include `vc4-hdmi-0`. Confirm that the display is on HDMI-A-1 and that the Pad's physical volume is raised. The sound helper uses `plughw:CARD=vc4hdmi0,DEV=0` on CM4 and the normal default ALSA device on CB1.

The helper only plays when `theme: neptune-maxout` is selected in `KlipperScreen.conf`. Changing to another KlipperScreen theme therefore makes the UI silent without deleting the sound files or source backup.

## Recovery

The installer creates these recoverable backups before editing:

- `~/KlipperScreen/ks_includes/KlippyGtk.py.hdr-audio-backup-YYYYMMDD-HHMMSS`
- `/boot/firmware/config.txt.hdr-audio-backup-YYYYMMDD-HHMMSS` on current Raspberry Pi OS, or the matching `/boot/config.txt` path on older images

Restore the newest `KlippyGtk.py` backup and restart KlipperScreen if a later upstream KlipperScreen update changes its button factory. Re-run this installer after KlipperScreen updates to restore the theme sound hook against the new source.

Return to the [documentation index](README.md).
