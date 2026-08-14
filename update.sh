#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
PACKAGE_ID=""
INCLUDE_PRINTER_CFG=0
ASSUME_YES=0
PAD7_UI_MODE="${HDR_PAD7_UI:-auto}"
PAD7_THEME_MODE="${HDR_PAD7_THEME:-auto}"
MOONRAKER_KAMP_MODE="${HDR_MOONRAKER_KAMP:-auto}"
SKR_USB_MODE="${HDR_SKR_USB_RECOVERY:-auto}"
MOONRAKER_UPDATER_MODE="${HDR_MOONRAKER_UPDATER:-auto}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
download() { curl --fail --location --silent --show-error "$1" --output "$2"; }

usage() {
  cat <<'EOF'
HDR Performance package-aware OTA updater

Usage:
  ./update.sh
  ./update.sh --package PACKAGE_ID

Options:
  --package ID           Override the package recorded by the original installer.
  --include-printer-cfg  Also replace printer.cfg (advanced; re-check calibration and MCU ID).
  --pad7-ui MODE         Refresh rotation/touch controls: auto (default), on, or off.
  --pad7-theme MODE      Refresh Maxout theme/sound: auto (default), on, or off.
  --moonraker-kamp MODE  Safe KAMP Moonraker setup: auto (default), on, or off.
  --skr-usb MODE         CM4/SKR USB recovery: auto (default), on, or off.
  --moonraker-updater MODE  Register in Mainsail: auto (default), on, or off.
  --yes                  Skip the UPDATE confirmation.
  --config-dir PATH      Override ~/printer_data/config.
  -h, --help             Show this help.

By default this updates HDR-managed custom/, KAMP_Settings.cfg, documentation,
and refreshes the rotation controls and Maxout theme when Pad 7 hardware is detected.
It preserves printer.cfg, moonraker.conf, mainsail.cfg, KlipperScreen.conf, KAMP/, and logs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) [[ $# -ge 2 ]] || die "--package requires a value"; PACKAGE_ID="$2"; shift 2 ;;
    --include-printer-cfg) INCLUDE_PRINTER_CFG=1; shift ;;
    --pad7-ui) [[ $# -ge 2 ]] || die "--pad7-ui requires a value"; PAD7_UI_MODE="$2"; shift 2 ;;
    --pad7-theme) [[ $# -ge 2 ]] || die "--pad7-theme requires a value"; PAD7_THEME_MODE="$2"; shift 2 ;;
    --moonraker-kamp) [[ $# -ge 2 ]] || die "--moonraker-kamp requires a value"; MOONRAKER_KAMP_MODE="$2"; shift 2 ;;
    --skr-usb) [[ $# -ge 2 ]] || die "--skr-usb requires a value"; SKR_USB_MODE="$2"; shift 2 ;;
    --moonraker-updater) [[ $# -ge 2 ]] || die "--moonraker-updater requires a value"; MOONRAKER_UPDATER_MODE="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --config-dir) [[ $# -ge 2 ]] || die "--config-dir requires a value"; CONFIG_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

case "${PAD7_UI_MODE}" in auto|on|off) ;; *) die "--pad7-ui must be auto, on, or off." ;; esac
case "${PAD7_THEME_MODE}" in auto|on|off) ;; *) die "--pad7-theme must be auto, on, or off." ;; esac
case "${MOONRAKER_KAMP_MODE}" in auto|on|off) ;; *) die "--moonraker-kamp must be auto, on, or off." ;; esac
case "${SKR_USB_MODE}" in auto|on|off) ;; *) die "--skr-usb must be auto, on, or off." ;; esac
case "${MOONRAKER_UPDATER_MODE}" in auto|on|off) ;; *) die "--moonraker-updater must be auto, on, or off." ;; esac

if [[ -z "${PACKAGE_ID}" && -f "${CONFIG_DIR}/.hdr-performance-install" ]]; then
  PACKAGE_ID="$(sed -n 's/^package_id=//p' "${CONFIG_DIR}/.hdr-performance-install" | head -n1)"
