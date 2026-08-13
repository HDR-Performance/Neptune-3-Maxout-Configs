#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
BACKUP_ROOT="${HDR_BACKUP_ROOT:-${HOME}/printer_data/config_backups}"
PACKAGE_ID=""
MCU_ID=""
HOST_TYPE="auto"
ASSUME_YES=0
DRY_RUN=0
TEMP_DIR=""
FRESH_INSTALL=0

cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    rm -rf -- "${TEMP_DIR}"
  fi
}
trap cleanup EXIT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '\n==> %s\n' "$*"
}

usage() {
  cat <<'EOF'
HDR Performance Neptune 3 configuration installer

Usage:
  ./install.sh
  ./install.sh --package PACKAGE_ID
  ./install.sh --package PACKAGE_ID --mcu-id /dev/serial/by-id/...

Options:
  --package ID       Skip the menu and select a package ID.
  --mcu-id PATH      SKR only: replace the MCU placeholder with this exact path.
  --host TYPE        Pad host: auto (default), cb1, or cm4.
  --config-dir PATH  Override ~/printer_data/config.
  --dry-run          Download and inspect, but do not change the printer.
  --yes              Skip the final INSTALL confirmation. Does not guess an MCU ID.
  --list             List package IDs and exit.
  -h, --help         Show this help.

Package IDs:
  neptune3-robin
  neptune3pro-robin
  neptune3plus-robin
  neptune3max-robin
  neptune3-skr3ez
  neptune3pro-skr3ez
  neptune3plus-skr3ez
  neptune3max-skr3ez
EOF
}

list_packages() {
  cat <<'EOF'
1) neptune3-robin       - Neptune 3 / stock Robin Nano / BTT Pad 7
2) neptune3pro-robin    - Neptune 3 Pro / stock Robin Nano / BTT Pad 7
3) neptune3plus-robin   - Neptune 3 Plus / stock Robin Nano / BTT Pad 7
4) neptune3max-robin    - Neptune 3 Max / stock Robin Nano / BTT Pad 7
5) neptune3-skr3ez      - Neptune 3 / SKR 3 EZ / TMC5160 Pro / BTT Pad 7
6) neptune3pro-skr3ez   - Neptune 3 Pro / SKR 3 EZ / TMC5160 Pro / BTT Pad 7
7) neptune3plus-skr3ez  - Neptune 3 Plus / SKR 3 EZ / TMC5160 Pro / BTT Pad 7
8) neptune3max-skr3ez   - Neptune 3 Max / SKR 3 EZ / TMC5160 Pro / BTT Pad 7
EOF
}

select_package() {
  local choice
  printf '\nSelect the exact printer and controller:\n\n'
  list_packages
  printf '\nEnter 1-8: '
  read -r choice
  case "${choice}" in
    1) PACKAGE_ID="neptune3-robin" ;;
    2) PACKAGE_ID="neptune3pro-robin" ;;
    3) PACKAGE_ID="neptune3plus-robin" ;;
    4) PACKAGE_ID="neptune3max-robin" ;;
    5) PACKAGE_ID="neptune3-skr3ez" ;;
    6) PACKAGE_ID="neptune3pro-skr3ez" ;;
    7) PACKAGE_ID="neptune3plus-skr3ez" ;;
    8) PACKAGE_ID="neptune3max-skr3ez" ;;
    *) die "Invalid selection." ;;
  esac
}

