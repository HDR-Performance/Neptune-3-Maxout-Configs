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
PAD7_UI_MODE="${HDR_PAD7_UI:-auto}"
PAD7_THEME_MODE="${HDR_PAD7_THEME:-auto}"
SKR_USB_MODE="${HDR_SKR_USB_RECOVERY:-auto}"
MOONRAKER_KAMP_MODE="${HDR_MOONRAKER_KAMP:-auto}"
MOONRAKER_UPDATER_MODE="${HDR_MOONRAKER_UPDATER:-auto}"
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
  --host TYPE        Klipper host: auto (default), cb1, cm4, or pi4.
  --pad7-ui MODE     Pad 7 controls: auto (default), on, or off.
  --pad7-theme MODE  Neptune Maxout theme: auto (default), on, or off.
  --skr-usb MODE      SKR USB recovery: auto (CM4 default), on, or off.
  --moonraker-kamp MODE  KAMP Moonraker preflight: auto (default), on, or off.
  --moonraker-updater MODE  Register Maxout updater: auto (default), on, or off.
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
1) neptune3-robin       - Neptune 3 / stock Robin Nano / Pad 7 or Raspberry Pi 4
2) neptune3pro-robin    - Neptune 3 Pro / stock Robin Nano / Pad 7 or Raspberry Pi 4
3) neptune3plus-robin   - Neptune 3 Plus / stock Robin Nano / Pad 7 or Raspberry Pi 4
4) neptune3max-robin    - Neptune 3 Max / stock Robin Nano / Pad 7 or Raspberry Pi 4
5) neptune3-skr3ez      - Neptune 3 / SKR 3 EZ / TMC5160 Pro / Pad 7 or Raspberry Pi 4
6) neptune3pro-skr3ez   - Neptune 3 Pro / SKR 3 EZ / TMC5160 Pro / Pad 7 or Raspberry Pi 4
7) neptune3plus-skr3ez  - Neptune 3 Plus / SKR 3 EZ / TMC5160 Pro / Pad 7 or Raspberry Pi 4
8) neptune3max-skr3ez   - Neptune 3 Max / SKR 3 EZ / TMC5160 Pro / Pad 7 or Raspberry Pi 4
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
        *"Raspberry Pi 4 Model"*) HOST_TYPE="pi4" ;;
        *"Compute Module 4"*) HOST_TYPE="cm4" ;;
        *"BTT-CB1"*|*"BIGTREETECH CB1"*) HOST_TYPE="cb1" ;;
        *) HOST_TYPE="unchanged" ;;
      esac
      ;;
    cb1|cm4|pi4) ;;
    *) die "--host must be auto, cb1, cm4, or pi4." ;;
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
  elif [[ "${HOST_TYPE}" == "pi4" ]]; then
    local pi4_cfg="${printer_cfg}.pi4"
    awk '
      /^\[(mcu (CB1|CM4)|adxl345|resonance_tester)\]([[:space:]]*(#.*)?)?$/ {
        skip=1
        next
      }
      skip && /^\[/ {skip=0}
      !skip {print}
    ' "${printer_cfg}" >"${pi4_cfg}"
    mv "${pi4_cfg}" "${printer_cfg}"
    cat >>"${printer_cfg}" <<'EOF'

# HDR Raspberry Pi 4 host mode:
# Pad 7 host-MCU and built-in ADXL345 sections were intentionally removed.
# The printer runs with saved input-shaper values. Configure and test a separately
# wired accelerometer before using SHAPER_CALIBRATE; see docs/18-raspberry-pi4-ssh-install.md.
EOF
    if grep -Eq '^\[(mcu (CB1|CM4)|adxl345|resonance_tester)\]' "${printer_cfg}"; then
      die "Raspberry Pi 4 adaptation could not remove the Pad 7-only host sections."
    fi
    info "Adapted the package for a Raspberry Pi 4 without Pad 7-only MCU/ADXL hardware"
  elif [[ "${HOST_TYPE}" == "unchanged" ]]; then
    printf 'WARNING: Pad host was not recognized; host-MCU/ADXL settings were left unchanged.\n' >&2
    printf 'Use --host cb1, --host cm4, or --host pi4 when the host type is known.\n' >&2
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

pad7_ui_detected() {
  command -v systemctl >/dev/null 2>&1 || return 1
  command -v xrandr >/dev/null 2>&1 || return 1
  command -v xinput >/dev/null 2>&1 || return 1
  systemctl cat KlipperScreen.service >/dev/null 2>&1 || return 1
  DISPLAY=:0 xrandr --query 2>/dev/null | grep -q '1024x600' || return 1
  DISPLAY=:0 xinput list --name-only 2>/dev/null | grep -Eiq 'BTT-HDMI7|ILITEK-TP' || return 1
}

install_pad7_ui() {
  local ui_dir="${TEMP_DIR}/pad7-ui"
  local ui_installer="${ui_dir}/install-pad7-ui.sh"

  case "${PAD7_UI_MODE}" in
    off)
      info "Pad 7 display/touch controls disabled by --pad7-ui off"
      return 0
      ;;
    auto)
      if ! pad7_ui_detected; then
        info "Pad 7 display/touch hardware not detected; UI controls were not changed"
        return 0
      fi
      ;;
    on) ;;
    *) die "--pad7-ui must be auto, on, or off." ;;
  esac

  info "Installing Pad 7 screen, touchscreen, macro-menu, and motor controls"
  mkdir -p "${ui_dir}"
  download_file "${RAW_BASE}/tools/install-pad7-ui.sh" "${ui_installer}"
  download_file "${RAW_BASE}/tools/hdr-pad7-rotate" "${ui_dir}/hdr-pad7-rotate"
  chmod +x "${ui_installer}" "${ui_dir}/hdr-pad7-rotate"
  if ! HDR_CONFIG_DIR="${CONFIG_DIR}" HDR_RAW_BASE="${RAW_BASE}" "${ui_installer}"; then
    if [[ "${PAD7_UI_MODE}" == "on" ]]; then
      die "Required Pad 7 UI installation failed. Printer files remain backed up at ${BACKUP_DIR}."
    fi
    printf 'WARNING: Pad 7 hardware was detected, but its optional UI controls could not be installed.\n' >&2
    printf 'The printer package is installed. Follow docs/15-pad7-display-touch-controls.md to repair the UI.\n' >&2
  fi
}

