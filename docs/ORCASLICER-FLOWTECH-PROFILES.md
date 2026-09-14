# OrcaSlicer Maxout + Micro Swiss FlowTech profiles

> **New user?** Use the [download and easy Windows installation tutorial](ORCASLICER-FLOWTECH-EASY-INSTALL.md). The release ZIP includes a double-click installer and manual fallback instructions.

This profile pack supplies separate printer, process, and filament layers:

- Printer presets: FlowTech 0.4, 0.6, 0.8, and 1.0 mm nozzles.
- Process presets: 0.10, 0.15, 0.20, 0.30, and 0.32 mm layer heights for each nozzle.
- Filament presets: generic and popular-brand PLA, PLA+, PETG, ABS, ASA, PC, Nylon/PA, TPU, and CF/GF composite starting points.

The process profiles reduce commanded motion speed as nozzle cross-section grows. OrcaSlicer's filament maximum-volumetric-speed setting remains the final extrusion limiter. The FlowTech CHT hardware can reach up to 50 mm3/s under suitable conditions, but the included filament defaults remain well below that ceiling.

These are starting profiles, not universal spool calibrations. Profile maturity is tracked as `candidate`, `local-baseline`, or `production validated`; see the [validation protocol](ORCA-PROFILE-VALIDATION-PROTOCOL.md). For every new material or color, run the following in order:

1. Dry the filament according to its manufacturer guidance.
2. Temperature tower at the intended speed.
3. Maximum volumetric flow calibration.
4. Flow-ratio calibration.
5. Pressure-advance calibration.
6. Retraction test.

Pressure advance is intentionally omitted from the generated branded profiles. A copied value can be inaccurate when nozzle diameter, temperature, color additives, spool formulation, extruder tension, or feed path changes.

## Material safety and hardware requirements

| Family | Minimum setup | Important note |
| --- | --- | --- |
| PLA / PLA+ | FlowTech 0.4 mm or larger | Cooling and MVS must be checked for each brand and color. |
| PETG | FlowTech 0.4 mm or larger; dry filament | Reduce flow if layers become glossy/rough or the extruder skips. |
| TPU 95A | FlowTech 0.4 mm or larger; dry filament | Keep the feed path constrained and calibrate at low flow first. |
| ABS / ASA / PC | Enclosure and ventilation | Do not use these presets on an open machine. |
| Nylon / PA | Active dry-box feed; enclosure when its manufacturer calls for one | Nylon moisture can invalidate every other calibration. |
| Any CF/GF composite | Hardened abrasion-resistant FlowTech-compatible nozzle, 0.6 mm or larger | Standard brass nozzles wear rapidly and small orifices are more clog-prone. |

The composite presets are only compatible with the generated 0.6, 0.8, and 1.0 mm printer profiles. OrcaSlicer will not offer them for the 0.4 mm profile.

Generate and install with:

```powershell
python tools/generate-orca-maxout-flowtech-profiles.py `
  --source-root "$env:APPDATA\OrcaSlicer\user\default" `
  --output-root ".\orca-profiles\Maxout-FlowTech" `
  --install-root "$env:APPDATA\OrcaSlicer\user\default"
```

Restart OrcaSlicer after installation so its preset registry is rebuilt.

Validate the generated pack before publication:

```powershell
python tools/validate-orca-maxout-flowtech-profiles.py `
  ".\orca-profiles\Maxout-FlowTech"
```
