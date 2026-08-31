from __future__ import annotations

import hashlib
import shutil
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
SHARED_CANCEL_MACRO = (
    ROOT
    / "Neptune3Max-SKR3EZ-TMC5160Pro-HDR-Performance"
    / "config"
    / "custom"
    / "macros"
    / "cancel_print.cfg"
)
SHARED_MACRO_DIR = SHARED_CANCEL_MACRO.parent
SHARED_FILAMENT_MACRO = SHARED_MACRO_DIR / "filament_control.cfg"
PACKAGES = [
    "Neptune3-HDR-Performance-Pad7-Complete-Guide",
    "Neptune3Pro-HDR-Performance-Pad7-Complete-Guide",
    "Neptune3Plus-HDR-Performance-Pad7-Complete-Guide",
    "Neptune3Max-HDR-Performance-Pad7-Complete-Guide",
    "Neptune3-SKR3EZ-TMC5160Pro-HDR-Performance",
    "Neptune3Pro-SKR3EZ-TMC5160Pro-HDR-Performance",
    "Neptune3Plus-SKR3EZ-TMC5160Pro-HDR-Performance",
    "Neptune3Max-SKR3EZ-TMC5160Pro-HDR-Performance",
]


def section(text: str, header: str) -> tuple[int, int, str]:
    start = text.index(header)
    end = text.find("\n[", start + len(header))
    if end < 0:
        end = len(text)
    return start, end, text[start:end]


def replace_section(text: str, header: str, updated: str) -> str:
    start, end, _ = section(text, header)
    return text[:start] + updated + text[end:]


def add_led_alerts(macro_dir: Path) -> None:
    """Add the shared LED notifier without replacing model-specific macros."""
    filament_path = macro_dir / "filament_control.cfg"
    start_path = macro_dir / "start_print.cfg"
    end_path = macro_dir / "end_print.cfg"
    for path in (filament_path, start_path, end_path):
        if not path.is_file():
            raise RuntimeError(f"Required macro file not found: {path}")

    shared = SHARED_FILAMENT_MACRO.read_text(encoding="utf-8")
    led_start = shared.index("[gcode_macro _LED_ALERT_STATE]")
    led_end = shared.index("[gcode_macro _CLEAR_FILAMENT_STATE]")
    led_block = shared[led_start:led_end]

    filament = filament_path.read_text(encoding="utf-8")
    if "[gcode_macro _LED_ALERT_STATE]" not in filament:
        marker = "[gcode_macro _CLEAR_FILAMENT_STATE]"
        if marker not in filament:
            raise RuntimeError(f"Filament state macro not found in {filament_path}")
        filament = filament.replace(marker, led_block + marker, 1)

    _, _, clear = section(filament, "[gcode_macro _CLEAR_FILAMENT_STATE]")
    if "_STOP_LED_ALERT" not in clear:
        marker = "    UPDATE_DELAYED_GCODE ID=_RUNOUT_COOLDOWN DURATION=0\n"
        if marker not in clear:
            raise RuntimeError(f"Runout cooldown reset not found in {filament_path}")
        clear = clear.replace(marker, marker + "    _STOP_LED_ALERT\n", 1)
        filament = replace_section(filament, "[gcode_macro _CLEAR_FILAMENT_STATE]", clear)

    _, _, runout = section(filament, "[gcode_macro _FILAMENT_RUNOUT]")
    if "_START_LED_ALERT MODE=RUNOUT" not in runout:
        marker = "        PAUSE\n"
        if marker not in runout:
            raise RuntimeError(f"Runout pause not found in {filament_path}")
        runout = runout.replace(marker, marker + "        _START_LED_ALERT MODE=RUNOUT\n", 1)
        filament = replace_section(filament, "[gcode_macro _FILAMENT_RUNOUT]", runout)

    _, _, resume = section(filament, "[gcode_macro RUNOUT_RESUME]")
    if "_STOP_LED_ALERT" not in resume:
        marker = "        RESUME\n"
        if marker not in resume:
            raise RuntimeError(f"Runout resume command not found in {filament_path}")
        resume = resume.replace(marker, "        _STOP_LED_ALERT\n" + marker, 1)
        filament = replace_section(filament, "[gcode_macro RUNOUT_RESUME]", resume)
    filament_path.write_text(filament, encoding="utf-8", newline="\n")

    start = start_path.read_text(encoding="utf-8")
    _, _, start_macro = section(start, "[gcode_macro START_PRINT]")
    if "_STOP_LED_ALERT" not in start_macro:
        start_macro = start_macro.replace("gcode:\n", "gcode:\n    _STOP_LED_ALERT\n", 1)
        start = replace_section(start, "[gcode_macro START_PRINT]", start_macro)
        start_path.write_text(start, encoding="utf-8", newline="\n")

    end = end_path.read_text(encoding="utf-8")
    _, _, end_macro = section(end, "[gcode_macro END_PRINT]")
    if "_START_LED_ALERT MODE=COMPLETE" not in end_macro:
        end_macro = end_macro.rstrip() + "\n    _START_LED_ALERT MODE=COMPLETE\n"
        end = replace_section(end, "[gcode_macro END_PRINT]", end_macro)
        end_path.write_text(end, encoding="utf-8", newline="\n")


def write_archive(source: Path, target: Path, name: str) -> None:
    temporary = target.with_suffix(".zip.new")
    if temporary.exists():
        temporary.unlink()
    with ZipFile(temporary, "w", ZIP_DEFLATED, compresslevel=9) as archive:
        archive.writestr(f"{name}/", b"")
        for directory in sorted(path for path in source.rglob("*") if path.is_dir()):
            relative = directory.relative_to(source).as_posix()
            archive.writestr(f"{name}/{relative}/", b"")
        for file in sorted(path for path in source.rglob("*") if path.is_file()):
            relative = file.relative_to(source).as_posix()
            archive.write(file, f"{name}/{relative}")
    temporary.replace(target)


def rebuild(name: str) -> None:
    target = ROOT / f"{name}.zip"
    expanded = ROOT / name
    overlay = ROOT / "package-overlays" / name
    if expanded.is_dir():
        cancel_target = expanded / "config" / "custom" / "macros" / "cancel_print.cfg"
        if cancel_target != SHARED_CANCEL_MACRO:
            shutil.copy2(SHARED_CANCEL_MACRO, cancel_target)
        add_led_alerts(cancel_target.parent)
        write_archive(expanded, target, name)
        return
    if not target.is_file():
        raise FileNotFoundError(f"Package archive not found: {target}")
    with tempfile.TemporaryDirectory(prefix="hdr-package-") as temporary:
        temp_root = Path(temporary)
        with ZipFile(target, "r") as archive:
            archive.extractall(temp_root)
        source = temp_root / name
        if not source.is_dir():
            raise RuntimeError(f"Unexpected package root in {target.name}")
        if overlay.is_dir():
            shutil.copytree(overlay, source, dirs_exist_ok=True)
        cancel_target = source / "config" / "custom" / "macros" / "cancel_print.cfg"
        if not cancel_target.parent.is_dir():
            raise RuntimeError(f"Macro directory not found in {target.name}")
        shutil.copy2(SHARED_CANCEL_MACRO, cancel_target)
        add_led_alerts(cancel_target.parent)
        write_archive(source, target, name)


for package in PACKAGES:
    rebuild(package)

checksums = []
for package in PACKAGES:
    archive = ROOT / f"{package}.zip"
    checksums.append(f"{hashlib.sha256(archive.read_bytes()).hexdigest()}  {archive.name}")
(ROOT / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="ascii", newline="\n")
