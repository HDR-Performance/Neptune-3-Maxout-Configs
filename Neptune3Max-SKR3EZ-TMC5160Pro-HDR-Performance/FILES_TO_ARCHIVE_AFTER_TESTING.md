# Files that can be archived after the new configuration passes testing

Based on the supplied Mainsail screenshot, these appear to be inactive backups
or exports. Confirm that no active `[include ...]` line references a file before
moving it.

## Move to `archive/printer-backups/`

- `printer-20260514_210602.cfg`
- `printer-20260514_032134.cfg`
- `printer 25.cfg`
- `Good Working Robin Nano printer.cfg`
- `Printer72625.cfg`
- `printer.wcfg`
- `PrinterOldWorking`

## Move to `archive/moonraker-backups/`

- `.moonraker.conf.bkp`
- `Moonraker72625.cfg`

## Move to `archive/config-exports/`

- Files named `config-*.zip`

## Old root-level KAMP copies

After the organized configuration works, the old root copies of
`Adaptive_Meshing.cfg`, `Line_Purge.cfg`, `Smart_Park.cfg`, and
`OG.Line_Purge.cfg` may also be archived. The new `KAMP_Settings.cfg` loads the
active copies from `custom/kamp/`.

Keep `printer.cfg`, `moonraker.conf`, `mainsail.cfg`, `timelapse.cfg`,
`KAMP_Settings.cfg`, `KlipperScreen.conf`, `sonar.conf`, and `KAMP/` in the
configuration root.

