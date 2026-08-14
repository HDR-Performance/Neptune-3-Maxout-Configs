# Pad 7 CM4/CB1 sound and Neptune Maxout laser feedback

The Neptune Maxout theme includes an original short retro toy-laser chirp for KlipperScreen button presses. It supports both Pad 7 host choices:

- **CM4:** audio is sent through HDMI0 to the Pad 7 display controller, then to its built-in amplifier and speaker. The tested setup uses PipeWire and WirePlumber so short interface sounds are not lost while the HDMI device wakes.
- **CB1:** the installer reuses the original Pad 7 `/etc/scripts/ks_click.sh` and SoX/ALSA speaker path, replacing only the click audio with the Maxout laser WAV. It does not install CM4 PipeWire settings or add a duplicate GTK click hook.

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

1. Requires an existing KlipperScreen installation. CB1 reuses its factory SoX/ALSA click scripts; CM4 installs the tested PipeWire/WirePlumber audio stack when it is missing.
2. Installs `maxout-laser.wav` under `/usr/local/share/neptune-maxout/sounds/`.
3. On CB1, backs up `/etc/scripts/sound.sh` and points its existing click hook at the laser WAV.
4. On CM4, installs a non-blocking player and backs up/hooks `KlippyGtk.py`, so standard buttons and macro buttons use the same feedback.
5. On CM4 only, installs a WirePlumber rule that keeps the HDMI node ready for short sounds by setting `session.suspend-timeout-seconds = 0` and `node.pause-on-idle = false`.
6. On CM4 only, enables the PipeWire, PipeWire-Pulse, and WirePlumber user services; selects HDMI0; and sets the sink to 100%.
7. On CM4 only, backs up the active boot config and changes `hdmi_drive=1` to `hdmi_drive=2` so the Pad 7 HDMI audio path is enabled.
8. Compiles the modified Python file before restarting KlipperScreen.

If the CM4 HDMI mode changed, reboot the Pad once:

```text
sudo reboot
```

## Test and troubleshoot

Play the sound directly:

```text
/usr/local/bin/hdr-maxout-sound
```

Confirm the CM4 audio services and HDMI sink:

```text
systemctl --user is-active pipewire pipewire-pulse wireplumber
wpctl status -n
wpctl get-volume @DEFAULT_AUDIO_SINK@
```

All three services should report `active`. The default sink (marked with `*`) should be the first HDMI controller, normally named similar to `alsa_output.platform-fef00700.hdmi.hdmi-stereo`, and the volume should show `1.00`. The CM4 helper uses `pw-play`; CB1 retains its normal ALSA output.

The tested CM4 WirePlumber settings are stored in:

```text
~/.config/wireplumber/wireplumber.conf.d/51-hdr-pad7-hdmi.conf
```

If the direct test works but buttons do not make sound, verify that KlipperScreen is using `theme: neptune-maxout`, then re-run the standalone installer to restore the button hook after a KlipperScreen update.

The helper only plays when `theme: neptune-maxout` is selected in `KlipperScreen.conf`. Changing to another KlipperScreen theme therefore makes the UI silent without deleting the sound files or source backup.

## Expected CM4 KlipperScreen dirty warning

On a Pad 7 CM4, Mainsail may label **KlipperScreen** as **DIRTY** and report:

```text
Repo is dirty. Detected the following modified files: ['ks_includes/KlippyGtk.py']
```

This warning is expected because the CM4 laser-button integration adds its
small click-sound hook to KlipperScreen's central button factory. It is safe to
ignore **only when `ks_includes/KlippyGtk.py` is the sole modified tracked
file** and the change came from this installer. Do not dismiss additional or
unrecognized modified files.

KlipperScreen **Soft Recovery** or **Hard Recovery** restores the upstream file
and removes the CM4 button-sound hook. After recovery or a KlipperScreen update,
rerun the Neptune Maxout theme installer to restore the tested theme and sound.
The CB1 uses its factory external ALSA click script and normally does not modify
`KlippyGtk.py`.

## Recovery

The installer creates these recoverable backups before editing:

- `~/KlipperScreen/ks_includes/KlippyGtk.py.hdr-audio-backup-YYYYMMDD-HHMMSS`
- `~/.config/wireplumber/wireplumber.conf.d/51-hdr-pad7-hdmi.conf.hdr-audio-backup-YYYYMMDD-HHMMSS` when an older HDR audio rule existed
- `/boot/firmware/config.txt.hdr-audio-backup-YYYYMMDD-HHMMSS` on current Raspberry Pi OS, or the matching `/boot/config.txt` path on older images

Restore the newest `KlippyGtk.py` backup and restart KlipperScreen if a later upstream KlipperScreen update changes its button factory. Re-run this installer after KlipperScreen updates to restore the theme sound hook against the new source.

Return to the [documentation index](README.md).