resolve_package() {
  case "${PACKAGE_ID}" in
    neptune3-robin)
      ZIP_NAME="Neptune3-HDR-Performance-Pad7-Complete-Guide.zip"
      PACKAGE_LABEL="Neptune 3 / Robin Nano / Pad 7"
      CONTROLLER="robin"
      ;;
    neptune3pro-robin)
      ZIP_NAME="Neptune3Pro-HDR-Performance-Pad7-Complete-Guide.zip"
      PACKAGE_LABEL="Neptune 3 Pro / Robin Nano / Pad 7"
      CONTROLLER="robin"
      ;;
    neptune3plus-robin)
      ZIP_NAME="Neptune3Plus-HDR-Performance-Pad7-Complete-Guide.zip"
      PACKAGE_LABEL="Neptune 3 Plus / Robin Nano / Pad 7"
      CONTROLLER="robin"
      ;;
    neptune3max-robin)
      ZIP_NAME="Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip"
      PACKAGE_LABEL="Neptune 3 Max / Robin Nano / Pad 7"
      CONTROLLER="robin"
      ;;
    neptune3-skr3ez)
      ZIP_NAME="Neptune3-SKR3EZ-TMC5160Pro-HDR-Performance.zip"
      PACKAGE_LABEL="Neptune 3 / SKR 3 EZ / TMC5160 Pro / Pad 7"
      CONTROLLER="skr"
      ;;
    neptune3pro-skr3ez)
      ZIP_NAME="Neptune3Pro-SKR3EZ-TMC5160Pro-HDR-Performance.zip"
      PACKAGE_LABEL="Neptune 3 Pro / SKR 3 EZ / TMC5160 Pro / Pad 7"
      CONTROLLER="skr"
      ;;
    neptune3plus-skr3ez)
      ZIP_NAME="Neptune3Plus-SKR3EZ-TMC5160Pro-HDR-Performance.zip"
      PACKAGE_LABEL="Neptune 3 Plus / SKR 3 EZ / TMC5160 Pro / Pad 7"
      CONTROLLER="skr"
      ;;
    neptune3max-skr3ez)
      ZIP_NAME="Neptune3Max-SKR3EZ-TMC5160Pro-HDR-Performance.zip"
      PACKAGE_LABEL="Neptune 3 Max / SKR 3 EZ / TMC5160 Pro / Pad 7"
      CONTROLLER="skr"
      ;;
    *) die "Unknown package ID: ${PACKAGE_ID}. Run with --list." ;;
  esac
}

resolve_host_type() {
  local model=""
  case "${HOST_TYPE}" in
    auto)
      if [[ -r /proc/device-tree/model ]]; then
        model="$(tr -d '\0' </proc/device-tree/model)"
      fi
      case "${model}" in
        *"Compute Module 4"*) HOST_TYPE="cm4" ;;
        *"BTT-CB1"*|*"BIGTREETECH CB1"*) HOST_TYPE="cb1" ;;
        *) HOST_TYPE="unchanged" ;;
      esac
      ;;
    cb1|cm4) ;;
    *) die "--host must be auto, cb1, or cm4." ;;
  esac
}

adapt_host_config() {
  local printer_cfg="$1"
  if [[ "${HOST_TYPE}" == "cm4" ]]; then
    if grep -q '^\[mcu CB1\]' "${printer_cfg}"; then
      sed -i \
        -e 's/^\[mcu CB1\].*$/[mcu CM4]  # BIGTREETECH Pad 7 with Raspberry Pi CM4 host MCU/' \
        -e 's/CB1:None/CM4:None/' \
        -e 's/spidev1\.1/spidev0.1/' \
        "${printer_cfg}"
    fi
    grep -q '^\[mcu CM4\]' "${printer_cfg}" || die "CM4 adaptation could not find the host MCU block."
    grep -q 'cs_pin: CM4:None' "${printer_cfg}" || die "CM4 adaptation could not set the ADXL chip select."
    grep -q 'spi_bus: spidev0.1' "${printer_cfg}" || die "CM4 adaptation could not set the ADXL SPI bus."
    info "Adapted Pad 7 input shaping for Raspberry Pi CM4"
  elif [[ "${HOST_TYPE}" == "unchanged" ]]; then
    printf 'WARNING: Pad host was not recognized; host-MCU/ADXL settings were left unchanged.\n' >&2
    printf 'Use --host cb1 or --host cm4 when the host type is known.\n' >&2
  fi
}

download_file() {
  local url="$1"
  local destination="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "${url}" --output "${destination}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "${destination}" "${url}"
  else
    die "curl or wget is required."
  fi
}

validate_config_dir() {
  [[ -n "${HOME:-}" && "${HOME}" != "/" ]] || die "HOME is not safe or is not set."
  [[ -n "${CONFIG_DIR}" && "${CONFIG_DIR}" != "/" && "${CONFIG_DIR}" != "${HOME}" ]] || die "Unsafe config directory: ${CONFIG_DIR}"
  [[ -d "${CONFIG_DIR}" ]] || die "Config directory does not exist: ${CONFIG_DIR}"
  [[ "$(basename "${CONFIG_DIR}")" == "config" ]] || die "Config directory must end in /config: ${CONFIG_DIR}"
  CONFIG_DIR="$(cd "${CONFIG_DIR}" && pwd -P)"
  if [[ ! -f "${CONFIG_DIR}/printer.cfg" ]]; then
    if [[ -f "${CONFIG_DIR}/moonraker.conf" || -e "${CONFIG_DIR}/mainsail.cfg" ]]; then
      FRESH_INSTALL=1
    else
      die "No printer.cfg or recognizable Moonraker/Mainsail config found in ${CONFIG_DIR}. Verify --config-dir."
    fi
  fi
}

