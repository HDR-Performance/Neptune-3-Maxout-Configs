#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
KS_DIR="${HDR_KLIPPERSCREEN_DIR:-${HOME}/KlipperScreen}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
KS_CONFIG="${CONFIG_DIR}/KlipperScreen.conf"
THEME_NAME="neptune-maxout"
THEME_DIR="${KS_DIR}/styles/${THEME_NAME}"
SOURCE_ICON_DIR="${KS_DIR}/styles/material-dark/images"
ROTATION_STATE="${HDR_PAD7_ROTATION_STATE:-/etc/hdr-pad7-rotation.state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RESTORE_MATERIAL_DARK=0
TEMP_DIR=""

cleanup() {
  [[ -z "${TEMP_DIR}" ]] || rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

download_file() {
  local url="$1"
  local destination="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "${url}" --output "${destination}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${destination}" "${url}"
  else
    die "curl or wget is required."
  fi
}

set_theme() {
  local requested_theme="$1"
  local clean_file output_file
  clean_file="$(mktemp)"
  output_file="$(mktemp)"

  if [[ -f "${KS_CONFIG}" ]]; then
    awk '
      /^# HDR Performance Neptune Maxout theme begin$/ {skip=1; next}
      /^# HDR Performance Neptune Maxout theme end$/ {skip=0; next}
      !skip {print}
    ' "${KS_CONFIG}" >"${clean_file}"
  fi

  awk -v requested_theme="${requested_theme}" '
    function emit_theme() {
      print "theme: " requested_theme
      theme_seen=1
    }
    function emit_main() {
      print "# HDR Performance Neptune Maxout theme begin"
      print "[main]"
      print "theme: " requested_theme
      print "# HDR Performance Neptune Maxout theme end"
      print ""
      main_found=1
      theme_seen=1
    }
    /^\[main\][[:space:]]*$/ {
      if (in_main && !theme_seen) emit_theme()
      in_main=1
      main_found=1
      theme_seen=0
      print
      next
    }
    /^\[/ {
      if (in_main && !theme_seen) emit_theme()
      in_main=0
      print
      next
    }
    in_main && /^[[:space:]]*theme[[:space:]]*[:=]/ {
      emit_theme()
      next
    }
    !inserted && /^#~# --- Do not edit below this line/ {
      if (in_main && !theme_seen) emit_theme()
      in_main=0
      if (!main_found) emit_main()
      inserted=1
      print
      next
    }
    {print}
    END {
      if (!inserted) {
        if (in_main && !theme_seen) emit_theme()
        if (!main_found) emit_main()
      }
    }
  ' "${clean_file}" >"${output_file}"
  install -m 0644 "${output_file}" "${KS_CONFIG}"
  rm -f -- "${clean_file}" "${output_file}"
}

apply_orientation_background() {
  local angle="0" source_image
  if [[ -r "${ROTATION_STATE}" ]]; then
    angle="$(tr -d '[:space:]' <"${ROTATION_STATE}")"
  fi
  case "${angle}" in
    90|270) source_image="${THEME_DIR}/background-portrait.png" ;;
    *) source_image="${THEME_DIR}/background-landscape.png" ;;
  esac
  [[ -s "${source_image}" ]] || die "Orientation background is missing: ${source_image}"
  install -m 0644 "${source_image}" "${THEME_DIR}/background.png"
  printf 'Active wallpaper: %s (rotation %s degrees)\n' "$(basename "${source_image}")" "${angle}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-material-dark) RESTORE_MATERIAL_DARK=1; shift ;;
    -h|--help)
      printf 'Usage: %s [--restore-material-dark]\n' "$0"
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
done

command -v systemctl >/dev/null 2>&1 || die "systemd is required."
systemctl cat KlipperScreen.service >/dev/null 2>&1 || die "KlipperScreen.service was not found."
[[ -d "${KS_DIR}/styles" ]] || die "KlipperScreen styles directory not found: ${KS_DIR}/styles"
[[ -d "${SOURCE_ICON_DIR}" ]] || die "Material Dark icon directory not found: ${SOURCE_ICON_DIR}"
mkdir -p "${CONFIG_DIR}"

if [[ ${RESTORE_MATERIAL_DARK} -eq 1 ]]; then
  [[ -f "${KS_CONFIG}" ]] && cp -a "${KS_CONFIG}" "${KS_CONFIG}.hdr-theme-backup-${STAMP}"
  set_theme material-dark
  sudo systemctl restart KlipperScreen.service
  printf 'KlipperScreen restored to Material Dark. The Neptune Maxout theme files were retained.\n'
  exit 0
fi

TEMP_DIR="$(mktemp -d -t hdr-maxout-theme.XXXXXX)"
mkdir -p "${TEMP_DIR}/images"
for relative_path in \
  style.css \
  style.conf \
  background-landscape.png \
  background-portrait.png \
  preview.png \
  preview-portrait.png \
  images/printer.png \
  images/neptune-maxout.png; do
  mkdir -p "$(dirname "${TEMP_DIR}/${relative_path}")"
  download_file "${RAW_BASE}/themes/${THEME_NAME}/${relative_path}" "${TEMP_DIR}/${relative_path}"
done
mkdir -p "${TEMP_DIR}/sounds"
download_file "${RAW_BASE}/assets/maxout-laser.wav" "${TEMP_DIR}/sounds/maxout-laser.wav"

[[ -s "${TEMP_DIR}/style.css" ]] || die "Theme stylesheet download is empty."
[[ -s "${TEMP_DIR}/background-landscape.png" ]] || die "Landscape background download is empty."
[[ -s "${TEMP_DIR}/background-portrait.png" ]] || die "Portrait background download is empty."

if [[ -d "${THEME_DIR}" ]]; then
  cp -a "${THEME_DIR}" "${THEME_DIR}.hdr-backup-${STAMP}"
fi
[[ -f "${KS_CONFIG}" ]] && cp -a "${KS_CONFIG}" "${KS_CONFIG}.hdr-theme-backup-${STAMP}"

rm -rf -- "${THEME_DIR}"
mkdir -p "${THEME_DIR}/images"
cp -a "${SOURCE_ICON_DIR}/." "${THEME_DIR}/images/"
cp -a "${TEMP_DIR}/." "${THEME_DIR}/"
apply_orientation_background
set_theme "${THEME_NAME}"

download_file "${RAW_BASE}/tools/install-pad7-audio.sh" "${TEMP_DIR}/install-pad7-audio.sh"
chmod +x "${TEMP_DIR}/install-pad7-audio.sh"
HDR_CONFIG_DIR="${CONFIG_DIR}" \
HDR_KLIPPERSCREEN_DIR="${KS_DIR}" \
HDR_SOUND_FILE="${TEMP_DIR}/sounds/maxout-laser.wav" \
HDR_RAW_BASE="${RAW_BASE}" \
  "${TEMP_DIR}/install-pad7-audio.sh"

sudo systemctl restart KlipperScreen.service
printf '\nNeptune Maxout KlipperScreen theme installed.\n'
printf 'Theme: %s\n' "${THEME_DIR}"
printf 'Config: %s\n' "${KS_CONFIG}"
printf 'Revert: %s --restore-material-dark\n' "$0"