fi
[[ -n "${PACKAGE_ID}" ]] || die "No installed package identity was found. Use --package with the exact printer/controller ID."
case "${PACKAGE_ID}" in
  neptune3-robin) ZIP="Neptune3-HDR-Performance-Pad7-Complete-Guide.zip" ;;
  neptune3pro-robin) ZIP="Neptune3Pro-HDR-Performance-Pad7-Complete-Guide.zip" ;;
  neptune3plus-robin) ZIP="Neptune3Plus-HDR-Performance-Pad7-Complete-Guide.zip" ;;
  neptune3max-robin) ZIP="Neptune3Max-HDR-Performance-Pad7-Complete-Guide.zip" ;;
  neptune3-skr3ez) ZIP="Neptune3-SKR3EZ-TMC5160Pro-HDR-Performance.zip" ;;
  neptune3pro-skr3ez) ZIP="Neptune3Pro-SKR3EZ-TMC5160Pro-HDR-Performance.zip" ;;
  neptune3plus-skr3ez) ZIP="Neptune3Plus-SKR3EZ-TMC5160Pro-HDR-Performance.zip" ;;
  neptune3max-skr3ez) ZIP="Neptune3Max-SKR3EZ-TMC5160Pro-HDR-Performance.zip" ;;
  *) die "Unknown package ID: ${PACKAGE_ID}" ;;
esac

[[ -d "${CONFIG_DIR}" && "$(basename "${CONFIG_DIR}")" == config ]] || die "Unsafe or missing config directory: ${CONFIG_DIR}"
[[ -f "${CONFIG_DIR}/printer.cfg" ]] || die "printer.cfg is missing; use install.sh for a fresh installation."

temp_dir="$(mktemp -d)"
trap 'rm -rf -- "${temp_dir}"' EXIT
download "${RAW_BASE}/${ZIP}" "${temp_dir}/package.zip"
command -v unzip >/dev/null 2>&1 || die "unzip is required."
unzip -q "${temp_dir}/package.zip" -d "${temp_dir}/package"
source_config="$(find "${temp_dir}/package" -type d -name config -print -quit)"
[[ -n "${source_config}" && -d "${source_config}/custom" && -f "${source_config}/KAMP_Settings.cfg" ]] || die "Downloaded package structure is invalid."

printf 'Package: %s\n' "${PACKAGE_ID}"
printf 'Target:  %s\n' "${CONFIG_DIR}"
printf 'Updates: custom/, KAMP_Settings.cfg, HDR_Documentation/'
[[ ${INCLUDE_PRINTER_CFG} -eq 1 ]] && printf ', printer.cfg'
printf '\nPreserves: Moonraker, Mainsail, KlipperScreen, updater-managed KAMP/, and all other host files.\n'
printf 'Pad 7 rotation/touch: %s; Maxout theme/sound: %s\n' "${PAD7_UI_MODE}" "${PAD7_THEME_MODE}"
printf 'Moonraker/KAMP: %s; CM4/SKR USB recovery: %s\n' "${MOONRAKER_KAMP_MODE}" "${SKR_USB_MODE}"
printf 'Moonraker Update Manager registration: %s\n' "${MOONRAKER_UPDATER_MODE}"
if [[ ${ASSUME_YES} -ne 1 ]]; then
  printf 'Type UPDATE to continue: '
  read -r answer
  [[ "${answer}" == UPDATE ]] || die "Update cancelled."
fi

stamp="$(date +%Y%m%d-%H%M%S)"
backup="${HOME}/printer_data/config_backups/${stamp}-${PACKAGE_ID}-before-ota-update"
mkdir -p "${backup}"
cp -a "${CONFIG_DIR}/custom" "${backup}/" 2>/dev/null || true
cp -a "${CONFIG_DIR}/KAMP_Settings.cfg" "${backup}/" 2>/dev/null || true
cp -a "${CONFIG_DIR}/HDR_Documentation" "${backup}/" 2>/dev/null || true
[[ ${INCLUDE_PRINTER_CFG} -eq 0 ]] || cp -a "${CONFIG_DIR}/printer.cfg" "${backup}/"

rm -rf -- "${CONFIG_DIR}/custom" "${CONFIG_DIR}/HDR_Documentation"
cp -a "${source_config}/custom" "${CONFIG_DIR}/custom"
cp -a "${source_config}/KAMP_Settings.cfg" "${CONFIG_DIR}/KAMP_Settings.cfg"
mkdir -p "${CONFIG_DIR}/HDR_Documentation"
package_root="$(dirname "${source_config}")"
find "${package_root}" -maxdepth 1 -type f -name '*.md' -exec cp -a {} "${CONFIG_DIR}/HDR_Documentation/" \;

