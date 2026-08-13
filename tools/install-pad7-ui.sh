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
LANDSCAPE_TOUCH_OFFSET="${HDR_PAD7_LANDSCAPE_TOUCH_OFFSET:-0}"
PORTRAIT_TOUCH_OFFSET="${HDR_PAD7_PORTRAIT_TOUCH_OFFSET:-180}"
[[ -n "${DISPLAY_CONNECTOR}" ]] || die "No connected X11 display was detected on DISPLAY=:0."
[[ -n "${TOUCH_NAME}" ]] || die "No Pad 7 touchscreen was detected on DISPLAY=:0."
[[ "${LANDSCAPE_TOUCH_OFFSET}" =~ ^(0|90|180|270)$ ]] || die "HDR_PAD7_LANDSCAPE_TOUCH_OFFSET must be 0, 90, 180, or 270."
[[ "${PORTRAIT_TOUCH_OFFSET}" =~ ^(0|90|180|270)$ ]] || die "HDR_PAD7_PORTRAIT_TOUCH_OFFSET must be 0, 90, 180, or 270."

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
HDR_PAD7_LANDSCAPE_TOUCH_OFFSET="${LANDSCAPE_TOUCH_OFFSET}"
HDR_PAD7_PORTRAIT_TOUCH_OFFSET="${PORTRAIT_TOUCH_OFFSET}"
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
if [[ -f /etc/X11/xorg.conf.d/91-hdr-pad7-touchscreen.conf ]]; then
  sudo cp -a /etc/X11/xorg.conf.d/91-hdr-pad7-touchscreen.conf \
    "/etc/X11/xorg.conf.d/91-hdr-pad7-touchscreen.conf.hdr-backup-${STAMP}"
fi

if systemctl cat hdr-pad7-rotate.service >/dev/null 2>&1; then
  # Retire the earlier cycle-style service without invoking its old "next"
  # action. A temporary drop-in clears ExecStop before the unit is stopped.
  sudo systemctl disable hdr-pad7-rotate.service || true
  sudo install -d -m 0755 /etc/systemd/system/hdr-pad7-rotate.service.d
  printf '[Service]\nExecStop=\nExecStop=/usr/bin/true\n' | \
    sudo tee /etc/systemd/system/hdr-pad7-rotate.service.d/retire.conf >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl stop hdr-pad7-rotate.service || true
  sudo rm -rf /etc/systemd/system/hdr-pad7-rotate.service.d
  sudo rm -f /etc/systemd/system/hdr-pad7-rotate.service
fi

for ORIENTATION in 0 90 180 270; do
  SERVICE_TMP="$(mktemp)"
  cat >"${SERVICE_TMP}" <<EOF
[Unit]
Description=HDR Performance Pad 7 explicit ${ORIENTATION}-degree orientation

[Service]
Type=oneshot
ExecStart=/usr/bin/true
ExecStop=/usr/bin/env HDR_PAD7_SERVICE_STOP=1 /usr/local/sbin/hdr-pad7-rotate ${ORIENTATION}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  sudo install -m 0644 "${SERVICE_TMP}" \
    "/etc/systemd/system/hdr-pad7-rotate-${ORIENTATION}.service"
  rm -f -- "${SERVICE_TMP}"
done

mkdir -p "${CONFIG_DIR}" "$(dirname "${ASVC_FILE}")"
if [[ -f "${KLIPPERSCREEN_CONFIG}" ]]; then
  cp -a "${KLIPPERSCREEN_CONFIG}" "${KLIPPERSCREEN_CONFIG}.hdr-backup-${STAMP}"
fi
if [[ -f "${ASVC_FILE}" ]]; then
  cp -a "${ASVC_FILE}" "${ASVC_FILE}.hdr-backup-${STAMP}"
fi

MENU_CLEAN="$(mktemp)"
MENU_BLOCK="$(mktemp)"
MENU_TMP="$(mktemp)"
if [[ -f "${KLIPPERSCREEN_CONFIG}" ]]; then
  awk '
    /^# HDR Performance Pad 7 rotation begin$/ {skip=1; next}
    /^# HDR Performance Pad 7 rotation end$/ {skip=0; next}
    /^# HDR Performance Pad 7 controls begin$/ {skip=1; next}
    /^# HDR Performance Pad 7 controls end$/ {skip=0; next}
    /^# HDR Performance Z calibration override begin$/ {skip=1; next}
    /^# HDR Performance Z calibration override end$/ {skip=0; next}
    !skip {print}
  ' "${KLIPPERSCREEN_CONFIG}" >"${MENU_CLEAN}"
