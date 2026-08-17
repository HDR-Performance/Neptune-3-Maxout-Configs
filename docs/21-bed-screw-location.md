# Universal Bed Screw Location

This feature teaches Klipper the actual probe position above each physical bed
adjuster. It supports 4, 5, or 6 adjusters and works across the Neptune 3
packages without copying another model's coordinates.

## Fixed-bed warning

Stock Neptune 3 and Neptune 3 Pro beds do not have user-adjustable leveling
knobs. Answer **No / Exit** unless the printer has been physically converted.
Software cannot tram a bed that has no manual adjusters.

## Setup

1. Open **More > Bed Screw Location**, or run `BED_SCREW_LOCATION` from the
   KlipperScreen macro list.
2. Confirm the printer has physical adjusters and choose 4, 5, or 6.
3. Select an adjuster on the bed map. A saved point is revisited automatically;
   a new point starts at a conservative approximate location.
4. Watch the machine and verify the probe remains over the bed. Use the X/Y
   arrows and select 0.1, 0.5, 1, 5, 10, or 25 mm per press.
5. Center the **probe** over the physical adjuster and press **Save**. Save
   returns to the bed map.
6. Configure every point and press **Done**. The panel validates 4-6 unique,
   motion-limit-safe positions, backs up the previous generated file, writes
   `custom/generated/screws_tilt_adjust.cfg`, homes, releases the motors, and
   restarts Klipper.
7. Run `MANUAL_BED_TRAMMING`. Klipper now uses the saved coordinates through
   its native `SCREWS_TILT_CALCULATE` calculation.

The coordinates persist in both the generated Klipper file and
`custom/state/bed_screw_locations.json`. HDR OTA updates preserve both folders.
Reopen Bed Screw Location whenever an adjuster or probe position changes.

## Update Manager note

The custom panel is installed in KlipperScreen's `panels/` directory, so its
upstream repository may display **DIRTY**. This is expected for this optional
panel. A KlipperScreen recovery removes it; rerun the HDR UI installer or OTA
refresh afterward.
