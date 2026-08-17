import json
import logging
import os
import re
import shutil
import tempfile
from datetime import datetime

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from ks_includes.screen_panel import ScreenPanel
from panels.hdr_bed_screw_transform import visual_direction, visual_grid_target


CONFIG_DIR = os.path.expanduser("__HDR_CONFIG_DIR__")
STATE_FILE = os.path.join(CONFIG_DIR, "custom", "state", "bed_screw_locations.json")
GENERATED_FILE = os.path.join(CONFIG_DIR, "custom", "generated", "screws_tilt_adjust.cfg")
STATE_VERSION = 4


class Panel(ScreenPanel):
    distances = ["0.1", "0.5", "1", "5", "10", "25"]

    def __init__(self, screen, title):
        super().__init__(screen, title or _("Bed Screw Location"))
        self.distance = "1"
        self.count = 0
        self.active = None
        self.points = {}
        self.map_grid = None
        self.load_state()
        self.show_question()

    def clear(self):
        for child in self.content.get_children():
            self.content.remove(child)

    def printer_busy(self):
        return self._printer.state in ("printing", "paused")

    def popup(self, text, level=1):
        self._screen.show_popup_message(text, level=level)

    def load_state(self):
        try:
            with open(STATE_FILE, encoding="utf-8") as handle:
                data = json.load(handle)
            if int(data.get("version", 0)) != STATE_VERSION:
                raise ValueError("Legacy orientation data must be taught again")
            count = int(data.get("count", 0))
            if count in (4, 5, 6):
                self.count = count
                raw = data.get("points", {})
                self.points = {
                    str(key): {"x": float(value["x"]), "y": float(value["y"])}
                    for key, value in raw.items()
                    if isinstance(value, dict) and "x" in value and "y" in value
                }
        except (OSError, ValueError, TypeError, json.JSONDecodeError):
            self.count = 0
            self.points = {}
        if self.count == 0:
            self.load_generated_points_by_name()

    @staticmethod
    def physical_name(name):
        text = re.sub(r"[^a-z]+", " ", name.lower().replace("back", "rear"))
        words = set(text.split())
        if "center" in words or "centre" in words:
            return "Center"
        side = "Left" if "left" in words else "Right" if "right" in words else None
        depth = "Front" if "front" in words else "Rear" if "rear" in words else "Middle" if "middle" in words else None
        return f"{depth} {side}" if side and depth else None

    def load_generated_points_by_name(self):
        """Import model defaults by physical name, never by screw number."""
        try:
            text = open(GENERATED_FILE, encoding="utf-8").read()
        except OSError:
            return
        coordinates = {
            int(match.group(1)): (float(match.group(2)), float(match.group(3)))
            for match in re.finditer(
                r"(?m)^screw(\d+):\s*([-+]?[0-9.]+)\s*,\s*([-+]?[0-9.]+)\s*$", text
            )
        }
        names = {
            int(match.group(1)): self.physical_name(match.group(2))
            for match in re.finditer(r"(?m)^screw(\d+)_name:\s*(.+?)\s*$", text)
        }
        named_points = {
            names[index]: {"x": x, "y": y}
            for index, (x, y) in coordinates.items()
            if names.get(index)
        }
        physical_count = len(named_points) - (1 if "Center" in named_points and len(named_points) == 7 else 0)
        if physical_count not in (4, 5, 6):
            return
        self.count = physical_count
        layout = self.slot_layout()
        mapped = {}
        for key, _column, _row, label in layout:
            if label not in named_points:
                self.count = 0
                self.points = {}
                return
            mapped[key] = named_points[label]
        self.points = mapped
        self.save_state()

    def save_state(self):
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        payload = {"version": STATE_VERSION, "count": self.count, "points": self.points}
        fd, temporary = tempfile.mkstemp(prefix="bed-screws-", suffix=".json", dir=os.path.dirname(STATE_FILE))
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump(payload, handle, indent=2, sort_keys=True)
                handle.write("\n")
            os.replace(temporary, STATE_FILE)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def show_question(self):
        self.clear()
        grid = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        message = Gtk.Label(
            label=_("Does this printer have physical manual bed adjusters?\n"
                    "Stock Neptune 3/3 Pro fixed beds must choose No."),
            wrap=True,
            justify=Gtk.Justification.CENTER,
        )
        grid.attach(message, 0, 0, 3, 1)
        for column, count in enumerate((4, 5, 6)):
            button = self._gtk.Button("bed-level", _("Yes - %d screws") % count, f"color{column + 1}")
            button.connect("clicked", self.choose_count, count)
            grid.attach(button, column, 1, 1, 1)
        no_button = self._gtk.Button("cancel", _("No / Exit"), "color4")
        no_button.connect("clicked", self.exit_panel)
        grid.attach(no_button, 0, 2, 3, 1)
        self.content.add(grid)
        self.content.show_all()

    def choose_count(self, widget, count):
        if self.printer_busy():
            self.popup(_("Stop or cancel the print before configuring bed screws."), 2)
            return
        if self.count != count:
            self.points = {}
        self.count = count
        self.save_state()
        self.show_map()

    def slot_layout(self):
        if self.count == 4:
            return [("1", 0, 2, "Front Left"), ("2", 2, 2, "Front Right"),
                    ("3", 2, 0, "Rear Right"), ("4", 0, 0, "Rear Left")]
        if self.count == 5:
            return [("1", 0, 2, "Front Left"), ("2", 2, 2, "Front Right"),
                    ("3", 2, 0, "Rear Right"), ("4", 0, 0, "Rear Left"),
                    ("5", 1, 1, "Center")]
        return [("1", 0, 2, "Front Left"), ("2", 0, 1, "Middle Left"),
                ("3", 0, 0, "Rear Left"), ("4", 2, 0, "Rear Right"),
                ("5", 2, 1, "Middle Right"), ("6", 2, 2, "Front Right")]

    def axis_limits(self):
        x_cfg = self._printer.get_config_section("stepper_x") or {}
        y_cfg = self._printer.get_config_section("stepper_y") or {}
        xmin = float(x_cfg.get("position_min", 0))
        xmax = float(x_cfg.get("position_max", 200))
        ymin = float(y_cfg.get("position_min", 0))
        ymax = float(y_cfg.get("position_max", 200))
        return xmin, xmax, ymin, ymax

    def suggested_point(self, column, row):
        rotation, invert_x, invert_y = self.orientation()
        return visual_grid_target(self.axis_limits(), column, row, rotation, invert_x, invert_y)

    def orientation(self):
        # Neptune bed-map convention when viewed from the operator/front edge.
        # A per-printer screw_rotation still overrides this universal default.
        rotation = 180
        if self.ks_printer_cfg is not None:
            rotation = self.ks_printer_cfg.getint("screw_rotation", 180)
        main = self._config.get_config()["main"]
        invert_x = main.getboolean("invert_x", False)
        invert_y = main.getboolean("invert_y", False)
        return rotation, invert_x, invert_y

    def show_map(self):
        self.clear()
        outer = Gtk.Grid(row_homogeneous=False, column_homogeneous=True)
        note = Gtk.Label(
            label=_("Choose a screw. Saved points are marked. The probe must be physically above the adjuster."),
            wrap=True,
            justify=Gtk.Justification.CENTER,
        )
        outer.attach(note, 0, 0, 3, 1)
        bed = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        for key, column, row, name in self.slot_layout():
            saved = self.points.get(key)
            suffix = "\nSaved" if saved else "\nSet location"
            button = self._gtk.Button("bed-level", _(name) + suffix, "color1" if saved else "color3")
            button.connect("clicked", self.edit_point, key, column, row, name)
            bed.attach(button, column, row, 1, 1)
        outer.attach(bed, 0, 1, 3, 3)
        change = self._gtk.Button("settings", _("Change screw count"), "color2")
        change.connect("clicked", lambda *_: self.show_question())
        done = self._gtk.Button("complete", _("Done"), "color4")
        done.connect("clicked", self.finish)
        outer.attach(change, 0, 4, 1, 1)
        outer.attach(done, 1, 4, 2, 1)
        self.content.add(outer)
        self.content.show_all()

    def edit_point(self, widget, key, column, row, name):
        if self.printer_busy():
            self.popup(_("Stop or cancel the print before moving the toolhead."), 2)
            return
        self.active = (key, name)
        target = self.points.get(key)
        if target is None:
            x, y = self.suggested_point(column, row)
        else:
            x, y = target["x"], target["y"]
        self.show_jog(name)
        script = f"G28\nG90\nG0 Z10 F900\nG0 X{x:.3f} Y{y:.3f} F3000"
        self._screen._send_action(widget, "printer.gcode.script", {"script": script})

    def show_jog(self, name):
        self.clear()
        grid = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        self.labels["position"] = Gtk.Label(label=_(name) + "\nX: --  Y: --", wrap=True)
        grid.attach(self.labels["position"], 0, 0, 3, 1)
        controls = {
            "left": ("arrow-left", 0, 2),
            "right": ("arrow-right", 2, 2),
            "up": ("arrow-up", 1, 1),
            "down": ("arrow-down", 1, 3),
        }
        for direction, (icon, column, row) in controls.items():
            button = self._gtk.Button(icon, None, "color1")
            button.connect("clicked", self.jog, direction)
            grid.attach(button, column, row, 1, 1)
        save = self._gtk.Button("complete", _("Save"), "color2")
        save.connect("clicked", self.save_point)
        cancel = self._gtk.Button("cancel", _("Cancel"), "color4")
        cancel.connect("clicked", lambda *_: self.show_map())
        grid.attach(save, 0, 4, 1, 1)
        grid.attach(cancel, 2, 4, 1, 1)

        distance_grid = Gtk.Grid(column_homogeneous=True)
        for column, distance in enumerate(self.distances):
            button = self._gtk.Button(label=distance)
            button.connect("clicked", self.set_distance, distance)
            button.get_style_context().add_class("horizontal_togglebuttons_active" if distance == self.distance else "horizontal_togglebuttons")
            self.labels[f"distance_{distance}"] = button
            distance_grid.attach(button, column, 0, 1, 1)
        grid.attach(distance_grid, 0, 5, 3, 1)
        self.content.add(grid)
        self.content.show_all()

    def set_distance(self, widget, distance):
        for value in self.distances:
            context = self.labels[f"distance_{value}"].get_style_context()
            context.remove_class("horizontal_togglebuttons_active")
            context.add_class("horizontal_togglebuttons")
        widget.get_style_context().remove_class("horizontal_togglebuttons")
        widget.get_style_context().add_class("horizontal_togglebuttons_active")
        self.distance = distance

    def jog(self, widget, direction):
        if self.printer_busy():
            self.popup(_("Movement is blocked while printing or paused."), 2)
            return
        rotation, invert_x, invert_y = self.orientation()
        axis, sign = visual_direction(rotation, invert_x, invert_y, direction)
        signed_distance = float(self.distance) * sign
        script = f"G91\nG0 {axis}{signed_distance:g} F3000\nG90"
        self._screen._send_action(widget, "printer.gcode.script", {"script": script})

    def current_xy(self):
        position = self._printer.get_stat("gcode_move", "gcode_position")
        if not position or len(position) < 2:
            return None
        return float(position[0]), float(position[1])

    def save_point(self, widget):
        position = self.current_xy()
        if position is None or self.active is None:
            self.popup(_("No valid homed XY position is available."), 2)
            return
        xmin, xmax, ymin, ymax = self.axis_limits()
        x, y = position
        if not (xmin <= x <= xmax and ymin <= y <= ymax):
            self.popup(_("The selected point is outside the configured motion limits."), 2)
            return
        key, _name = self.active
        self.points[key] = {"x": round(x, 3), "y": round(y, 3)}
        self.save_state()
        self.show_map()

    def write_generated_config(self):
        if len(self.points) != self.count or any(str(i) not in self.points for i in range(1, self.count + 1)):
            raise ValueError(_("Configure and save every screw location before pressing Done."))
        coords = [(self.points[str(i)]["x"], self.points[str(i)]["y"]) for i in range(1, self.count + 1)]
        if len(set(coords)) != len(coords):
            raise ValueError(_("Every screw must have a unique location."))
        os.makedirs(os.path.dirname(GENERATED_FILE), exist_ok=True)
        if os.path.exists(GENERATED_FILE):
            stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            shutil.copy2(GENERATED_FILE, f"{GENERATED_FILE}.backup-{stamp}")
        names = {key: name for key, _column, _row, name in self.slot_layout()}
        lines = [
            "# Generated by HDR Performance Bed Screw Location. Do not hand-edit while using the UI.",
            "# schema_version: 4",
            "[screws_tilt_adjust]",
            "screw_thread: CW-M3",
            "speed: 75",
            "horizontal_move_z: 10",
        ]
        for index in range(1, self.count + 1):
            key = str(index)
            point = self.points[key]
            lines.append(f"screw{index}: {point['x']:.3f}, {point['y']:.3f}")
            lines.append(f"screw{index}_name: {names[key].lower()}")
        fd, temporary = tempfile.mkstemp(prefix="screws-tilt-", suffix=".cfg", dir=os.path.dirname(GENERATED_FILE))
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                handle.write("\n".join(lines) + "\n")
            os.replace(temporary, GENERATED_FILE)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def finish(self, widget):
        if self.printer_busy():
            self.popup(_("Stop or cancel the print before saving tramming configuration."), 2)
            return
        try:
            self.write_generated_config()
        except (OSError, ValueError) as error:
            logging.exception("Unable to save bed screw configuration")
            self.popup(str(error), 2)
            return
        self._screen._send_action(widget, "printer.gcode.script", {"script": "G28\nM18\nRESTART"})
        self._screen._menu_go_back(home=True)

    def exit_panel(self, widget=None):
        self._screen._menu_go_back(home=True)

    def process_update(self, action, data):
        if action != "notify_status_update" or "gcode_move" not in data:
            return
        if "position" not in self.labels:
            return
        position = self.current_xy()
        if position and self.active:
            self.labels["position"].set_label(f"{self.active[1]}\nX: {position[0]:.2f}  Y: {position[1]:.2f}")

