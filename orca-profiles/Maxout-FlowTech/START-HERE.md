# Start here: install the Maxout FlowTech profiles

These profiles are for the HDR Maxout hardware configuration described in `manifest.json`. They are beta starting points, not universal spool calibrations.

## Easy Windows installation

1. Close OrcaSlicer completely.
2. Double-click `INSTALL-ORCA-PROFILES.cmd`.
3. Wait for the green **Installed** message, then press any key to close the window.
4. Start OrcaSlicer.
5. Select the appropriate **Maxout FlowTech** printer preset for your installed nozzle.
6. Select a matching Maxout process and filament preset.

The installer copies 4 printer, 20 process, and 47 filament profiles into your OrcaSlicer user preset folders. If it replaces an earlier Maxout profile with the same filename, it first creates a timestamped backup under:

```text
%APPDATA%\OrcaSlicer\user\default\Maxout-FlowTech-backups
```

## Manual installation

If the installer cannot run:

1. Press `Windows + R`, paste `%APPDATA%\OrcaSlicer\user\default`, and press Enter.
2. Copy the JSON files from this ZIP's `machine` folder into the destination `machine` folder.
3. Copy the JSON files from `process` into the destination `process` folder.
4. Copy the JSON files from `filament` into the destination `filament` folder.
5. Restart OrcaSlicer.

Create the destination folders if they do not already exist. Do not copy `manifest.json` into any preset folder.

## Before the first print

- Confirm the selected nozzle diameter matches the nozzle physically installed.
- CF/GF composites require a hardened, abrasion-resistant FlowTech-compatible nozzle of at least 0.6 mm.
- ABS, ASA, PC, and applicable nylon materials require suitable enclosure, ventilation, and drying.
- Calibrate temperature, maximum volumetric flow, flow ratio, pressure advance, and retraction for every material, color, and nozzle combination.
- Review the complete guide and validation protocol linked from the GitHub release page.
