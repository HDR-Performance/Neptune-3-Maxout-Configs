# SKR 3 EZ wiring and firmware guide

This conversion is for a BIGTREETECH SKR 3 EZ, four TMC5160 Pro EZ drivers, and a BTT Pad 7. It is not a drop-in motherboard swap. Connector shape does not prove voltage, polarity, pin order, or current compatibility.

## Safety first

- Disconnect AC power before opening the printer.
- Photograph and label every original connection.
- Confirm motor coil pairs with a meter. Never repin a motor from wire color alone.
- Confirm thermistor type and heater voltage before connecting them.
- The SKR 3 heated-bed output is rated at 10 A. Measure the bed resistance or read its label and calculate `current = 24 / resistance`. Use an appropriately rated external MOSFET if the bed may exceed the board limit. This is especially important on Plus and Max beds.
- The three controlled fan outputs share one selected voltage. Set the fan-voltage jumper correctly before connecting a fan or LED.
- Keep a hand on the emergency-stop control during every first-motion test.

## Package pin map

| Device | SKR 3 EZ connection | MCU pin |
|---|---|---|
| X motor | X-MOT | PD4 / PD3 / PD6, CS PD5 |
| Y motor | Y-MOT | PA15 / PA8 / PD1, CS PD0 |
| Both Z motors | Z-MOT through the proven parallel/split harness | PE2 / PE3 / PE0, CS PE1 |
| Extruder motor | E0-MOT | PD15 / PD14 / PC7, CS PC6 |
| X endstop | X-STOP | PC1 |
| Y endstop | Y-STOP | PC3 |
| Pro/Plus/Max probe signal | Z-STOP in these packages | PC0 |
| Standard Neptune 3 strain-gauge signal | Dedicated PROBE input after interface verification | PC13 |
| Filament sensor | E0-DET / FIL-DET | PC2 |
| Hotend heater | HE0 | PB3 |
| Bed or external-MOSFET trigger | BED | PD7 |
| Hotend thermistor | TH0 | PA2 |
| Bed thermistor | THB | PA1 |
| Overhead 24 V LED, where used | FAN0 | PB7 |
| Part-cooling fan | FAN1 | PB6 |
| Hotend fan | FAN2 | PB5 |

PB9 is FDCAN transmit on the SKR 3 EZ. The old PB9 LED instruction has deliberately not been carried forward.

## TMC5160 Pro EZ setup

Install the drivers with power disconnected and orient them exactly as shown in the BIGTREETECH manual. Confirm the driver-voltage selection for every socket. The configuration uses the onboard software-SPI lines PE15/PE13/PE14 and the per-axis chip-select pins above.

The Maxout current baseline is:

- X: 1.0 A RMS
- Y: 1.6 A RMS for the documented 42x60 mm, 2.1 A motor
- Z: 0.8 A RMS for both Z motors on one driver
- Extruder: 0.8 A RMS

This Neptune 3 Max package preserves the printer-tested quiet configuration: `stealthchop_threshold: 999999`, X run/hold current 1.0/0.5 A, Y 1.6/0.7 A, Z 0.8/0.5 A, and Z1 0.8/0.4 A. These are RMS values for the documented Maxout motors and cooling. They apply with either CB1 or CM4 because the host board does not control the TMC5160 operating mode. Do not copy them to different motors without verification.

## Build and flash Klipper

1. Read the marking on the SKR 3 MCU. Select STM32H723 or STM32H743 to match the actual chip.
2. SSH into the Pad 7 and run:

   ```text
   cd ~/klipper
   make menuconfig
   ```

3. Enable extra low-level options and select:

   - Architecture: STMicroelectronics STM32
   - Processor: the H723 or H743 printed on the board
   - Bootloader: 128 KiB
   - Clock reference: 25 MHz crystal
   - Communication: USB on PA11/PA12

4. Build with `make`, rename `out/klipper.bin` to `firmware.bin`, and copy it to the root of a FAT32 microSD card.
5. Power the SKR off, insert the card, power on, then verify the board renamed the file to `firmware.cur`.
6. Connect USB to the Pad 7 and run:

   ```text
   ls /dev/serial/by-id/
   ```

7. Replace `REPLACE_WITH_YOUR_SKR3_EZ_ID` in `config/printer.cfg` with the exact reported identifier.

Do not reuse another printer's MCU ID or a prebuilt firmware made for the other processor revision.

## Controlled first-power test

1. With motors and heaters still disabled or disconnected, power the controller and confirm the MCU connects without smoke, heat, or fault LEDs.
2. Confirm both thermistors show believable room temperature. If either shows an error or an implausible value, stop.
3. Connect endstops and run `QUERY_ENDSTOPS` while manually operating each switch. Do not home yet.
4. Connect one motor at a time and use `STEPPER_BUZZ STEPPER=stepper_x`, then Y, Z, and extruder. Correct wiring or direction before continuing.
5. Verify the probe changes state with `QUERY_PROBE`. For an inductive probe, test it with the steel sheet while the nozzle is safely above the bed. For the standard Neptune 3 strain-gauge system, verify its interface voltage and pin order before connecting it to PC13.
6. Briefly test the hotend and bed at low targets while watching the temperature graph. Stop immediately if the wrong sensor responds or the temperature rises uncontrollably.
7. Only after those checks, run the first `G28` with a hand on emergency stop.
8. Complete PID tuning, Z-offset calibration, bed tramming, mesh generation, and input-shaper calibration before printing.

## Source references

- BIGTREETECH SKR 3 repository and pin table: https://github.com/bigtreetech/SKR-3
- Klipper SKR 3 sample configuration: https://github.com/Klipper3d/klipper/blob/master/config/generic-bigtreetech-skr-3.cfg
- Klipper configuration reference: https://www.klipper3d.org/Config_Reference.html
