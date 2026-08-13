#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
KLIPPERSCREEN_CONFIG="${CONFIG_DIR}/KlipperScreen.conf"
ASVC_FILE="${HOME}/printer_data/moonraker.asvc"
ROTATOR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hdr-pad7-rotate"
STAMP="$(date +%Y%m%d-%H%M%S)"
TEMP_FILE=""

cleanup() {
  [[ -z "${TEMP_FILE}" ]] || rm -f -- "${TEMP_FILE}"
}
trap cleanup EXIT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v systemctl >/dev/null 2>&1 || die "systemd is required."
command -v xrandr >/dev/null 2>&1 || die "xrandr is required."
command -v xinput >/dev/null 2>&1 || die "xinput is required."
systemctl cat KlipperScreen.service >/dev/null 2>&1 || die "KlipperScreen.service was not found."
[[ -d "${CONFIG_DIR}" ]] || die "Klipper config directory not found: ${CONFIG_DIR}"

sudo -v

DISPLAY_CONNECTOR="$(DISPLAY=:0 xrandr --query 2>/dev/null | awk '/ connected primary| connected / {print $1; exit}')"
TOUCH_NAME="$(DISPLAY=:0 xinput list --name-only 2>/dev/null | grep -Ei 'BTT-HDMI7|touchscreen|touch' | head -n 1 || true)"
[[ -n "${DISPLAY_CONNECTOR}" ]] || die "No connected X11 display was detected on DISPLAY=:0."
[[ -n "${TOUCH_NAME}" ]] || die "No Pad 7 touchscreen was detected on DISPLAY=:0."

if [[ ! -f "${ROTATOR_SOURCE}" ]]; then
  TEMP_FILE="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error \
      "${RAW_BASE}/tools/hdr-pad7-rotate" --output "${TEMP_FILE}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${TEMP_FILE}" "${RAW_BASE}/tools/hdr-pad7-rotate"
  else
    die "curl or wget is required."
  fi
  ROTATOR_SOURCE="${TEMP_FILE}"
fi

sudo install -m 0755 "${ROTATOR_SOURCE}" /usr/local/sbin/hdr-pad7-rotate

SETTINGS_TMP="$(mktemp)"
cat >"${SETTINGS_TMP}" <<EOF
HDR_PAD7_DISPLAY="${DISPLAY_CONNECTOR}"
HDR_PAD7_TOUCH="${TOUCH_NAME}"
EOF
sudo install -m 0644 "${SETTINGS_TMP}" /etc/default/hdr-pad7-rotation
rm -f -- "${SETTINGS_TMP}"

if [[ -f /etc/X11/xorg.conf.d/90-hdr-pad7-monitor.conf ]]; then
  sudo cp -a /etc/X11/xorg.conf.d/90-hdr-pad7-monitor.conf \
    "/etc/X11/xorg.conf.d/90-hdr-pad7-monitor.conf.hdr-backup-${STAMP}"
fi
if [[ -f /etc/udev/rules.d/51-hdr-pad7-touchscreen.rules ]]; then
  sudo cp -a /etc/udev/rules.d/51-hdr-pad7-touchscreen.rules \
    "/etc/udev/rules.d/51-hdr-pad7-touchscreen.rules.hdr-backup-${STAMP}"
fi

SERVICE_TMP="$(mktemp)"
cat >"${SERVICE_TMP}" <<'EOF'
[Unit]
Description=HDR Performance Pad 7 rotation control

[Service]
Type=oneshot
ExecStart=/usr/bin/true
ExecStop=/usr/bin/env HDR_PAD7_SERVICE_STOP=1 /usr/local/sbin/hdr-pad7-rotate next
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo install -m 0644 "${SERVICE_TMP}" /etc/systemd/system/hdr-pad7-rotate.service
rm -f -- "${SERVICE_TMP}"

mkdir -p "${CONFIG_DIR}" "$(dirname "${ASVC_FILE}")"
if [[ -f "${KLIPPERSCREEN_CONFIG}" ]]; then
  cp -a "${KLIPPERSCREEN_CONFIG}" "${KLIPPERSCREEN_CONFIG}.hdr-backup-${STAMP}"
fi
if [[ -f "${ASVC_FILE}" ]]; then
  cp -a "${ASVC_FILE}" "${ASVC_FILE}.hdr-backup-${STAMP}"
fi

MENU_TMP="$(mktemp)"
if [[ -f "${KLIPPERSCREEN_CONFIG}" ]]; then
  awk '
    /^# HDR Performance Pad 7 rotation begin$/ {skip=1; next}
    /^# HDR Performance Pad 7 rotation end$/ {skip=0; next}
    !skip {print}
  ' "${KLIPPERSCREEN_CONFIG}" >"${MENU_TMP}"
fi
cat >>"${MENU_TMP}" <<'EOF'

# HDR Performance Pad 7 rotation begin
[menu __main more hdr_rotation]
name: Screen Rotation
icon: settings

[menu __main more hdr_rotation rotate]
name: Rotate Screen 90 Degrees
icon: refresh
method: machine.services.restart
params: {"service":"hdr-pad7-rotate"}
# HDR Performance Pad 7 rotation end
EOF
install -m 0644 "${MENU_TMP}" "${KLIPPERSCREEN_CONFIG}"
rm -f -- "${MENU_TMP}"

touch "${ASVC_FILE}"
grep -qxF 'hdr-pad7-rotate' "${ASVC_FILE}" || printf '%s\n' 'hdr-pad7-rotate' >>"${ASVC_FILE}"

sudo systemctl daemon-reload
sudo systemctl enable --now hdr-pad7-rotate.service

if [[ ! -f /etc/hdr-pad7-rotation.state ]]; then
  sudo /usr/local/sbin/hdr-pad7-rotate 0
else
  CURRENT_ROTATION="$(cat /etc/hdr-pad7-rotation.state)"
  sudo /usr/local/sbin/hdr-pad7-rotate "${CURRENT_ROTATION}"
fi

sudo systemctl restart moonraker.service

printf '\nHDR Performance Pad 7 controls installed.\n'
printf 'Display: %s\nTouchscreen: %s\n' "${DISPLAY_CONNECTOR}" "${TOUCH_NAME}"
printf 'KlipperScreen: More > Screen Rotation > Rotate Screen 90 Degrees\n'
printf 'Motor release: Move > Disable Motors (the motor-off icon beside Home).\n'
printf 'After releasing motors, home again before any controlled move.\n'