fi
cat >"${MENU_BLOCK}" <<'EOF'

# HDR Performance Pad 7 controls begin
[menu __main hdr_macros]
name: Macros
icon: custom-script
panel: gcode_macros
enable: {{ printer.gcode_macros.count > 0 }}

# Override KlipperScreen's stock More > Z Calibrate entry. The stock panel
# starts PROBE_CALIBRATE directly and bypasses the Maxout nozzle-cleaning
# sequence. KlipperScreen automatically opens its TESTZ panel when this macro
# reaches manual-probe mode.
[menu __main more zoffset]
name: Z Calibrate + Clean
icon: z-farther
method: printer.gcode.script
params: {"script":"MANUAL_Z_OFFSET_ADJUST"}
enable: {{ 'MANUAL_Z_OFFSET_ADJUST' in printer.gcode_macros.list }}

[menu __main more hdr_rotation]
name: Screen Rotation
icon: settings

[menu __main more hdr_rotation original]
name: Original Landscape
icon: refresh
method: machine.services.restart
params: {"service":"hdr-pad7-rotate-0"}

[menu __main more hdr_rotation portrait_right]
name: Portrait Right
icon: refresh
method: machine.services.restart
params: {"service":"hdr-pad7-rotate-90"}

[menu __main more hdr_rotation landscape_inverted]
name: Inverted Landscape
icon: refresh
method: machine.services.restart
params: {"service":"hdr-pad7-rotate-180"}

[menu __main more hdr_rotation portrait_left]
name: Portrait Left
icon: refresh
method: machine.services.restart
params: {"service":"hdr-pad7-rotate-270"}
# HDR Performance Pad 7 controls end
EOF

# KlipperScreen owns everything below its auto-generated marker. Insert custom
# menu sections before that marker so a settings save cannot erase them.
if grep -q '^#~# --- Do not edit below this line' "${MENU_CLEAN}"; then
  awk -v block="${MENU_BLOCK}" '
    !inserted && /^#~# --- Do not edit below this line/ {
      while ((getline line < block) > 0) print line
      close(block)
      inserted=1
    }
    {print}
  ' "${MENU_CLEAN}" >"${MENU_TMP}"
else
  cat "${MENU_CLEAN}" "${MENU_BLOCK}" >"${MENU_TMP}"
fi
install -m 0644 "${MENU_TMP}" "${KLIPPERSCREEN_CONFIG}"
rm -f -- "${MENU_CLEAN}" "${MENU_BLOCK}" "${MENU_TMP}"

touch "${ASVC_FILE}"
sed -i '/^hdr-pad7-rotate$/d' "${ASVC_FILE}"
for ORIENTATION in 0 90 180 270; do
  SERVICE_NAME="hdr-pad7-rotate-${ORIENTATION}"
  grep -qxF "${SERVICE_NAME}" "${ASVC_FILE}" || printf '%s\n' "${SERVICE_NAME}" >>"${ASVC_FILE}"
done

sudo systemctl daemon-reload
sudo systemctl enable --now \
  hdr-pad7-rotate-0.service \
  hdr-pad7-rotate-90.service \
  hdr-pad7-rotate-180.service \
  hdr-pad7-rotate-270.service

if [[ ! -f /etc/hdr-pad7-rotation.state ]]; then
  sudo /usr/local/sbin/hdr-pad7-rotate 0
else
  CURRENT_ROTATION="$(cat /etc/hdr-pad7-rotation.state)"
  sudo /usr/local/sbin/hdr-pad7-rotate "${CURRENT_ROTATION}"
fi

sudo systemctl restart moonraker.service

printf '\nHDR Performance Pad 7 controls installed.\n'
printf 'Display: %s\nTouchscreen: %s\n' "${DISPLAY_CONNECTOR}" "${TOUCH_NAME}"
printf 'Touchscreen offsets: landscape %s degrees, portrait %s degrees\n' \
  "${LANDSCAPE_TOUCH_OFFSET}" "${PORTRAIT_TOUCH_OFFSET}"
printf 'KlipperScreen: More > Screen Rotation > choose an explicit orientation\n'
printf 'KlipperScreen: Main Menu > Macros\n'
printf 'Motor release: Move > Disable Motors (the motor-off icon beside Home).\n'
printf 'After releasing motors, home again before any controlled move.\n'
