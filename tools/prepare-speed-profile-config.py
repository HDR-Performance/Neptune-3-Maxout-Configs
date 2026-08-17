#!/usr/bin/env python3
"""Add verified HDR speed-limit markers without changing any configured value."""

import os
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
begin = "# HDR_SPEED_LIMITS_BEGIN"
end = "# HDR_SPEED_LIMITS_END"
if text.count(begin) == 1 and text.count(end) == 1:
    raise SystemExit(0)
if begin in text or end in text:
    raise SystemExit("incomplete or duplicated HDR speed markers")

sections = list(re.finditer(r"(?m)^\[printer\]\s*(?:#.*)?$", text))
if len(sections) != 1:
    raise SystemExit(f"expected one [printer] section, found {len(sections)}")
start = sections[0].start()
next_section = re.search(r"(?m)^\[", text[sections[0].end():])
stop = sections[0].end() + (next_section.start() if next_section else len(text))
block = text[start:stop]
for key in ("max_velocity", "max_accel", "square_corner_velocity"):
    if len(re.findall(rf"(?m)^\s*{key}\s*:", block)) != 1:
        raise SystemExit(f"[printer] must contain exactly one {key}")

lines = block.splitlines(keepends=True)
first = next(i for i, line in enumerate(lines) if re.match(r"^\s*max_velocity\s*:", line))
last = next(i for i, line in enumerate(lines) if re.match(r"^\s*square_corner_velocity\s*:", line))
if last < first:
    raise SystemExit("square_corner_velocity occurs before max_velocity")
newline = "\r\n" if "\r\n" in text else "\n"
lines.insert(first, begin + newline)
lines.insert(last + 2, end + newline)
updated = text[:start] + "".join(lines) + text[stop:]
temporary = path.with_name(".printer.cfg.hdr-marker.tmp")
with temporary.open("w", encoding="utf-8", newline="") as handle:
    handle.write(updated)
os.replace(temporary, path)