install_pad7_theme() {
  local theme_installer="${TEMP_DIR}/install-neptune-maxout-theme.sh"

  case "${PAD7_THEME_MODE}" in
    off)
      info "Neptune Maxout theme disabled by --pad7-theme off"
      return 0
      ;;
    auto)
      if ! pad7_ui_detected; then
        info "Pad 7 display/touch hardware not detected; Neptune Maxout theme was not changed"
        return 0
      fi
      ;;
    on) ;;
    *) die "--pad7-theme must be auto, on, or off." ;;
  esac

  info "Installing the Neptune Maxout KlipperScreen theme"
  download_file "${RAW_BASE}/tools/install-neptune-maxout-theme.sh" "${theme_installer}"
  chmod +x "${theme_installer}"
  if ! HDR_CONFIG_DIR="${CONFIG_DIR}" HDR_RAW_BASE="${RAW_BASE}" "${theme_installer}"; then
    if [[ "${PAD7_THEME_MODE}" == "on" ]]; then
      die "Required Neptune Maxout theme installation failed. Printer files remain backed up at ${BACKUP_DIR}."
    fi
    printf 'WARNING: The printer package is installed, but the optional Neptune Maxout theme failed.\n' >&2
    printf 'Follow docs/16-neptune-maxout-klipperscreen-theme.md to install it manually.\n' >&2
  fi
}

