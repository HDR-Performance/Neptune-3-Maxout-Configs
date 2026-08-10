# KAMP setup and use

KAMP creates a mesh around the actual objects being printed, parks near the print area, and places the purge close to the job. The packages already contain an organized KAMP configuration; this guide explains the requirements and how to repair or install KAMP from scratch.

## Required pieces

1. `[exclude_object]` in `printer.cfg`
2. Object processing enabled in `moonraker.conf`
3. Object labels emitted by the slicer
4. `KAMP_Settings.cfg` included by `printer.cfg`
5. The adaptive meshing, purge, and smart-park files at the included paths

Moonraker setting:

```ini
[file_manager]
enable_object_processing: True
```

Restart Moonraker after changing `moonraker.conf`.

## Package layout

The HDR packages use:

```text
~/printer_data/config/
|-- printer.cfg
|-- KAMP_Settings.cfg
`-- custom/
    `-- kamp/
        |-- Adaptive_Meshing.cfg
        |-- Line_Purge.cfg
        `-- Smart_Park.cfg
```

Keep these relative paths intact. The line-purge configuration in the packages caps the move to the purge location at 100 mm/s to prevent the uncontrolled-looking travel seen in the earlier setup.

## Install upstream KAMP from scratch

Use the upstream project when you want Moonraker-managed KAMP updates:

```text
cd ~
git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
ln -s ~/Klipper-Adaptive-Meshing-Purging/Configuration ~/printer_data/config/KAMP
cp ~/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg ~/printer_data/config/KAMP_Settings.cfg
```

Optional Moonraker update-manager entry:

```ini
[update_manager Klipper-Adaptive-Meshing-Purging]
type: git_repo
channel: dev
path: ~/Klipper-Adaptive-Meshing-Purging
origin: https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
managed_services: klipper
primary_branch: main
```

Do not mix the symlinked upstream layout with the packaged `custom/kamp` layout without updating the include paths. Choose one layout and keep it internally consistent.

## Slicer object labels

KAMP cannot find the print area if the slicer does not label objects. Enable exclude-object/object labeling in OrcaSlicer, PrusaSlicer, or the Moonraker preprocessing workflow. In Cura, use the supported object-label/post-processing workflow for the installed Moonraker version.

## Print-start order

The package's `START_PRINT` owns the sequence:

1. Validate temperatures
2. Home
3. Optionally heat-soak the bed
4. Generate the adaptive mesh
5. Smart-park
6. Finish heating the nozzle
7. Purge at a bounded travel speed

Do not duplicate homing, full-bed meshing, or purge G-code in the slicer.

## Heat-soak control

```text
ENABLE_HEAT_SOAK
DISABLE_HEAT_SOAK
BED_HEAT_SOAK BED_TEMP=70 MINUTES=5
```

The saved default persists through restarts. Per-print overrides are described in the [slicer guide](08-slicer-gcode.md).

## Troubleshooting

If KAMP creates a full-bed mesh or reports no objects:

- Confirm `[exclude_object]` is loaded.
- Confirm Moonraker object processing is enabled.
- Confirm the sliced G-code contains labeled objects.
- Confirm all paths included by `KAMP_Settings.cfg` exist.
- Restart Moonraker after its configuration changes and restart Klipper after Klipper configuration changes.

Official project: [Klipper Adaptive Meshing & Purging](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging)

Return to the [documentation index](README.md).
