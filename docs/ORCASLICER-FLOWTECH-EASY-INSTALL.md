# Easy installation: Maxout FlowTech OrcaSlicer profiles

## Download

**[Download Maxout FlowTech Orca Profiles 0.2.0 Beta](https://github.com/HDR-Performance/Neptune-3-Maxout-Configs/releases/download/orca-profiles-v0.2.0-beta/Maxout-FlowTech-Orca-Profiles-0.2.0-beta.zip)**

For later versions, open the [Maxout FlowTech Orca profile releases](https://github.com/HDR-Performance/Neptune-3-Maxout-Configs/releases?q=orca-profiles&expanded=true) and download the named profile ZIP from the newest release's **Assets** section.

Do not use GitHub's automatically generated **Source code** ZIP. The named profile ZIP includes the installer and the complete preset pack.

## Install on Windows

1. Close OrcaSlicer completely.
2. Right-click the downloaded ZIP, select **Extract All**, and open the extracted folder.
3. Double-click `INSTALL-ORCA-PROFILES.cmd`.
4. Wait for the green **Installed** message, then press any key to close the window.
5. Start OrcaSlicer.
6. In the **Printer** preset list, select the **Maxout FlowTech** preset matching the nozzle physically installed: 0.4, 0.6, 0.8, or 1.0 mm.
7. Select a matching Maxout process preset and a Maxout filament preset.

The installer writes only the included profile JSON files. If a same-named profile already exists, it is backed up before replacement under:

```text
%APPDATA%\OrcaSlicer\user\default\Maxout-FlowTech-backups
```

## Manual installation

If Windows prevents the installer from running:

1. Press `Windows + R`.
2. Paste `%APPDATA%\OrcaSlicer\user\default` and press Enter.
3. Copy the downloaded `machine` JSON files into the destination `machine` folder.
4. Copy the downloaded `process` JSON files into the destination `process` folder.
5. Copy the downloaded `filament` JSON files into the destination `filament` folder.
6. Restart OrcaSlicer.

Create any missing destination folders. Do not copy `manifest.json` into a preset folder.

## What is included

- 4 printer presets for 0.4, 0.6, 0.8, and 1.0 mm Micro Swiss FlowTech nozzles
- 20 process presets covering 0.10, 0.15, 0.20, 0.30, and 0.32 mm layer heights
- 47 filament starting profiles covering popular brands plus PLA, PLA+, PETG, ABS, ASA, PC, nylon/PA, TPU, and CF/GF composites

## Important first-print checks

These are beta starting profiles. Most combinations are structurally validated candidates rather than physically proven spool profiles.

- Confirm the selected preset matches the nozzle installed on the printer.
- Use a hardened abrasion-resistant FlowTech-compatible nozzle of at least 0.6 mm for CF/GF composites.
- Use appropriate enclosure, ventilation, and drying for engineering materials.
- Calibrate temperature, maximum volumetric flow, flow ratio, pressure advance, and retraction for each material, color, nozzle, and printer.
- Read the [full profile guide](ORCASLICER-FLOWTECH-PROFILES.md) and [validation protocol](ORCA-PROFILE-VALIDATION-PROTOCOL.md).

## Remove the profiles

Close OrcaSlicer, open `%APPDATA%\OrcaSlicer\user\default`, and remove only the JSON files whose names begin with `Maxout FlowTech` or `Maxout `. Restore earlier copies from the timestamped backup folder if needed.
