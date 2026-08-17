import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

from ks_includes.screen_panel import ScreenPanel


class Panel(ScreenPanel):
    def __init__(self, screen, title):
        super().__init__(screen, title or _("Full Bed Mesh"))
        bed_cfg = self._printer.get_config_section("heater_bed") or {}
        nozzle_cfg = self._printer.get_config_section("extruder") or {}
        bed_max = max(0, float(bed_cfg.get("max_temp", 115)) - 5)
        nozzle_max = max(0, float(nozzle_cfg.get("max_temp", 300)) - 5)
        grid = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        note = Gtk.Label(
            label=_("The bed heats first, then the nozzle. A normal full-bed mesh starts after both targets are reached."),
            wrap=True,
            justify=Gtk.Justification.CENTER,
        )
        grid.attach(note, 0, 0, 2, 1)
        grid.attach(Gtk.Label(label=_("Bed target (C)")), 0, 1, 1, 1)
        self.bed = Gtk.SpinButton(adjustment=Gtk.Adjustment(60, 0, bed_max, 5, 10, 0), digits=0)
        grid.attach(self.bed, 1, 1, 1, 1)
        grid.attach(Gtk.Label(label=_("Nozzle target (C)")), 0, 2, 1, 1)
        self.nozzle = Gtk.SpinButton(adjustment=Gtk.Adjustment(190, 0, nozzle_max, 5, 10, 0), digits=0)
        grid.attach(self.nozzle, 1, 2, 1, 1)
        start = self._gtk.Button("complete", _("Start Full Mesh"), "color2")
        start.connect("clicked", self.start)
        cancel = self._gtk.Button("cancel", _("Cancel"), "color4")
        cancel.connect("clicked", lambda *_: self._screen._menu_go_back())
        grid.attach(start, 0, 3, 1, 1)
        grid.attach(cancel, 1, 3, 1, 1)
        self.content.add(grid)
        self.content.show_all()

    def start(self, widget):
        script = f"G29 BED_TEMP={self.bed.get_value():.0f} NOZZLE_TEMP={self.nozzle.get_value():.0f}"
        self._screen._send_action(widget, "printer.gcode.script", {"script": script})
        self._screen._menu_go_back(home=True)

