# Maxout OrcaSlicer profile validation protocol

The public Maxout profiles use three maturity levels:

- **Candidate**: generated, structurally validated, and within hardware guardrails, but not proven by a physical print.
- **Local baseline**: derived from a setting combination already used successfully on the development Maxout.
- **Production validated**: passed the complete protocol below on the stated nozzle, material, and hardware contract.

Do not describe a candidate profile as tuned, proven, or production validated.

## Hardware contract

- Elegoo Neptune 3 Max frame and 420 x 420 x 500 mm build volume
- SKR 3 EZ controller and the project-supported Klipper configuration
- Project-supported upgraded X/Y motors
- Direct-drive extruder
- Micro Swiss FlowTech hotend/nozzle
- Hardened abrasion-resistant FlowTech-compatible nozzle of at least 0.6 mm for every CF/GF composite
- Enclosure, ventilation, and dry-box feed where required by the material manufacturer

## Per-printer commissioning gate

Before evaluating a profile, confirm mechanics, belt tension, frame squareness, heater safety, probe repeatability, rotation distance, input shaping, pressure advance, and maximum acceleration. A profile cannot compensate for a printer that has not passed commissioning.

## Per-filament sequence

Use a new result record for every brand, product line, material, color, nozzle diameter, and meaningful hardware change.

1. Dry and store the filament according to manufacturer guidance.
2. Run a temperature tower at the intended range and speed.
3. Determine maximum volumetric flow; publish a profile MVS with at least a 15 percent reliability margin below the failure point.
4. Calibrate flow ratio.
5. Calibrate pressure advance on the real printer. Do not copy PA into the shared filament preset unless repeated spools demonstrate a stable value.
6. Calibrate retraction and verify seams.
7. Print dimensional, overhang, bridge, first-layer, and surface-finish tests.
8. Print a representative part for at least four hours with no skipped steps, extrusion instability, heat creep, or thermal fault.
9. Repeat the representative print once before promotion to production validated.

## Process-profile sequence

For every nozzle/layer combination, verify:

- first-layer consistency across the large bed;
- outer-wall ringing and corner quality;
- small-perimeter cooling;
- top-surface closure and bottom-surface finish;
- overhangs at 30, 45, 55, and 65 degrees;
- bridges at 10, 25, 50, and 100 mm;
- support removal using the profile's layer-scaled contact distance;
- dimensional error on X, Y, Z, holes, and external contours;
- KAMP object labeling and `START_PRINT`/`END_PRINT` behavior.

Record failures and the exact setting changed. Change one variable at a time. Keep a candidate profile separate until the new value passes the same test twice.

## Automated pack check

Run after every generator change:

```powershell
python tools/generate-orca-maxout-flowtech-profiles.py `
  --source-root "$env:APPDATA\OrcaSlicer\user\default" `
  --output-root ".\orca-profiles\Maxout-FlowTech"

python tools/validate-orca-maxout-flowtech-profiles.py `
  ".\orca-profiles\Maxout-FlowTech"
```

The validator rejects private host/path data, missing public dependencies, unsafe composite compatibility, excessive temperature/MVS, incorrect macro contracts, duplicate nozzle/layer pairs, and missing KAMP object labeling.
