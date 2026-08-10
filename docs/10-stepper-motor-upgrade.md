# Neptune 3 Max X/Y stepper-motor upgrade

This guide refines the original HDR Performance motor-upgrade write-up. The tested concept is to install a higher-torque Y motor for the heavy bed and reuse the original Y motor on X.

## Documented hardware baseline

- Replacement Y motor: iMetrx 42x60 mm NEMA 17
- Rated current: 2.1 A
- Step angle: 1.8 degrees
- Original reference: [Amazon ASIN B097PD2JW3](https://www.amazon.com/dp/B097PD2JW3)
- Original Y motor moved to the X axis
- Original pulleys transferred to preserve the belt geometry

Equivalent motors may work, but must match the electrical, mechanical, shaft, current, and step-angle requirements.

> [!WARNING]
> The original guide found that its specific replacement cable required the two center conductors to be exchanged. Do not copy that swap by wire color or position alone. Identify both coil pairs with a meter and compare the motor and board pinouts before repinning. A different cable or motor may already be correct.

## Tools

- 2 mm and 3 mm hex keys
- Small driver or pick for connector terminals
- Multimeter with resistance/continuity measurement
- Marker or tape for labeling connectors
- Caliper or ruler for recording pulley position
- Cable ties and thread locker where appropriate
- A second person to help support the large printer safely

## Before disassembly

1. Shut the printer down, switch off the PSU, and unplug AC power.
2. Wait for the bed and hotend to cool.
3. Photograph the original motor wiring and pulley positions.
4. Mark the X and Y harnesses.
5. Record the flat/pulley alignment and pulley distance from each motor body.
6. Support the frame securely. Do not rest the printer where the gantry, toolhead, bed, or electronics can be damaged.

## Replace the Y motor

1. Back off the Y belt tension until the belt can be removed without prying.
2. Remove the Y motor cover/shield.
3. Support or carefully reposition the printer to reach the motor mount.
4. Disconnect the Y motor and remove its mounting screws.
5. Loosen both pulley set screws and remove the pulley.
6. Verify the new motor's two coil pairs with a meter.
7. Compare those pairs with the controller-side harness pin order. Repin only when the measured pinout requires it.
8. Install the original Y pulley on the replacement motor at the recorded depth. Tighten one set screw against the shaft flat when available.
9. Mount the motor squarely, route the cable away from motion, and reinstall the belt.
10. Set the belt snug enough to avoid skipping without overtensioning the motor and idlers.

## Move the original Y motor to X

1. Remove the X endstop/cover parts necessary to access the motor.
2. Release the X belt tension.
3. Disconnect and remove the original X motor.
4. Record and remove the X pulley.
5. Verify the original Y motor's shaft and mounting fit.
6. Install the X pulley on the original Y motor at the recorded depth.
7. Mount the motor, align the pulley with the belt path, reinstall the belt, and restore the endstop.
8. Route the heavier motor and cable so the gantry can travel through its full range without strain.

## Electrical and configuration checks

Both documented motors use a 1.8-degree step angle, so the package keeps the same full-steps-per-rotation assumption. That does not eliminate the need to verify direction, current, pulley alignment, and actual travel.

For the SKR/TMC Maxout baseline, the package starts at:

- X: 1.0 A RMS
- Y: 1.6 A RMS

These are starting values. Confirm motor and driver temperatures under real load and provide active driver cooling.

## First test

1. Move the axes by hand with power off and confirm there is no binding.
2. Place the bed and carriage near center.
3. Run `STEPPER_BUZZ STEPPER=stepper_x` and then Y.
4. Correct coil wiring or configured direction before homing.
5. Home one axis at a time with emergency stop ready.
6. Start with conservative velocity and acceleration.
7. Check the pulleys for slip and the belts for tracking.
8. Recalibrate input shaper because the moving mass and motor behavior changed.

Faster motors do not remove the bed's inertia. Increase print speed and acceleration gradually while watching for skipped steps, overheating, ringing, loose hardware, and frame movement.

Return to the [documentation index](README.md).
