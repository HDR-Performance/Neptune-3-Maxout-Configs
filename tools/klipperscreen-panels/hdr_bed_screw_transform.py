"""Orientation transforms for the HDR Bed Screw Location panel."""


def visual_direction(rotation, invert_x, invert_y, direction):
    """Return the machine axis and sign for a direction shown on screen."""
    rotation = int(rotation) % 360
    mappings = {
        0: {"left": ("X", -1), "right": ("X", 1), "up": ("Y", 1), "down": ("Y", -1)},
        90: {"left": ("Y", -1), "right": ("Y", 1), "up": ("X", -1), "down": ("X", 1)},
        180: {"left": ("X", 1), "right": ("X", -1), "up": ("Y", -1), "down": ("Y", 1)},
        270: {"left": ("Y", 1), "right": ("Y", -1), "up": ("X", 1), "down": ("X", -1)},
    }
    axis, sign = mappings.get(rotation, mappings[0])[direction]
    if (axis == "X" and invert_x) or (axis == "Y" and invert_y):
        sign *= -1
    return axis, sign


def visual_grid_target(limits, column, row, rotation=0, invert_x=False, invert_y=False):
    """Convert a visual 3x3 bed-map cell into safe machine coordinates."""
    xmin, xmax, ymin, ymax = limits
    centers = {"X": (xmin + xmax) / 2.0, "Y": (ymin + ymax) / 2.0}
    spans = {
        "X": max(0.0, (xmax - xmin) / 2.0 - max(10.0, (xmax - xmin) * 0.12)),
        "Y": max(0.0, (ymax - ymin) / 2.0 - max(10.0, (ymax - ymin) * 0.12)),
    }
    target = dict(centers)
    horizontal = int(column) - 1
    vertical = 1 - int(row)
    axis, sign = visual_direction(rotation, invert_x, invert_y, "right")
    target[axis] += horizontal * sign * spans[axis]
    axis, sign = visual_direction(rotation, invert_x, invert_y, "up")
    target[axis] += vertical * sign * spans[axis]
    return target["X"], target["Y"]
