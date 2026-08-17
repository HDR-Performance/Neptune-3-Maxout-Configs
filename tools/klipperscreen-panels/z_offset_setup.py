import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from ks_includes.screen_panel import ScreenPanel


class Panel(ScreenPanel):
    def __init__(self, screen, title):
        super().__init__(screen, title or _("Z Offset Setup"))
        bed_cfg = self._printer.get_config_section("heater_bed") or {}
        nozzle_cfg = self._printer.get_config_section("extruder") or {}
        bed_max = max(0, float(bed_cfg.get("max_temp", 115)) - 5)
        nozzle_max = max(170, float(nozzle_cfg.get("max_temp", 300)) - 5)
        current_nozzle = float(self._printer.get_stat("extruder", "target") or 0)
        bed_default = min(50, bed_max)
        nozzle_default = current_nozzle if current_nozzle >= 170 else 230

        grid = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        note = Gtk.Label(
            label=_("Optional bed preheat for Z calibration.\n"
                    "Set & Continue waits for the bed first, then heats the nozzle.\n"
                    "Skip Bed Heat leaves the bed heater off."),
            wrap=True,
            justify=Gtk.Justification.CENTER,
        )
        grid.attach(note, 0, 0, 2, 1)
        grid.attach(Gtk.Label(label=_("Bed target (C)")), 0, 1, 1, 1)
        self.bed = Gtk.SpinButton(
            adjustment=Gtk.Adjustment(bed_default, 0, bed_max, 5, 10, 0), digits=0
        )
        grid.attach(self.bed, 1, 1, 1, 1)
        grid.attach(Gtk.Label(label=_("Nozzle target (C)")), 0, 2, 1, 1)
        self.nozzle = Gtk.SpinButton(
            adjustment=Gtk.Adjustment(nozzle_default, 170, nozzle_max, 5, 10, 0), digits=0
        )
        grid.attach(self.nozzle, 1, 2, 1, 1)
        skip = self._gtk.Button("forward", _("Skip Bed Heat"), "color3")
        skip.connect("clicked", self.start, True)
        start = self._gtk.Button("complete", _("Set & Continue"), "color2")
        start.connect("clicked", self.start, False)
        cancel = self._gtk.Button("cancel", _("Cancel"), "color4")
        cancel.connect("clicked", lambda *_: self._screen._menu_go_back())
        grid.attach(skip, 0, 3, 1, 1)
        grid.attach(start, 1, 3, 1, 1)
        grid.attach(cancel, 0, 4, 2, 1)
        self.content.add(grid)
        self.content.show_all()

    def start(self, widget, skip_bed=False):
        bed_target = 0 if skip_bed else self.bed.get_value()
        script = f"MANUAL_Z_OFFSET_ADJUST BED_TEMP={bed_target:.0f} TEMP={self.nozzle.get_value():.0f}"
        self._screen._send_action(widget, "printer.gcode.script", {"script": script})
        self._screen._menu_go_back(home=True)

