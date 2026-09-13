#!/usr/bin/env python3
"""Validate the public Maxout FlowTech OrcaSlicer profile pack."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


NOZZLES = {"0.4", "0.6", "0.8", "1.0"}
LAYERS = {"0.10", "0.15", "0.20", "0.30", "0.32"}
PRIVATE_PATTERNS = (
    re.compile(r"(?:^|[^0-9])(?:10|127|192\.168)\.\d+\.\d+\.\d+"),
    re.compile(r"[A-Za-z]:\\"),
    re.compile(r"\\\\"),
)


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def validate(root: Path, install_root: Path | None = None) -> list[str]:
    errors: list[str] = []
    manifest = load(root / "manifest.json")
    machine_files = sorted((root / "machine").glob("*.json"))
    process_files = sorted((root / "process").glob("*.json"))
    filament_files = sorted((root / "filament").glob("*.json"))

    expected = (
        manifest["generated_printer_profiles"],
        manifest["generated_process_profiles"],
        manifest["generated_filament_profiles"],
    )
    actual = (len(machine_files), len(process_files), len(filament_files))
    if actual != expected:
        fail(errors, f"profile counts differ: expected {expected}, got {actual}")

    machine_names: set[str] = set()
    for path in machine_files:
        raw = path.read_text(encoding="utf-8")
        profile = json.loads(raw)
        machine_names.add(profile["name"])
        diameter = profile["nozzle_diameter"][0]
        if diameter not in NOZZLES:
            fail(errors, f"{path.name}: unexpected nozzle {diameter}")
        if profile.get("inherits"):
            fail(errors, f"{path.name}: public machine profile is not self-contained")
        if profile.get("machine_start_gcode") != "START_PRINT BED_TEMP=[bed_temperature_initial_layer_single] EXTRUDER_TEMP=[nozzle_temperature_initial_layer]":
            fail(errors, f"{path.name}: incorrect START_PRINT contract")
        if profile.get("machine_end_gcode") != "END_PRINT":
            fail(errors, f"{path.name}: incorrect END_PRINT contract")
        if profile.get("default_filament_profile") != ["Maxout Generic PLA"]:
            fail(errors, f"{path.name}: default filament is not pack-owned")
        if profile.get("default_print_profile") != f"Maxout FlowTech {diameter} - 0.20 Balanced":
            fail(errors, f"{path.name}: default process is not pack-owned")
        if profile.get("nozzle_type") != "undefine":
            fail(errors, f"{path.name}: nozzle material must not be assumed")
        for pattern in PRIVATE_PATTERNS:
            if pattern.search(raw):
                fail(errors, f"{path.name}: contains a private host or filesystem path")

    seen_process_pairs: set[tuple[str, str]] = set()
    max_process_demand = 0.0
    for path in process_files:
        profile = load(path)
        printers = profile.get("compatible_printers", [])
        if len(printers) != 1 or printers[0] not in machine_names:
            fail(errors, f"{path.name}: invalid compatible printer")
            continue
        match = re.search(r"FlowTech (\d\.\d) nozzle", printers[0])
        diameter = match.group(1) if match else ""
        layer = profile.get("layer_height", "")
        if layer not in LAYERS or diameter not in NOZZLES:
            fail(errors, f"{path.name}: invalid nozzle/layer pair")
            continue
        pair = (diameter, layer)
        if pair in seen_process_pairs:
            fail(errors, f"{path.name}: duplicate nozzle/layer pair")
        seen_process_pairs.add(pair)
        if profile.get("inherits"):
            fail(errors, f"{path.name}: public process profile is not self-contained")
        if profile.get("enable_support") != "0":
            fail(errors, f"{path.name}: support must be opt-in")
        if profile.get("exclude_object") != "1" or profile.get("gcode_label_objects") != "1":
            fail(errors, f"{path.name}: KAMP object labeling is not enabled")
        ratio = float(layer) / float(diameter)
        if ratio < 0.20 and "Experimental thin-layer" not in profile.get("notes", ""):
            fail(errors, f"{path.name}: thin geometry lacks experimental warning")
        if float(profile["top_shell_thickness"]) < 0.8:
            fail(errors, f"{path.name}: top shell is too thin")
        if float(profile["bottom_shell_thickness"]) < 0.6:
            fail(errors, f"{path.name}: bottom shell is too thin")
        demand = float(profile["line_width"]) * float(layer) * float(profile["sparse_infill_speed"])
        max_process_demand = max(max_process_demand, demand)
    if max_process_demand > 35:
        fail(errors, f"process demand {max_process_demand:.2f} mm3/s exceeds pack guardrail")

    for path in filament_files:
        profile = load(path)
        name = profile["name"]
        temp = int(profile["nozzle_temperature"][0])
        mvs = float(profile["filament_max_volumetric_speed"][0])
        notes = profile.get("filament_notes", [""])[0]
        composite = bool(re.search(r"(?:-CF|-GF| CF| GF)", name))
        if temp > 300:
            fail(errors, f"{path.name}: temperature exceeds Maxout 300 C ceiling")
        if not 1 <= mvs <= 30:
            fail(errors, f"{path.name}: MVS {mvs:g} is outside public guardrails")
        if not profile.get("inherits", "").endswith("@System"):
            fail(errors, f"{path.name}: filament does not inherit a portable system preset")
        if composite:
            if any("0.4" in printer for printer in profile.get("compatible_printers", [])):
                fail(errors, f"{path.name}: abrasive composite allows 0.4 mm")
            if "hardened" not in notes or "0.6 mm or larger" not in notes:
                fail(errors, f"{path.name}: composite hardware warning missing")

    if install_root:
        for category, files in (("machine", machine_files), ("process", process_files), ("filament", filament_files)):
            for source in files:
                installed = install_root / category / source.name
                if not installed.exists() or installed.read_bytes() != source.read_bytes():
                    fail(errors, f"installed copy mismatch: {category}/{source.name}")

    print(f"machines={len(machine_files)} processes={len(process_files)} filaments={len(filament_files)}")
    print(f"max_process_demand_mm3_s={max_process_demand:.2f}")
    print(f"validation={'FAIL' if errors else 'PASS'}")
    return errors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("profile_root", type=Path)
    parser.add_argument("--install-root", type=Path)
    args = parser.parse_args()
    errors = validate(args.profile_root, args.install_root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
