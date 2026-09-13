#!/usr/bin/env python3
"""Generate installable OrcaSlicer presets for the Maxout + Micro Swiss FlowTech.

The values are conservative starting points. Brand/material profiles deliberately
do not set pressure advance because that must be calibrated on the actual spool,
extruder, nozzle diameter, and print temperature.
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


NOZZLES = {
    "0.4": {"line": 0.42, "outer": 90, "inner": 130, "solid": 110, "infill": 130, "support": 90, "travel": 350},
    "0.6": {"line": 0.62, "outer": 90, "inner": 125, "solid": 105, "infill": 125, "support": 90, "travel": 330},
    "0.8": {"line": 0.84, "outer": 70, "inner": 95, "solid": 85, "infill": 95, "support": 75, "travel": 300},
    "1.0": {"line": 1.05, "outer": 55, "inner": 75, "solid": 65, "infill": 75, "support": 60, "travel": 270},
}

LAYER_HEIGHTS = (0.10, 0.15, 0.20, 0.30, 0.32)

LAYER_INTENTS = {
    0.10: {"label": "Precision", "speed": 0.65, "resolution": 0.008},
    0.15: {"label": "Fine", "speed": 0.82, "resolution": 0.010},
    0.20: {"label": "Balanced", "speed": 1.00, "resolution": 0.012},
    0.30: {"label": "Fast", "speed": 1.08, "resolution": 0.016},
    0.32: {"label": "Draft", "speed": 1.12, "resolution": 0.020},
}

def material(name, family, nozzle, bed, flow, fan_min, fan_max, *, abrasive=False,
             enclosure=False, dry=False, vendor="Maxout"):
    return {
        "name": f"Maxout {name}", "family": family, "nozzle": nozzle,
        "bed": bed, "flow": flow, "fan_min": fan_min, "fan_max": fan_max,
        "abrasive": abrasive, "enclosure": enclosure, "dry": dry,
        "vendor": vendor,
    }


# Temperatures favor the warmer side of the normal manufacturer range so the
# FlowTech melt zone can support speed. MVS values remain conservative starting
# limits and must be calibrated for each spool/color/nozzle combination.
FILAMENTS = (
    # Generic families make the pack useful even when a brand is not listed.
    material("Generic PLA", "PLA", 225, 60, 22, 100, 100),
    material("Generic PLA+", "PLA", 230, 60, 24, 100, 100),
    material("Generic PETG", "PETG", 250, 80, 18, 30, 60, dry=True),
    material("Generic ABS", "ABS", 265, 100, 17, 0, 15, enclosure=True, dry=True),
    material("Generic ASA", "ASA", 270, 100, 16, 0, 20, enclosure=True, dry=True),
    material("Generic PC", "PC", 285, 110, 11, 0, 15, enclosure=True, dry=True),
    material("Generic Nylon PA", "PA", 280, 90, 11, 0, 25, enclosure=True, dry=True),
    material("Generic TPU 95A", "TPU", 240, 45, 6, 70, 100, dry=True),
    # Generic fiber-filled families. These are deliberately unavailable on 0.4.
    material("Generic PLA-CF", "PLA-CF", 235, 60, 14, 70, 100, abrasive=True, dry=True),
    material("Generic PLA-GF", "PLA", 235, 60, 13, 70, 100, abrasive=True, dry=True),
    material("Generic PETG-CF", "PETG-CF", 265, 80, 13, 20, 50, abrasive=True, dry=True),
    material("Generic PETG-GF", "PETG", 265, 80, 12, 20, 50, abrasive=True, dry=True),
    material("Generic ABS-CF", "ABS", 275, 100, 12, 0, 15, abrasive=True, enclosure=True, dry=True),
    material("Generic ABS-GF", "ABS", 275, 100, 11, 0, 15, abrasive=True, enclosure=True, dry=True),
    material("Generic ASA-CF", "ASA", 275, 100, 12, 0, 15, abrasive=True, enclosure=True, dry=True),
    material("Generic ASA-GF", "ASA", 275, 100, 11, 0, 15, abrasive=True, enclosure=True, dry=True),
    material("Generic PA6-CF", "PA-CF", 285, 100, 11, 0, 20, abrasive=True, enclosure=True, dry=True),
    material("Generic PA6-GF", "PA", 295, 100, 9, 0, 20, abrasive=True, enclosure=True, dry=True),
    material("Generic PA12-CF", "PA-CF", 285, 90, 11, 0, 20, abrasive=True, enclosure=True, dry=True),
    # Popular brand starting points.
    material("ELEGOO Rapid PLA+", "PLA", 225, 60, 28, 100, 100, vendor="ELEGOO"),
    material("ELEGOO Rapid PETG", "PETG", 260, 75, 22, 40, 70, dry=True, vendor="ELEGOO"),
    material("eSUN PLA+HS", "PLA", 225, 60, 28, 100, 100, vendor="eSUN"),
    material("eSUN PETG+HS", "PETG", 255, 80, 24, 40, 70, dry=True, vendor="eSUN"),
    material("eSUN ePA-CF", "PA-CF", 285, 100, 10, 0, 20, abrasive=True, enclosure=True, dry=True, vendor="eSUN"),
    material("SUNLU High Speed PLA", "PLA", 225, 60, 26, 100, 100, vendor="SUNLU"),
    material("SUNLU PETG", "PETG", 250, 80, 20, 35, 65, dry=True, vendor="SUNLU"),
    material("Polymaker PolySonic PLA Pro", "PLA", 230, 60, 25, 100, 100, vendor="Polymaker"),
    material("Polymaker PETG", "PETG", 250, 80, 20, 30, 60, dry=True, vendor="Polymaker"),
    material("Polymaker Fiberon PETG-ESD", "PETG", 255, 80, 12, 20, 50, abrasive=True, dry=True, vendor="Polymaker"),
    material("Polymaker Fiberon PA6-CF20", "PA-CF", 290, 50, 10, 0, 0, abrasive=True, dry=True, vendor="Polymaker"),
    material("Bambu PLA Basic", "PLA", 230, 60, 25, 100, 100, vendor="Bambu"),
    material("Bambu PLA-CF", "PLA-CF", 235, 60, 14, 70, 100, abrasive=True, dry=True, vendor="Bambu"),
    material("Bambu PETG HF", "PETG", 260, 75, 25, 30, 80, dry=True, vendor="Bambu"),
    material("Bambu PETG-CF", "PETG-CF", 265, 80, 13, 20, 50, abrasive=True, dry=True, vendor="Bambu"),
    material("Bambu ABS", "ABS", 270, 100, 22, 0, 15, enclosure=True, dry=True, vendor="Bambu"),
    material("Bambu ASA", "ASA", 270, 100, 20, 0, 20, enclosure=True, dry=True, vendor="Bambu"),
    material("Bambu PA6-CF", "PA-CF", 285, 100, 11, 0, 20, abrasive=True, enclosure=True, dry=True, vendor="Bambu"),
    material("Bambu PA6-GF", "PA", 295, 100, 9, 0, 20, abrasive=True, enclosure=True, dry=True, vendor="Bambu"),
    material("Bambu TPU 95A HF", "TPU", 240, 45, 8, 70, 100, dry=True, vendor="Bambu"),
    material("Overture PLA Professional", "PLA", 220, 60, 18, 100, 100, vendor="Overture"),
    material("Overture PETG", "PETG", 250, 80, 18, 30, 60, dry=True, vendor="Overture"),
    material("Hatchbox PLA", "PLA", 220, 60, 18, 100, 100, vendor="Hatchbox"),
    material("Hatchbox PETG", "PETG", 245, 80, 16, 30, 60, dry=True, vendor="Hatchbox"),
    material("Inland PLA+", "PLA", 225, 60, 20, 100, 100, vendor="Inland"),
    material("Inland PETG+", "PETG", 250, 80, 18, 30, 60, dry=True, vendor="Inland"),
    material("Creality Hyper PLA", "PLA", 230, 60, 26, 100, 100, vendor="Creality"),
    material("Creality Hyper PETG", "PETG", 255, 80, 22, 35, 70, dry=True, vendor="Creality"),
)

INHERITS = {
    "PLA": "Generic PLA @System", "PLA-CF": "Generic PLA-CF @System",
    "PETG": "Generic PETG @System", "PETG-CF": "Generic PETG-CF @System",
    "ABS": "Generic ABS @System", "ASA": "Generic ASA @System",
    "PC": "Generic PC @System", "PA": "Generic PA @System",
    "PA-CF": "Generic PA-CF @System", "TPU": "Generic TPU @System",
}


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write(json.dumps(payload, indent=4, ensure_ascii=False) + "\n")


def generate(source_root: Path, output_root: Path) -> None:
    for category in ("machine", "process"):
        for old_profile in (output_root / category).glob("Maxout FlowTech*.json"):
            old_profile.unlink()
    machine_source = source_root / "machine" / "Elegoo Elegoo Neptune Maxout 0.4 nozzle.json"
    process_source = source_root / "process" / "Maxout 0.4 nozzle 0.20 Basic.json"
    machine_template_source = source_root / "machine" / "base" / "Elegoo Elegoo Neptune 3 Max 0.4 nozzle.json"
    process_template_source = source_root / "process" / "base" / "process template @Elegoo Elegoo Neptune 3 Max 0.4 nozzle.json"
    machine_template = json.loads(machine_template_source.read_text(encoding="utf-8"))
    machine_overlay = json.loads(machine_source.read_text(encoding="utf-8"))
    process_template = json.loads(process_template_source.read_text(encoding="utf-8"))
    process_overlay = json.loads(process_source.read_text(encoding="utf-8"))
    # Flatten the local inheritance chain so the published presets do not depend
    # on any unpublished user preset being present on another computer.
    machine_base = {**machine_template, **machine_overlay}
    process_base = {**process_template, **process_overlay}

    for private_key in (
        "bed_custom_model", "bed_custom_texture", "print_host", "print_host_webui",
        "printhost_apikey", "printhost_cafile", "printhost_password", "printhost_port",
        "printhost_user",
    ):
        machine_base[private_key] = ""

    for nozzle, speeds in NOZZLES.items():
        machine_name = f"Maxout FlowTech {nozzle} nozzle"
        machine = dict(machine_base)
        machine.update(
            {
                "inherits": "",
                "from": "User",
                "gcode_flavor": "klipper",
                "machine_end_gcode": "END_PRINT",
                "machine_start_gcode": "START_PRINT BED_TEMP=[bed_temperature_initial_layer_single] EXTRUDER_TEMP=[nozzle_temperature_initial_layer]",
                "default_filament_profile": ["Maxout Generic PLA"],
                "default_print_profile": f"Maxout FlowTech {nozzle} - 0.20 Balanced",
                "name": machine_name,
                "nozzle_type": "undefine",
                "nozzle_diameter": [nozzle],
                "printer_settings_id": machine_name,
                "printer_variant": nozzle,
                "max_layer_height": [f"{float(nozzle) * 0.8:g}"],
                "min_layer_height": ["0.08"],
            }
        )
        write_json(output_root / "machine" / f"{machine_name}.json", machine)

        for layer in LAYER_HEIGHTS:
            layer_text = f"{layer:.2f}"
            intent = LAYER_INTENTS[layer]
            process_name = f"Maxout FlowTech {nozzle} - {layer_text} {intent['label']}"
            line = speeds["line"]
            speed_factor = intent["speed"]
            first_layer_height = max(layer, min(0.30, float(nozzle) * 0.5))
            layer_ratio = layer / float(nozzle)
            maturity = "local-baseline" if nozzle == "0.4" and layer == 0.20 else "candidate"
            geometry_warning = " Experimental thin-layer geometry; validate adhesion and line consistency." if layer_ratio < 0.20 else ""
            process = dict(process_base)
            process.update(
                {
                    "compatible_printers": [machine_name],
                    "inherits": "",
                    "from": "User",
                    "notes": f"Maxout FlowTech profile maturity: {maturity}.{geometry_warning} Filament MVS remains the extrusion-speed limiter.",
                    "enable_support": "0",
                    "exclude_object": "1",
                    "gcode_label_objects": "1",
                    "detect_overhang_wall": "1",
                    "slowdown_for_curled_perimeters": "1",
                    "precise_outer_wall": "1",
                    "wall_loops": "3",
                    "wall_sequence": "inner wall/outer wall",
                    "seam_position": "aligned",
                    "sparse_infill_density": "15%",
                    "sparse_infill_pattern": "crosshatch",
                    "top_surface_pattern": "monotonicline",
                    "bottom_surface_pattern": "monotonic",
                    "top_shell_thickness": f"{max(0.8, layer * 4):.2f}",
                    "bottom_shell_thickness": f"{max(0.6, layer * 3):.2f}",
                    "resolution": f"{intent['resolution']:.3f}",
                    "initial_layer_line_width": f"{line * 1.08:.2f}",
                    "initial_layer_print_height": f"{first_layer_height:.2f}",
                    "inner_wall_line_width": f"{line:.2f}",
                    "inner_wall_speed": str(round(speeds["inner"] * speed_factor)),
                    "internal_solid_infill_line_width": f"{line:.2f}",
                    "internal_solid_infill_speed": str(round(speeds["solid"] * speed_factor)),
                    "layer_height": layer_text,
                    "line_width": f"{line:.2f}",
                    "name": process_name,
                    "outer_wall_line_width": f"{line:.2f}",
                    "outer_wall_speed": str(round(speeds["outer"] * speed_factor)),
                    "print_settings_id": process_name,
                    "sparse_infill_line_width": f"{line:.2f}",
                    "sparse_infill_speed": str(round(speeds["infill"] * speed_factor)),
                    "support_line_width": f"{line:.2f}",
                    "support_speed": str(round(speeds["support"] * speed_factor)),
                    "support_interface_speed": str(max(30, round(speeds["support"] * speed_factor * 0.75))),
                    "support_top_z_distance": layer_text,
                    "support_bottom_z_distance": layer_text,
                    "top_surface_line_width": f"{line:.2f}",
                    "top_surface_speed": str(max(30, round((speeds["outer"] - 15) * speed_factor))),
                    "travel_speed": str(speeds["travel"]),
                }
            )
            write_json(output_root / "process" / f"{process_name}.json", process)

    all_printers = [f"Maxout FlowTech {diameter} nozzle" for diameter in NOZZLES]
    abrasive_printers = [name for name in all_printers if " 0.4 " not in name]
    for spec in FILAMENTS:
        name = spec["name"]
        requirements = []
        if spec["abrasive"]:
            requirements.append("REQUIRES a hardened abrasion-resistant FlowTech-compatible nozzle, 0.6 mm or larger")
        if spec["enclosure"]:
            requirements.append("REQUIRES an enclosure and suitable ventilation")
        if spec["dry"]:
            requirements.append("Dry filament and print from a dry box when appropriate")
        requirements.append("Calibrate temperature, max flow, flow ratio, pressure advance, and retraction for this spool")
        notes = ". ".join(requirements) + "."
        filament = {
            "compatible_printers": abrasive_printers if spec["abrasive"] else all_printers,
            "default_filament_colour": ["#FFFFFF"],
            "fan_max_speed": [str(spec["fan_max"])],
            "fan_min_speed": [str(spec["fan_min"])],
            "filament_extruder_variant": ["Direct Drive Standard"],
            "filament_max_volumetric_speed": [str(spec["flow"])],
            "filament_notes": ["Maxout + Micro Swiss FlowTech starting point. " + notes],
            "filament_settings_id": [name],
            "filament_type": [spec["family"]],
            "filament_vendor": [spec["vendor"]],
            "from": "User",
            "hot_plate_temp": [str(spec["bed"])],
            "hot_plate_temp_initial_layer": [str(spec["bed"])],
            "inherits": INHERITS[spec["family"]],
            "name": name,
            "nozzle_temperature": [str(spec["nozzle"])],
            "nozzle_temperature_initial_layer": [str(spec["nozzle"])],
            "nozzle_temperature_range_high": [str(min(300, spec["nozzle"] + 10))],
            "nozzle_temperature_range_low": [str(max(170, spec["nozzle"] - 20))],
            "textured_plate_temp": [str(spec["bed"])],
            "textured_plate_temp_initial_layer": [str(spec["bed"])],
            "version": "1.9.0.2",
        }
        write_json(output_root / "filament" / f"{name}.json", filament)

    manifest = {
        "profile_family": "Maxout + Micro Swiss FlowTech",
        "profile_pack_version": "0.2.0-beta",
        "hardware_contract": "Neptune 3 Max; SKR 3 EZ; upgraded X/Y motors; direct drive; Klipper; Micro Swiss FlowTech",
        "generated_printer_profiles": len(NOZZLES),
        "generated_process_profiles": len(NOZZLES) * len(LAYER_HEIGHTS),
        "generated_filament_profiles": len(FILAMENTS),
        "flowtech_hardware_ceiling_mm3_s": 50,
        "maturity": {"0.4/0.20": "local-baseline", "all_other_processes": "candidate", "filaments": "candidate"},
        "validation_required": ["temperature tower", "max volumetric flow", "flow ratio", "pressure advance", "retraction", "dimensional test", "overhang/bridge test", "representative long print"],
    }
    write_json(output_root / "manifest.json", manifest)


def install(output_root: Path, install_root: Path) -> None:
    for category in ("machine", "process", "filament"):
        destination = install_root / category
        destination.mkdir(parents=True, exist_ok=True)
        if category in ("machine", "process"):
            for old_profile in destination.glob("Maxout FlowTech*.json"):
                old_profile.unlink()
        for source in (output_root / category).glob("*.json"):
            shutil.copy2(source, destination / source.name)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--install-root", type=Path)
    args = parser.parse_args()
    generate(args.source_root, args.output_root)
    if args.install_root:
        install(args.output_root, args.install_root)


if __name__ == "__main__":
    main()
