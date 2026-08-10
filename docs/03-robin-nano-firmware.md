# Robin Nano firmware with a BTT Pad 7

This guide modernizes the original Neptune 3 Max Robin Nano firmware instructions. Use it only with the stock ZNP Robin Nano v2.2 controller and a package whose `printer.cfg` matches that board.

> [!WARNING]
> Do not use these build settings for an SKR 3 EZ. The two controllers use different processors, bootloaders, file names, communication interfaces, and pin maps.

## What you need

- BTT Pad 7 connected to the network
- SSH access to the Pad 7
- A FAT32-formatted microSD card
- A complete backup of `~/printer_data/config`
- The correct Robin Nano package from this repository

## Connect to the Pad 7

Find the Pad 7 IP address in its network screen or router. From Windows, connect with PowerShell, Windows Terminal, or PuTTY:

```text
ssh biqu@PAD7_IP_ADDRESS
```

Use the credentials configured on the Pad 7. Change default credentials if they are still active.

## Build the firmware

```text
cd ~/klipper
make clean
make menuconfig
```

The legacy Neptune 3 Max Robin Nano v2.2 build used:

- Architecture: STM32
- Processor: STM32F401
- Flash size: 256 KiB
- Bootloader: 32 KiB
- Communication: the serial interface matching the printer's actual Pad 7 connection
- Baud: 250000 for the documented UART setup

The old guide listed USART1 PA10/PA9 and USART2 PA3/PA2 as different wiring choices. Select only the interface actually connected on your printer. If the packaged configuration uses `/dev/ttyUSB0`, confirm how the board is connected before rebuilding firmware.

Save the menu configuration, then build:

```text
make
cp ~/klipper/out/klipper.bin ~/klipper/out/ZNP_ROBIN_NANO.bin
```

## Flash the board

1. Copy `ZNP_ROBIN_NANO.bin` to the root of a clean FAT32 microSD card.
2. Shut the printer down and disconnect power.
3. Insert the card into the controller's SD slot.
4. Apply power and allow the board time to flash.
5. Power down and remove the card.
6. Reconnect the controller to the Pad 7 and restart Klipper.

Manual SD flashing is expected for this board; do not assume `make flash` is supported.

## If the MCU does not connect

- Verify the controller really is the expected Robin Nano revision.
- Recheck the selected communication interface against the physical connection.
- Check `klippy.log` for the exact serial error.
- Confirm the Pad 7 sees the USB/UART adapter with `ls /dev/serial/by-id/` and `ls /dev/ttyUSB*`.
- Rebuild from a clean tree rather than reusing an unknown prebuilt binary.

Continue with the [commissioning checklist](05-commissioning-checklist.md).

Return to the [documentation index](README.md).
