#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
MOONRAKER_CONF="${HDR_MOONRAKER_CONF:-${CONFIG_DIR}/moonraker.conf}"
STAMP="$(date +%Y%m%d-%H%M%S)"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "${CONFIG_DIR}" && "$(basename "${CONFIG_DIR}")" == config ]] || die "Unsafe config directory: ${CONFIG_DIR}"
[[ -f "${MOONRAKER_CONF}" ]] || die "Moonraker configuration not found: ${MOONRAKER_CONF}"
command -v python3 >/dev/null 2>&1 || die "python3 is required."

BACKUP="${MOONRAKER_CONF}.hdr-kamp-backup-${STAMP}"
cp -a "${MOONRAKER_CONF}" "${BACKUP}"
WORK="$(mktemp)"
trap 'rm -f -- "${WORK}"' EXIT

python3 - "${MOONRAKER_CONF}" "${WORK}" "${CONFIG_DIR}" <<'PY'
import os
import re
import sys

source, destination, config_dir = sys.argv[1:]
with open(source, "r", encoding="utf-8") as handle:
    lines = handle.readlines()

header_re = re.compile(r"^\s*\[([^]]+)]\s*(?:#.*)?$")
sections = []
for index, line in enumerate(lines):
    match = header_re.match(line)
    if match:
        sections.append((index, match.group(1).strip()))
sections.append((len(lines), "__end__"))

file_managers = [item for item in sections[:-1] if item[1].lower() == "file_manager"]
if len(file_managers) > 1:
    raise SystemExit("Duplicate [file_manager] sections detected; no automatic change was made.")

result = list(lines)
if file_managers:
    start = file_managers[0][0]
    end = next(index for index, _ in sections if index > start)
    setting_re = re.compile(r"^(\s*)enable_object_processing\s*:\s*.*$", re.I)
    found = False
    for index in range(start + 1, end):
        if setting_re.match(result[index]):
            indent = setting_re.match(result[index]).group(1)
            result[index] = f"{indent}enable_object_processing: True\n"
            found = True
            break
    if not found:
        result.insert(end, "enable_object_processing: True\n")
else:
    if result and not result[-1].endswith("\n"):
        result[-1] += "\n"
    result.extend(["\n", "[file_manager]\n", "enable_object_processing: True\n"])

# Re-scan after the possible insertion, then disable only update-manager blocks
# whose managed repository is physically nested beneath the Moonraker config root.
lines = result
sections = []
for index, line in enumerate(lines):
    match = header_re.match(line)
    if match:
        sections.append((index, match.group(1).strip()))
sections.append((len(lines), "__end__"))

disable_ranges = []
for pos, (start, name) in enumerate(sections[:-1]):
    if not name.lower().startswith("update_manager "):
        continue
    end = sections[pos + 1][0]
    path_value = None
    for line in lines[start + 1:end]:
        match = re.match(r"^\s*path\s*:\s*(.*?)\s*(?:#.*)?$", line, re.I)
        if match:
            path_value = match.group(1).strip()
            break
    if not path_value:
        continue
    expanded = os.path.abspath(os.path.expanduser(os.path.expandvars(path_value)))
    root = os.path.abspath(config_dir)
    try:
        nested = os.path.commonpath([expanded, root]) == root
    except ValueError:
        nested = False
    if nested and ("kamp" in name.lower() or "adaptive-meshing" in name.lower() or "kamp" in expanded.lower()):
        disable_ranges.append((start, end, name, expanded))

for start, end, name, expanded in reversed(disable_ranges):
    replacement = [
        f"# HDR disabled [{name}] because its path was inside the config root,\n",
        f"# which creates overlapping Moonraker inotify watches: {expanded}\n",
    ]
    replacement.extend("# " + line if not line.lstrip().startswith("#") else line for line in lines[start:end])
    lines[start:end] = replacement

with open(destination, "w", encoding="utf-8", newline="") as handle:
    handle.writelines(lines)

print(f"object_processing=True; disabled_overlapping_kamp_updaters={len(disable_ranges)}")
PY

mv "${WORK}" "${MOONRAKER_CONF}"
trap - EXIT

restart_moonraker() {
  if systemctl restart moonraker.service 2>/dev/null; then
    systemctl is-active --quiet moonraker.service
  else
    sudo systemctl restart moonraker.service
    sudo systemctl is-active --quiet moonraker.service
  fi
}

if ! restart_moonraker; then
  printf 'Moonraker did not restart successfully; restoring %s\n' "${BACKUP}" >&2
  cp -a "${BACKUP}" "${MOONRAKER_CONF}"
  restart_moonraker || true
  die "Moonraker preflight was rolled back. Inspect journalctl -u moonraker."
fi

printf 'Moonraker KAMP preflight complete. Backup: %s\n' "${BACKUP}"
