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
        current_bed = float(self._printer.get_stat("heater_bed", "target") or 0)
        current_nozzle = float(self._printer.get_stat("extruder", "target") or 0)
        nozzle_default = current_nozzle if current_nozzle >= 170 else 230

        grid = Gtk.Grid(row_homogeneous=True, column_homogeneous=True)
        note = Gtk.Label(
            label=_("Set preparation temperatures. A bed target of 0 disables bed heating.\n"
                    "The bed reaches its target before nozzle heating begins."),
            wrap=True,
            justify=Gtk.Justification.CENTER,
        )
        grid.attach(note, 0, 0, 2, 1)
        grid.attach(Gtk.Label(label=_("Bed target (C)")), 0, 1, 1, 1)
        self.bed = Gtk.SpinButton(adjustment=Gtk.Adjustment(current_bed, 0, bed_max, 5, 10, 0), digits=0)
        grid.attach(self.bed, 1, 1, 1, 1)
        grid.attach(Gtk.Label(label=_("Nozzle target (C)")), 0, 2, 1, 1)
        self.nozzle = Gtk.SpinButton(
            adjustment=Gtk.Adjustment(nozzle_default, 170, nozzle_max, 5, 10, 0), digits=0
        )
        grid.attach(self.nozzle, 1, 2, 1, 1)
        start = self._gtk.Button("complete", _("Start"), "color2")
        start.connect("clicked", self.start)
        cancel = self._gtk.Button("cancel", _("Cancel"), "color4")
        cancel.connect("clicked", lambda *_: self._screen._menu_go_back())
        grid.attach(start, 0, 3, 1, 1)
        grid.attach(cancel, 1, 3, 1, 1)
        self.content.add(grid)
        self.content.show_all()

    def start(self, widget):
        script = f"MANUAL_Z_OFFSET_ADJUST BED_TEMP={self.bed.get_value():.0f} TEMP={self.nozzle.get_value():.0f}"
        self._screen._send_action(widget, "printer.gcode.script", {"script": script})
        self._screen._menu_go_back(home=True)
