# Troubleshooting

## MCU not found

- Confirm the firmware was built for the exact H723/H743 marking.
- Confirm 128 KiB bootloader, 25 MHz crystal, and USB PA11/PA12.
- Check that the SD card changed `firmware.bin` to `firmware.cur`.
- Run `ls /dev/serial/by-id/` again and copy the exact current ID.
- Check the SKR USB/CAN selector against the BIGTREETECH manual.

## TMC SPI error

- Power off immediately and reseat the EZ driver in the correct orientation.
- Verify every driver's voltage-selection setting.
- Confirm CS pins PD5, PD0, PE1, and PC6 and shared SPI PE15/PE13/PE14.
- Do not continue motor testing until `DUMP_TMC STEPPER=stepper_x` succeeds for every driver.

## Axis moves the wrong way

Power off and verify coil pairs first. If wiring is correct, invert or remove `!` on that axis's `dir_pin`. Never compensate for a mispaired motor coil with configuration.

## Endstop or probe never changes

Use `QUERY_ENDSTOPS` and `QUERY_PROBE` before homing. Verify signal voltage, ground, pin order, and pull-up requirements. The Pro/Plus/Max packages use PC0 through Z-STOP; the standard Neptune 3 strain-gauge conversion uses PC13 and requires interface verification.

## Heater or thermistor error

Stop heating. Confirm the hotend thermistor is on PA2/TH0 and the bed thermistor on PA1/THB. Confirm sensor type before changing configuration. A FlowTech unit tuned for a different printer is not automatically electrically equivalent.

## Moonraker configuration missing

Back up `~/printer_data` first. Confirm `~/printer_data/config/moonraker.conf` exists and inspect `~/printer_data/logs/moonraker.log`. Reinstall or repair Moonraker with the Pad 7's supported installation method/KIAUH rather than pasting a broad, old update-manager file over a working modern installation.

## KAMP does not adapt

- Confirm `[exclude_object]` is enabled.
- Confirm Moonraker object processing is enabled.
- Confirm the slicer emits labeled objects.
- Confirm every file included by `KAMP_Settings.cfg` exists at the packaged path.

