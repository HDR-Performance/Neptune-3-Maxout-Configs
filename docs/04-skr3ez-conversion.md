# SKR 3 EZ and TMC5160 Pro conversion

This is the refined version of the original Neptune Maxout controller-conversion guide. It applies to the HDR Maxout packages, not the stock Robin Nano packages.

## Required hardware

- BIGTREETECH SKR 3 EZ
- Four TMC5160 Pro EZ drivers
- BTT Pad 7 or another supported Klipper host
- Adequate driver and enclosure cooling
- Correct fusing, terminals, wire sizes, and strain relief
- An external heated-bed MOSFET when the measured bed load requires one

## Electrical safety

Disconnect AC power before opening the electronics enclosure. Photograph and label every original connection.

> [!DANGER]
> Matching connector shells do not prove compatibility. Verify voltage, polarity, pin order, stepper coil pairs, signal level, and current capacity before connecting anything.

The SKR 3 heated-bed output is rated at 10 A. For a 24 V bed, measure resistance with power disconnected and estimate current with `current = 24 / resistance`. Leave suitable safety margin. Large Plus and Max beds may require a correctly rated external MOSFET and wiring.

The controlled fan outputs share the voltage selected by the board's fan-voltage jumper. Set that jumper before connecting the fans or 24 V light.

## Package pin map

| Device | Connection | MCU pins used by the package |
|---|---|---|
| X motor/driver | X-MOT | step PD4, dir PD3, enable PD6, CS PD5 |
| Y motor/driver | Y-MOT | step PA15, dir PA8, enable PD1, CS PD0 |
| Both Z motors | Z-MOT through verified split harness | step PE2, dir PE3, enable PE0, CS PE1 |
| Extruder | E0-MOT | step PD15, dir PD14, enable PC7, CS PC6 |
| X endstop | X-STOP | PC1 |
| Y endstop | Y-STOP | PC3 |
| Pro/Plus/Max probe | Z-STOP | PC0 |
| Standard Neptune 3 strain-gauge signal | PROBE after interface verification | PC13 |
| Filament sensor | E0-DET/FIL-DET | PC2 |
| Hotend heater | HE0 | PB3 |
| Bed/MOSFET trigger | BED | PD7 |
| Hotend thermistor | TH0 | PA2 |
| Bed thermistor | THB | PA1 |
| Optional 24 V light | FAN0 | PB7 |
| Part-cooling fan | FAN1 | PB6 |
| Hotend fan | FAN2 | PB5 |

PB9 is FDCAN transmit on this board and is not used as the light output.

## Install the TMC5160 Pro EZ drivers

1. Remove power and wait for capacitors to discharge.
2. Set the driver voltage selection exactly as required by the driver and board documentation.
3. Orient every EZ driver using the markings in the BIGTREETECH manual.
4. Seat the drivers in X, Y, Z, and E0 before installing the board in the enclosure.
5. Provide active airflow over the drivers.

The package uses software SPI on PE15/PE13/PE14 and the individual CS pins in the table. Before any motion test, run:

```text
DUMP_TMC STEPPER=stepper_x
DUMP_TMC STEPPER=stepper_y
DUMP_TMC STEPPER=stepper_z
DUMP_TMC STEPPER=extruder
```

Do not continue if any driver reports an SPI or communication fault.

## Current and motion mode

Starting RMS currents in the packages are:

| Axis | Starting current |
|---|---:|
| X | 1.0 A RMS |
| Y | 1.6 A RMS for the documented 42x60 mm, 2.1 A motor |
| Z | 0.8 A RMS for both Z motors on one driver |
| Extruder | 0.8 A RMS |

The Neptune 3, Pro, and Plus engineering packages use `stealthchop_threshold: 0`, keeping their drivers in SpreadCycle for the intended high-load motion. The physically tested Neptune 3 Max package instead preserves the quieter StealthChop and run/hold-current settings proven on the HDR Maxout printer. These motor-specific settings are used with either a CB1 or CM4 host and must not be copied blindly to different motors.

Monitor motors and drivers during commissioning. Current is not tuned by chasing the highest value; it is tuned for reliable motion with acceptable temperatures and margin.

## Build SKR 3 firmware

Read the marking printed on the MCU. SKR 3 boards may use STM32H723 or STM32H743.

```text
cd ~/klipper
make clean
make menuconfig
```

Select:

- Architecture: STMicroelectronics STM32
- Processor: the H723 or H743 physically installed
- Bootloader: 128 KiB
- Clock: 25 MHz crystal
- Communication: USB on PA11/PA12

Build and prepare the SD card:

```text
make
cp ~/klipper/out/klipper.bin ~/klipper/out/firmware.bin
```

Copy `firmware.bin` to the root of a FAT32 microSD card. With the SKR powered off, insert the card and power on. A successful flash normally renames the file to `firmware.cur`.

Connect the board to the Pad 7 and obtain its stable identifier:

```text
ls /dev/serial/by-id/
```

Put the exact result into the package's `[mcu] serial:` line.

## First power-up order

1. Power the board initially with motors and heaters disconnected when practical.
2. Confirm the MCU connects and no component overheats.
3. Connect and verify thermistors at room temperature.
4. Verify endstops and probe without homing.
5. Connect and buzz one motor at a time.
6. Test fans and the optional light.
7. Briefly test heaters at low targets while watching the temperature graph.
8. Only then proceed to the full [commissioning checklist](05-commissioning-checklist.md).

## Official references

- [BIGTREETECH SKR 3 repository and pin table](https://github.com/bigtreetech/SKR-3)
- [Klipper generic SKR 3 configuration](https://github.com/Klipper3d/klipper/blob/master/config/generic-bigtreetech-skr-3.cfg)
- [Klipper configuration reference](https://www.klipper3d.org/Config_Reference.html)

Return to the [documentation index](README.md).