install_skr_usb_recovery() {
  local usb_installer="${TEMP_DIR}/install-skr-usb-recovery.sh"
  [[ "${CONTROLLER}" == "skr" ]] || return 0

  case "${SKR_USB_MODE}" in
    off)
      info "SKR USB recovery disabled"
      return 0
      ;;
    auto)
      if [[ "${HOST_TYPE}" != "cm4" ]]; then
        info "SKR USB recovery is not needed automatically on host type ${HOST_TYPE}"
        return 0
      fi
      ;;
    on) ;;
    *) die "--skr-usb must be auto, on, or off." ;;
  esac

  if [[ -z "${MCU_ID}" || "${MCU_ID}" != /dev/serial/by-id/* ]]; then
    printf 'WARNING: CM4 SKR USB recovery was not installed because no stable --mcu-id was selected.\n' >&2
    printf 'Re-run with the exact /dev/serial/by-id/... path after the SKR is connected.\n' >&2
    return 0
  fi

  info "Installing the Pad 7 CM4/SKR USB boot-wait and reconnect recovery"
  download_file "${RAW_BASE}/tools/install-skr-usb-recovery.sh" "${usb_installer}"
  chmod +x "${usb_installer}"
  if ! "${usb_installer}" "${MCU_ID}"; then
    if [[ "${SKR_USB_MODE}" == "on" ]]; then
      die "Required SKR USB recovery installation failed."
    fi
    printf 'WARNING: Printer files were installed, but optional CM4/SKR USB recovery failed.\n' >&2
  fi
}

configure_moonraker_kamp() {
  local preflight="${TEMP_DIR}/configure-moonraker-kamp.sh"
  case "${MOONRAKER_KAMP_MODE}" in
    off) info "Moonraker KAMP preflight disabled"; return 0 ;;
    auto)
      if [[ ! -f "${CONFIG_DIR}/moonraker.conf" ]]; then
        info "moonraker.conf was not found in the config directory; KAMP preflight was skipped"
        return 0
      fi
      ;;
    on) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || die "Required moonraker.conf is missing from ${CONFIG_DIR}." ;;
    *) die "--moonraker-kamp must be auto, on, or off." ;;
  esac

  info "Backing up and configuring Moonraker object processing for KAMP"
  download_file "${RAW_BASE}/tools/configure-moonraker-kamp.sh" "${preflight}"
  chmod +x "${preflight}"
  if ! HDR_CONFIG_DIR="${CONFIG_DIR}" "${preflight}"; then
    [[ "${MOONRAKER_KAMP_MODE}" != on ]] || die "Required Moonraker KAMP preflight failed."
    printf 'WARNING: Printer files were installed, but Moonraker KAMP preflight failed or rolled back.\n' >&2
  fi
}

install_moonraker_updater() {
  local registrar="${TEMP_DIR}/install-moonraker-update-manager.sh"
  case "${MOONRAKER_UPDATER_MODE}" in
    off) info "Moonraker Neptune Maxout updater registration disabled"; return 0 ;;
    auto)
      [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || { info "moonraker.conf not found; updater registration skipped"; return 0; }
      ;;
    on) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || die "Required moonraker.conf is missing from ${CONFIG_DIR}." ;;
    *) die "--moonraker-updater must be auto, on, or off." ;;
  esac

  info "Registering Neptune-Maxout-Configs with Moonraker Update Manager"
  download_file "${RAW_BASE}/tools/install-moonraker-update-manager.sh" "${registrar}"
  chmod +x "${registrar}"
  if ! HDR_CONFIG_DIR="${CONFIG_DIR}" "${registrar}"; then
    [[ "${MOONRAKER_UPDATER_MODE}" != on ]] || die "Required Moonraker updater registration failed."
    printf 'WARNING: Printer files were installed, but the optional Moonraker updater registration failed or rolled back.\n' >&2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) [[ $# -ge 2 ]] || die "--package requires a value."; PACKAGE_ID="$2"; shift 2 ;;
    --mcu-id) [[ $# -ge 2 ]] || die "--mcu-id requires a value."; MCU_ID="$2"; shift 2 ;;
    --host) [[ $# -ge 2 ]] || die "--host requires a value."; HOST_TYPE="$2"; shift 2 ;;
    --pad7-ui) [[ $# -ge 2 ]] || die "--pad7-ui requires a value."; PAD7_UI_MODE="$2"; shift 2 ;;
    --pad7-theme) [[ $# -ge 2 ]] || die "--pad7-theme requires a value."; PAD7_THEME_MODE="$2"; shift 2 ;;
    --skr-usb) [[ $# -ge 2 ]] || die "--skr-usb requires a value."; SKR_USB_MODE="$2"; shift 2 ;;
    --moonraker-kamp) [[ $# -ge 2 ]] || die "--moonraker-kamp requires a value."; MOONRAKER_KAMP_MODE="$2"; shift 2 ;;
    --moonraker-updater) [[ $# -ge 2 ]] || die "--moonraker-updater requires a value."; MOONRAKER_UPDATER_MODE="$2"; shift 2 ;;
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
case "${PAD7_UI_MODE}" in auto|on|off) ;; *) die "--pad7-ui must be auto, on, or off." ;; esac
case "${PAD7_THEME_MODE}" in auto|on|off) ;; *) die "--pad7-theme must be auto, on, or off." ;; esac
case "${SKR_USB_MODE}" in auto|on|off) ;; *) die "--skr-usb must be auto, on, or off." ;; esac
case "${MOONRAKER_KAMP_MODE}" in auto|on|off) ;; *) die "--moonraker-kamp must be auto, on, or off." ;; esac
case "${MOONRAKER_UPDATER_MODE}" in auto|on|off) ;; *) die "--moonraker-updater must be auto, on, or off." ;; esac

printf '\nHDR Performance Neptune 3 installer\n'
printf 'Package:    %s\n' "${PACKAGE_LABEL}"
printf 'Config dir: %s\n' "${CONFIG_DIR}"
printf 'Source:     %s/%s\n' "${RAW_BASE}" "${ZIP_NAME}"
printf 'Host:       %s\n' "${HOST_TYPE}"
printf 'Pad 7 UI:   %s\n' "${PAD7_UI_MODE}"
printf 'Pad 7 theme:%s\n' " ${PAD7_THEME_MODE}"
printf 'SKR USB:    %s\n' "${SKR_USB_MODE}"
printf 'KAMP/Moonraker: %s\n' "${MOONRAKER_KAMP_MODE}"
printf 'Moonraker updater: %s\n' "${MOONRAKER_UPDATER_MODE}"
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
  if [[ "${PAD7_UI_MODE}" == "off" ]]; then
    printf 'Pad 7 UI: disabled\n'
  elif pad7_ui_detected; then
    printf 'Pad 7 UI: detected; controls would be installed\n'
  else
    printf 'Pad 7 UI: not detected in this session\n'
  fi
  if [[ "${PAD7_THEME_MODE}" == "off" ]]; then
    printf 'Pad 7 theme: disabled\n'
  elif pad7_ui_detected; then
    printf 'Pad 7 theme: detected; Neptune Maxout theme would be installed\n'
  else
    printf 'Pad 7 theme: not detected in this session\n'
  fi
  if [[ "${CONTROLLER}" == "skr" && "${SKR_USB_MODE}" == "auto" && "${HOST_TYPE}" == "cm4" ]]; then
    printf 'SKR USB recovery: Pad 7 CM4 detected; recovery would be installed after a stable MCU ID is selected\n'
  else
    printf 'SKR USB recovery: %s\n' "${SKR_USB_MODE}"
  fi
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
pad7_ui=${PAD7_UI_MODE}
pad7_theme=${PAD7_THEME_MODE}
EOF

info "Installation files copied successfully"
RESTORE_SCRIPT="${HOME}/hdr-neptune-restore.sh"
if download_file "${RAW_BASE}/restore-config.sh" "${RESTORE_SCRIPT}"; then
  chmod +x "${RESTORE_SCRIPT}"
else
  printf 'WARNING: Could not download the optional restore helper.\n' >&2
  rm -f -- "${RESTORE_SCRIPT}"
fi

install_pad7_ui
install_pad7_theme
install_skr_usb_recovery
configure_moonraker_kamp
install_moonraker_updater

UPDATE_SCRIPT="${HOME}/hdr-neptune-update.sh"
if download_file "${RAW_BASE}/update.sh" "${UPDATE_SCRIPT}"; then
  chmod +x "${UPDATE_SCRIPT}"
  printf 'OTA updater: %s --package %s\n' "${UPDATE_SCRIPT}" "${PACKAGE_ID}"
else
  printf 'WARNING: Could not download the optional OTA updater.\n' >&2
  rm -f -- "${UPDATE_SCRIPT}"
fi

printf 'Backup: %s\n' "${BACKUP_DIR}"
printf 'Docs:   %s\n' "${DOC_DIR}"
printf '\nKlipper was NOT restarted. Before restarting:\n'
printf '  1. Open printer.cfg in Mainsail and verify the printer model and controller.\n'
printf '  2. For SKR, verify the MCU serial line and all wiring/pins.\n'
printf '  3. Read HDR_Documentation/START_HERE.md.\n'
printf '  4. Save, restart, and follow the controlled commissioning checklist.\n'
printf '  5. On a Pad 7, use More > Screen Rotation for the four fixed orientations.\n'
printf '  6. The Neptune Maxout theme can be changed from KlipperScreen Settings.\n'
printf '\nRestore command if needed:\n'
printf '  bash "%s" "%s"\n' "${RESTORE_SCRIPT}" "${BACKUP_DIR}"