if [[ ${INCLUDE_PRINTER_CFG} -eq 1 ]]; then
  old_serial="$(sed -n '/^\[mcu\][[:space:]]*$/,/^\[/s/^[[:space:]]*serial:[[:space:]]*//p' "${CONFIG_DIR}/printer.cfg" | head -n1)"
  cp -a "${source_config}/printer.cfg" "${CONFIG_DIR}/printer.cfg"
  if [[ "${PACKAGE_ID}" == *-skr3ez && -n "${old_serial}" && "${old_serial}" == /dev/serial/by-id/* ]]; then
    sed -i "s|/dev/serial/by-id/REPLACE_WITH_YOUR_SKR3_EZ_ID|${old_serial}|" "${CONFIG_DIR}/printer.cfg"
  fi
fi

cat >"${CONFIG_DIR}/.hdr-performance-update" <<EOF
package_id=${PACKAGE_ID}
updated_at=${stamp}
included_printer_cfg=${INCLUDE_PRINTER_CFG}
backup_dir=${backup}
EOF

pad7_detected() {
  command -v systemctl >/dev/null 2>&1 || return 1
  command -v xrandr >/dev/null 2>&1 || return 1
  command -v xinput >/dev/null 2>&1 || return 1
  systemctl cat KlipperScreen.service >/dev/null 2>&1 || return 1
  DISPLAY=:0 xrandr --query 2>/dev/null | grep -q '1024x600' || return 1
  DISPLAY=:0 xinput list --name-only 2>/dev/null | grep -Eiq 'BTT-HDMI7|ILITEK-TP' || return 1
}

run_pad7_ui_update() {
  local installer="${temp_dir}/install-pad7-ui.sh"
  case "${PAD7_UI_MODE}" in
    off) printf 'Pad 7 rotation/touch refresh disabled.\n'; return 0 ;;
    auto) pad7_detected || { printf 'Pad 7 hardware not detected; rotation/touch settings were not changed.\n'; return 0; } ;;
    on) ;;
  esac
  download "${RAW_BASE}/tools/install-pad7-ui.sh" "${installer}"
  download "${RAW_BASE}/tools/hdr-pad7-rotate" "${temp_dir}/hdr-pad7-rotate"
  chmod +x "${installer}" "${temp_dir}/hdr-pad7-rotate"
  HDR_CONFIG_DIR="${CONFIG_DIR}" HDR_RAW_BASE="${RAW_BASE}" "${installer}"
}

run_pad7_theme_update() {
  local installer="${temp_dir}/install-neptune-maxout-theme.sh"
  case "${PAD7_THEME_MODE}" in
    off) printf 'Neptune Maxout theme/sound refresh disabled.\n'; return 0 ;;
    auto) pad7_detected || { printf 'Pad 7 hardware not detected; theme and sound were not changed.\n'; return 0; } ;;
    on) ;;
  esac
  download "${RAW_BASE}/tools/install-neptune-maxout-theme.sh" "${installer}"
  chmod +x "${installer}"
  HDR_CONFIG_DIR="${CONFIG_DIR}" HDR_RAW_BASE="${RAW_BASE}" "${installer}"
}

detect_host_type() {
  local model=""
  [[ -r /proc/device-tree/model ]] && model="$(tr -d '\0' </proc/device-tree/model)"
  case "${model}" in
    *"Compute Module 4"*) printf 'cm4' ;;
    *"BTT-CB1"*|*"BIGTREETECH CB1"*) printf 'cb1' ;;
    *"Raspberry Pi 4 Model"*) printf 'pi4' ;;
    *) printf 'unknown' ;;
  esac
}

run_moonraker_kamp_update() {
  local installer="${temp_dir}/configure-moonraker-kamp.sh"
  if [[ "${HDR_MOONRAKER_HOOK:-0}" == 1 ]]; then
    printf 'Running inside Moonraker Update Manager; Moonraker restart preflight skipped.\n'
    return 0
  fi
  case "${MOONRAKER_KAMP_MODE}" in
    off) printf 'Moonraker KAMP preflight disabled.\n'; return 0 ;;
    auto) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || { printf 'moonraker.conf not found; KAMP preflight skipped.\n'; return 0; } ;;
    on) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || return 1 ;;
  esac
  download "${RAW_BASE}/tools/configure-moonraker-kamp.sh" "${installer}"
  chmod +x "${installer}"
  HDR_CONFIG_DIR="${CONFIG_DIR}" "${installer}"
}

current_printer_mcu_path() {
  awk '
    /^\[mcu\][[:space:]]*(#.*)?$/ {in_mcu=1; next}
    in_mcu && /^\[/ {exit}
    in_mcu && /^[[:space:]]*serial[[:space:]]*:/ {
      sub(/^[[:space:]]*serial[[:space:]]*:[[:space:]]*/, "")
      sub(/[[:space:]]*(#.*)?$/, "")
      print
      exit
    }
  ' "${CONFIG_DIR}/printer.cfg"
}

run_skr_usb_update() {
  local host_type mcu_path installer
  [[ "${PACKAGE_ID}" == *-skr3ez ]] || return 0
  host_type="$(detect_host_type)"
  case "${SKR_USB_MODE}" in
    off) printf 'SKR USB recovery disabled.\n'; return 0 ;;
    auto) [[ "${host_type}" == cm4 ]] || { printf 'Host %s does not need automatic CM4/SKR USB recovery.\n' "${host_type}"; return 0; } ;;
    on) ;;
  esac
  mcu_path="$(current_printer_mcu_path)"
  if [[ "${mcu_path}" != /dev/serial/by-id/* ]]; then
    printf 'WARNING: No stable SKR /dev/serial/by-id path was found in printer.cfg; USB recovery skipped.\n' >&2
    [[ "${SKR_USB_MODE}" != on ]] && return 0
    return 1
  fi
  installer="${temp_dir}/install-skr-usb-recovery.sh"
  download "${RAW_BASE}/tools/install-skr-usb-recovery.sh" "${installer}"
  chmod +x "${installer}"
  "${installer}" "${mcu_path}"
}

run_moonraker_updater_registration() {
  local installer="${temp_dir}/install-moonraker-update-manager.sh"
  if [[ "${HDR_MOONRAKER_HOOK:-0}" == 1 ]]; then
    printf 'Running from Moonraker Update Manager; registration refresh skipped.\n'
    return 0
  fi
  case "${MOONRAKER_UPDATER_MODE}" in
    off) printf 'Moonraker updater registration disabled.\n'; return 0 ;;
    auto) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || { printf 'moonraker.conf not found; updater registration skipped.\n'; return 0; } ;;
    on) [[ -f "${CONFIG_DIR}/moonraker.conf" ]] || return 1 ;;
  esac
  download "${RAW_BASE}/tools/install-moonraker-update-manager.sh" "${installer}"
  chmod +x "${installer}"
  HDR_CONFIG_DIR="${CONFIG_DIR}" "${installer}"
}

if ! run_pad7_ui_update; then
  [[ "${PAD7_UI_MODE}" != on ]] || die "Required Pad 7 rotation/touch refresh failed."
  printf 'WARNING: Package files updated, but the optional Pad 7 rotation/touch refresh failed.\n' >&2
fi
if ! run_pad7_theme_update; then
  [[ "${PAD7_THEME_MODE}" != on ]] || die "Required Neptune Maxout theme refresh failed."
  printf 'WARNING: Package files updated, but the optional theme/sound refresh failed.\n' >&2
fi
if ! run_moonraker_kamp_update; then
  [[ "${MOONRAKER_KAMP_MODE}" != on ]] || die "Required Moonraker KAMP preflight failed."
  printf 'WARNING: Package files updated, but the optional Moonraker KAMP preflight failed or rolled back.\n' >&2
fi
if ! run_skr_usb_update; then
  [[ "${SKR_USB_MODE}" != on ]] || die "Required CM4/SKR USB recovery refresh failed."
  printf 'WARNING: Package files updated, but the optional CM4/SKR USB recovery refresh failed.\n' >&2
fi
if ! run_moonraker_updater_registration; then
  [[ "${MOONRAKER_UPDATER_MODE}" != on ]] || die "Required Moonraker updater registration failed."
  printf 'WARNING: Package files updated, but Update Manager registration failed or rolled back.\n' >&2
fi

printf 'OTA update staged successfully. Backup: %s\n' "${backup}"
printf 'Review the files in Mainsail, then issue RESTART when ready.\n'

