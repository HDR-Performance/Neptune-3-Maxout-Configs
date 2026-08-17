from __future__ import annotations

import hashlib
import shutil
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
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
        write_archive(source, target, name)


for package in PACKAGES:
    rebuild(package)

checksums = []
for package in PACKAGES:
    archive = ROOT / f"{package}.zip"
    checksums.append(f"{hashlib.sha256(archive.read_bytes()).hexdigest()}  {archive.name}")
(ROOT / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="ascii", newline="\n")

