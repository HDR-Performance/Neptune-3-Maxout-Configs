# Pad 7 CM4/SKR USB recovery and package-specific OTA updates

## The CM4-specific USB problem

On the tested Pad 7 upgraded to a Raspberry Pi CM4, the SKR 3 EZ USB MCU could
appear after Klipper had already started. Klipper would then remain disconnected
until services or the entire Pad were restarted. This is a host startup/reconnect
timing problem; it is not corrected by changing stepper, heater, or motion pins.

For an SKR package, the main installer now uses `--skr-usb auto`. Automatic mode
installs the recovery only when the selected controller is SKR 3 EZ and the host
is detected as a CM4. It does not change CB1 or ordinary Raspberry Pi 4 hosts.

The recovery:

1. Uses the printer's stable `/dev/serial/by-id/...` identity.
2. Makes Klipper wait up to 60 seconds for that MCU during host startup.
3. Restarts Klipper when that exact USB MCU reconnects.
4. Backs up any earlier HDR recovery files before replacing them.

Install it directly after connecting and flashing the SKR:

```text
ls -l /dev/serial/by-id/
curl -fsSL https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main/tools/install-skr-usb-recovery.sh -o ~/install-skr-usb-recovery.sh
chmod +x ~/install-skr-usb-recovery.sh
~/install-skr-usb-recovery.sh /dev/serial/by-id/YOUR_ACTUAL_SKR_ID
```

Never copy another printer's example ID. The installer derives the udev identity
from the connected board and targets only that MCU.

Use `--skr-usb off` when installing the main package to leave system services and
udev rules unchanged. Use `--skr-usb on` to require the recovery on a non-CM4
host when diagnosing the same proven reconnect behavior.

## Mainsail/Moonraker Update Manager

New installations register a standard entry named `Neptune-Maxout-Configs` in
Moonraker's Update Manager. Its clean Git checkout is stored at:

```text
~/Neptune-3-Maxout-Configs
```

The checkout is intentionally outside `~/printer_data/config`, preventing the
overlapping inotify-watch warning. When the user presses **Update**, Moonraker
pulls the repository and then invokes `tools/moonraker-update-hook.sh`. The hook
runs the same package-aware `update.sh --yes` workflow described below, using
the package identity recorded during installation.

Moonraker currently supports `install_script` for `git_repo` extensions but
marks it deprecated. The hook is isolated in one file so it can be replaced if
Moonraker removes that compatibility option in a future release. Use
`--moonraker-updater off` to skip this registration.

The registrar supports `HDR_BRANCH` for maintainer testing. Normal users should
leave it unset so the checkout and Update Manager remain pinned to `main`.

## Package-specific over-the-air updates

The main installer leaves this helper in the user's home directory:

```text
~/hdr-neptune-update.sh
```

Update the exact application recorded by the original installer:

```text
~/hdr-neptune-update.sh
```

The updater reads `package_id` from `.hdr-performance-install`; it does not
guess from bed size or pin names. A package can also be selected explicitly:

```text
~/hdr-neptune-update.sh --package neptune3max-skr3ez
```

If the installation marker is missing, the package ID is mandatory. This
prevents a Neptune 3 Max/SKR system from silently receiving Neptune 3 Pro,
Plus, Robin Nano, or other controller files.

The normal OTA mode updates only:

- `custom/`
- `KAMP_Settings.cfg`
- `HDR_Documentation/`

On a detected Pad 7, it also refreshes by default:

- The four screen-orientation controls
- The matching touchscreen/digitizer transformations
- The Neptune Maxout landscape and portrait theme assets
- The platform-correct CB1 or CM4 sound integration and laser button feedback
- Moonraker object processing and the known overlapping KAMP updater repair
- The CM4/SKR USB boot-wait and reconnect recovery on that exact host/controller combination

The hardware check prevents a normal Raspberry Pi 4 without the Pad 7 display
from receiving Pad-specific display changes. To preserve a custom UI or theme:

```text
~/hdr-neptune-update.sh --pad7-ui off --pad7-theme off
```

Use `--pad7-ui on` or `--pad7-theme on` when the feature must be installed and
the update should stop with an error if that required installation fails.

It preserves `printer.cfg`, saved calibration, `moonraker.conf`, `mainsail.cfg`,
`KlipperScreen.conf`, the updater-managed `KAMP/` directory, and other host files.
A timestamped backup is created before anything is replaced.

Advanced users may deliberately include the package's new `printer.cfg`:

```text
~/hdr-neptune-update.sh --package neptune3max-skr3ez --include-printer-cfg
```

That option preserves an existing stable SKR `/dev/serial/by-id/...` line, but
all Z offset, PID, rotation-distance, thermistor, current, and other machine
specific values must still be reviewed before issuing `RESTART`.

