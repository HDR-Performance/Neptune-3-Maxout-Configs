# Raspberry Pi 4 and generic CM4 Klipper host

This section is for a Raspberry Pi 4 or Compute Module 4 used as the Klipper host. Pad 7-specific display, touchscreen, and built-in ADXL345 details are in the separate [Pad 7 with CM4 guide](14-pad7-cm4-klipperscreen.md).

## Before installing a printer package

1. Install a current MainsailOS image appropriate for the Pi 4/CM4.
2. Complete the first-boot network and SSH setup.
3. Confirm the host has Klipper, Moonraker, and Mainsail running.
4. Back up the complete `~/printer_data/config` directory.
5. Connect the printer controller and identify it with:

   ```text
   ls -l /dev/serial/by-id/
   ```

Use the stable `/dev/serial/by-id/...` name in `[mcu]`. Do not use a temporary `/dev/ttyUSB*` name.

## Build the Linux host MCU

The Linux host MCU is needed when Klipper directly accesses host GPIO/SPI devices such as an accelerometer.

```text
cd ~/klipper
make menuconfig
```

Select **Linux process**, save, then build and install:

```text
make clean
make
sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/
sudo ./scripts/flash-linux.sh
sudo systemctl daemon-reload
sudo systemctl enable --now klipper-mcu.service
```

Verify:

```text
systemctl is-active klipper-mcu
ls -l /tmp/klipper_host_mcu
```

The Klipper configuration uses a host section such as:

```ini
[mcu host]
serial: /tmp/klipper_host_mcu
```

The MCU section name may be `host`, `CM4`, or another intentional name. Every pin reference must use the same name.

## SPI and accelerometer warning

SPI bus names and chip-select pins depend on the carrier board and wiring. A generic Pi 4/CM4 must not copy the Pad 7's `spidev0.1` setting unless its actual wiring matches. Confirm with:

```text
ls -l /dev/spidev*
```

Before running input-shaper motion, verify the accelerometer without moving the printer:

```text
ACCELEROMETER_QUERY
```

A valid response contains changing X/Y/Z acceleration values. An SPI error, constant invalid values, or a shutdown must be corrected before continuing.

## Install the HDR printer configuration

Follow the [SSH installer guide](12-ssh-installer.md). The package installer detects a CM4 and adapts the packaged Pad host block where supported. It does not guess generic carrier-board wiring.

Return to the [documentation index](README.md).