replace_skr_mcu_id() {
  local printer_cfg="$1"
  local answer=""
  local escaped=""
  local candidates=()

  grep -q 'REPLACE_WITH_YOUR_SKR3_EZ_ID' "${printer_cfg}" || return 0

  if [[ -z "${MCU_ID}" && -d /dev/serial/by-id ]]; then
    shopt -s nullglob
    candidates=(/dev/serial/by-id/*)
    shopt -u nullglob
    if [[ ${#candidates[@]} -eq 1 && -t 0 ]]; then
      printf '\nDetected one serial device:\n  %s\n' "${candidates[0]}"
      printf 'Use this as the SKR MCU ID? [y/N]: '
      read -r answer
      if [[ "${answer}" =~ ^[Yy]$ ]]; then
        MCU_ID="${candidates[0]}"
      fi
    elif [[ ${#candidates[@]} -gt 0 ]]; then
      printf '\nDetected serial devices:\n'
      printf '  %s\n' "${candidates[@]}"
    fi
  fi

  if [[ -n "${MCU_ID}" ]]; then
    [[ "${MCU_ID}" == /dev/serial/by-id/* ]] || die "--mcu-id must be a /dev/serial/by-id/... path."
    escaped="${MCU_ID//\\/\\\\}"
    escaped="${escaped//&/\\&}"
    escaped="${escaped//|/\\|}"
    sed -i "s|/dev/serial/by-id/REPLACE_WITH_YOUR_SKR3_EZ_ID|${escaped}|g" "${printer_cfg}"
    info "Installed SKR MCU ID: ${MCU_ID}"
  else
    printf '\nIMPORTANT: The SKR MCU placeholder remains in printer.cfg.\n'
    printf 'Run: ls /dev/serial/by-id/\n'
    printf 'Then replace REPLACE_WITH_YOUR_SKR3_EZ_ID before restarting Klipper.\n'
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) [[ $# -ge 2 ]] || die "--package requires a value."; PACKAGE_ID="$2"; shift 2 ;;
    --mcu-id) [[ $# -ge 2 ]] || die "--mcu-id requires a value."; MCU_ID="$2"; shift 2 ;;
    --host) [[ $# -ge 2 ]] || die "--host requires a value."; HOST_TYPE="$2"; shift 2 ;;
    --config-dir) [[ $# -ge 2 ]] || die "--config-dir requires a value."; CONFIG_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --list) list_packages; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

command -v unzip >/dev/null 2>&1 || die "unzip is required. Install it before continuing."
validate_config_dir
[[ -n "${PACKAGE_ID}" ]] || select_package
resolve_package
resolve_host_type

printf '\nHDR Performance Neptune 3 installer\n'
printf 'Package:    %s\n' "${PACKAGE_LABEL}"
printf 'Config dir: %s\n' "${CONFIG_DIR}"
printf 'Source:     %s/%s\n' "${RAW_BASE}" "${ZIP_NAME}"
printf 'Pad host:   %s\n' "${HOST_TYPE}"
if [[ ${FRESH_INSTALL} -eq 1 ]]; then
  printf 'Mode:       fresh install (no existing printer.cfg)\n'
fi

if [[ ${ASSUME_YES} -ne 1 ]]; then
  printf '\nType INSTALL to download, back up, and copy this package: '
  read -r confirmation
  [[ "${confirmation}" == "INSTALL" ]] || die "Installation cancelled."
fi

TEMP_DIR="$(mktemp -d -t hdr-neptune-install.XXXXXX)"
ARCHIVE_PATH="${TEMP_DIR}/${ZIP_NAME}"
EXTRACT_DIR="${TEMP_DIR}/extracted"
mkdir -p "${EXTRACT_DIR}"

info "Downloading ${ZIP_NAME}"
download_file "${RAW_BASE}/${ZIP_NAME}" "${ARCHIVE_PATH}"
[[ -s "${ARCHIVE_PATH}" ]] || die "Downloaded archive is empty."

if command -v sha256sum >/dev/null 2>&1; then
  CHECKSUM_FILE="${TEMP_DIR}/SHA256SUMS"
  download_file "${RAW_BASE}/SHA256SUMS" "${CHECKSUM_FILE}" || die "Could not download SHA256SUMS."
  expected_hash="$(awk -v file="${ZIP_NAME}" '$2 == file {print $1}' "${CHECKSUM_FILE}")"
  [[ -n "${expected_hash}" ]] || die "No checksum was published for ${ZIP_NAME}."
  actual_hash="$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')"
  [[ "${actual_hash}" == "${expected_hash}" ]] || die "SHA-256 verification failed for ${ZIP_NAME}."
  info "SHA-256 checksum verified"
else
  printf 'WARNING: sha256sum is unavailable; continuing with the ZIP integrity check only.\n' >&2
fi

info "Checking and extracting the package"
unzip -tq "${ARCHIVE_PATH}" >/dev/null || die "The downloaded ZIP failed its integrity check."
if unzip -Z1 "${ARCHIVE_PATH}" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  die "The ZIP contains an unsafe absolute or parent path."
fi
unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_DIR}"

PACKAGE_ROOT="$(find "${EXTRACT_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "${PACKAGE_ROOT}" ]] || die "Could not find the package root after extraction."
[[ "$(basename "${PACKAGE_ROOT}")" == "${ZIP_NAME%.zip}" ]] || die "Unexpected package root: $(basename "${PACKAGE_ROOT}")"
SOURCE_CONFIG="${PACKAGE_ROOT}/config"
[[ -f "${SOURCE_CONFIG}/printer.cfg" ]] || die "Package does not contain config/printer.cfg."
[[ -f "${SOURCE_CONFIG}/KAMP_Settings.cfg" ]] || die "Package does not contain config/KAMP_Settings.cfg."
[[ -d "${SOURCE_CONFIG}/custom" ]] || die "Package does not contain the custom configuration directories."
adapt_host_config "${SOURCE_CONFIG}/printer.cfg"

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "Dry run successful; no printer files were changed"
  find "${SOURCE_CONFIG}" -maxdepth 3 -type f -print | sed "s|${SOURCE_CONFIG}/||" | sort
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${timestamp}-${PACKAGE_ID}-before-install"
mkdir -p "${BACKUP_DIR}"

info "Backing up the complete existing config to ${BACKUP_DIR}"
cp -a "${CONFIG_DIR}/." "${BACKUP_DIR}/"
if [[ ${FRESH_INSTALL} -eq 1 ]]; then
  [[ -n "$(find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -print -quit)" ]] || die "Fresh-install backup is empty; installation stopped."
else
  [[ -f "${BACKUP_DIR}/printer.cfg" ]] || die "Backup verification failed; installation stopped."
fi

cat > "${BACKUP_DIR}/.hdr-backup-info" <<EOF
created_at=${timestamp}
package_id=${PACKAGE_ID}
fresh_install=${FRESH_INSTALL}
source_config=${CONFIG_DIR}
EOF

info "Replacing HDR-managed files and preserving other host configuration"
rm -rf -- "${CONFIG_DIR}/custom"
rm -f -- "${CONFIG_DIR}/printer.cfg" "${CONFIG_DIR}/KAMP_Settings.cfg"
cp -a "${SOURCE_CONFIG}/." "${CONFIG_DIR}/"

DOC_DIR="${CONFIG_DIR}/HDR_Documentation"
rm -rf -- "${DOC_DIR}"
mkdir -p "${DOC_DIR}"
find "${PACKAGE_ROOT}" -maxdepth 1 -type f -name '*.md' -exec cp -a {} "${DOC_DIR}/" \;

if [[ "${CONTROLLER}" == "skr" ]]; then
  replace_skr_mcu_id "${CONFIG_DIR}/printer.cfg"
fi

cat > "${CONFIG_DIR}/.hdr-performance-install" <<EOF
package_id=${PACKAGE_ID}
package_label=${PACKAGE_LABEL}
installed_at=${timestamp}
backup_dir=${BACKUP_DIR}
source=${RAW_BASE}/${ZIP_NAME}
pad_host=${HOST_TYPE}
EOF

info "Installation files copied successfully"
RESTORE_SCRIPT="${HOME}/hdr-neptune-restore.sh"
if download_file "${RAW_BASE}/restore-config.sh" "${RESTORE_SCRIPT}"; then
  chmod +x "${RESTORE_SCRIPT}"
else
  printf 'WARNING: Could not download the optional restore helper.\n' >&2
  rm -f -- "${RESTORE_SCRIPT}"
fi

printf 'Backup: %s\n' "${BACKUP_DIR}"
printf 'Docs:   %s\n' "${DOC_DIR}"
printf '\nKlipper was NOT restarted. Before restarting:\n'
printf '  1. Open printer.cfg in Mainsail and verify the printer model and controller.\n'
printf '  2. For SKR, verify the MCU serial line and all wiring/pins.\n'
printf '  3. Read HDR_Documentation/START_HERE.md.\n'
printf '  4. Save, restart, and follow the controlled commissioning checklist.\n'
printf '\nRestore command if needed:\n'
printf '  bash "%s" "%s"\n' "${RESTORE_SCRIPT}" "${BACKUP_DIR}"
