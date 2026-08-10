# Choose the correct package

The printer model and controller must both match. The Neptune 3, Pro, Plus, and Max have different motion envelopes, probes, homing positions, mesh limits, fan mappings, and bed sizes.

## Controller families

### Stock Robin Nano + BTT Pad 7

Choose this family when the printer still uses its original Robin Nano controller. These packages add the organized macro suite, KAMP integration, Pad 7 input-shaper configuration, and guided setup while retaining the model's supplied working board mapping.

### HDR Maxout: SKR 3 EZ + TMC5160 Pro EZ

Choose this family only after converting the printer to:

- BIGTREETECH SKR 3 EZ
- Four TMC5160 Pro EZ drivers for X, Y, Z, and extruder
- BTT Pad 7 or another supported Klipper host
- Both Z motors connected to the single Z driver through the proven split/parallel harness

The Maxout motor baseline uses a 42x60 mm, 2.1 A Y motor and moves the original Y motor to X. The configured current values are starting points, not permission to ignore motor temperature or the driver's cooling requirements.

## Model matrix

| Printer | Nominal class | Important distinction |
|---|---:|---|
| Neptune 3 | 235 mm | Stock strain-gauge probing; the SKR conversion requires electrical interface verification |
| Neptune 3 Pro | 235 mm | Pro direct-drive toolhead and inductive probe |
| Neptune 3 Plus | 320 mm | Larger bed and six-screw tramming workflow |
| Neptune 3 Max | 420 mm | Largest and heaviest bed; seven-point tramming workflow |

## Do not continue if

- The printer model is uncertain.
- The board revision or MCU marking is not visible.
- A heater, fan, probe, or motor connector has not been electrically identified.
- The bed current has not been checked for an SKR conversion.
- The package's motion limits do not match the physical printer.

Return to the [documentation index](README.md).
