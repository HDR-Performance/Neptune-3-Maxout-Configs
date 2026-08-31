#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
KLIPPERSCREEN_CONFIG="${CONFIG_DIR}/KlipperScreen.conf"
KLIPPERSCREEN_DIR="${HDR_KLIPPERSCREEN_DIR:-${HOME}/KlipperScreen}"
Z_SETUP_TARGET="${KLIPPERSCREEN_DIR}/panels/z_offset_setup.py"
Z_CALIBRATE_TARGET="${KLIPPERSCREEN_DIR}/panels/zcalibrate.py"
MAIN_MENU_TARGET="${KLIPPERSCREEN_DIR}/panels/main_menu.py"
ASVC_FILE="${HOME}/printer_data/moonraker.asvc"
ROTATOR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hdr-pad7-rotate"
Z_SETUP_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/klipperscreen-panels/z_offset_setup.py"
STAMP="$(date +%Y%m%d-%H%M%S)"
TEMP_DIR="$(mktemp -d -t hdr-pad7-ui.XXXXXX)"
ROTATION_ONLY=0

for ARG in "$@"; do
  case "${ARG}" in
    --rotation-only) ROTATION_ONLY=1 ;;
    -h|--help)
      printf 'Usage: %s [--rotation-only]\n' "$0"
      exit 0
      ;;
    *) printf 'ERROR: Unknown option: %s\n' "${ARG}" >&2; exit 2 ;;
  esac
done

cleanup() {
  rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

download() {
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "$1" --output "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    die "curl or wget is required."
  fi
}

command -v systemctl >/dev/null 2>&1 || die "systemd is required."
command -v xrandr >/dev/null 2>&1 || die "xrandr is required."
command -v xinput >/dev/null 2>&1 || die "xinput is required."
systemctl cat KlipperScreen.service >/dev/null 2>&1 || die "KlipperScreen.service was not found."
[[ -d "${CONFIG_DIR}" ]] || die "Klipper config directory not found: ${CONFIG_DIR}"

as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ ${EUID} -ne 0 ]]; then
  sudo -v
fi

DISPLAY_CONNECTOR="$(DISPLAY=:0 xrandr --query 2>/dev/null | awk '/ connected primary| connected / {print $1; exit}')"
TOUCH_NAME="$(DISPLAY=:0 xinput list --name-only 2>/dev/null | grep -Ei 'BTT-HDMI7|touchscreen|touch' | head -n 1 || true)"
LANDSCAPE_TOUCH_OFFSET="${HDR_PAD7_LANDSCAPE_TOUCH_OFFSET:-0}"
PORTRAIT_TOUCH_OFFSET="${HDR_PAD7_PORTRAIT_TOUCH_OFFSET:-180}"
[[ -n "${DISPLAY_CONNECTOR}" ]] || die "No connected X11 display was detected on DISPLAY=:0."
[[ -n "${TOUCH_NAME}" ]] || die "No Pad 7 touchscreen was detected on DISPLAY=:0."
[[ "${LANDSCAPE_TOUCH_OFFSET}" =~ ^(0|90|180|270)$ ]] || die "HDR_PAD7_LANDSCAPE_TOUCH_OFFSET must be 0, 90, 180, or 270."
[[ "${PORTRAIT_TOUCH_OFFSET}" =~ ^(0|90|180|270)$ ]] || die "HDR_PAD7_PORTRAIT_TOUCH_OFFSET must be 0, 90, 180, or 270."

if [[ ! -f "${ROTATOR_SOURCE}" ]]; then
  ROTATOR_SOURCE="${TEMP_DIR}/hdr-pad7-rotate"
  download "${RAW_BASE}/tools/hdr-pad7-rotate" "${ROTATOR_SOURCE}"
fi

as_root install -m 0755 "${ROTATOR_SOURCE}" /usr/local/sbin/hdr-pad7-rotate

# Z Calibrate + Clean is a core Pad 7 control. Install and validate its panel
# before writing the menu entry so an interrupted or partial OTA update cannot
# leave a button that points to a missing Python file.
if [[ ${ROTATION_ONLY} -eq 0 ]]; then
  [[ -d "${KLIPPERSCREEN_DIR}/panels" ]] || \
    die "KlipperScreen panels directory was not found: ${KLIPPERSCREEN_DIR}/panels"
  Z_SETUP_PAYLOAD="${TEMP_DIR}/z_offset_setup.py"
  if [[ -f "${Z_SETUP_SOURCE}" ]]; then
    cp -a "${Z_SETUP_SOURCE}" "${Z_SETUP_PAYLOAD}"
  else
    download "${RAW_BASE}/tools/klipperscreen-panels/z_offset_setup.py" "${Z_SETUP_PAYLOAD}"
  fi
  python3 -m py_compile "${Z_SETUP_PAYLOAD}" || die "The Z Offset Setup panel failed Python validation."
  if [[ -f "${Z_SETUP_TARGET}" ]]; then
    cp -a "${Z_SETUP_TARGET}" "${Z_SETUP_TARGET}.hdr-backup-${STAMP}"
  fi
  PANEL_OWNER="$(stat -c '%u' "${KLIPPERSCREEN_DIR}/panels")"
  PANEL_GROUP="$(stat -c '%g' "${KLIPPERSCREEN_DIR}/panels")"
  as_root install -o "${PANEL_OWNER}" -g "${PANEL_GROUP}" -m 0644 \
    "${Z_SETUP_PAYLOAD}" "${Z_SETUP_TARGET}"
  [[ -s "${Z_SETUP_TARGET}" ]] || die "Z Offset Setup panel installation failed: ${Z_SETUP_TARGET}"

  # Stock KlipperScreen leaves the nozzle at paper-test height after ACCEPT.
  # Patch that exact action idempotently so a saved Z offset cannot leave the
  # nozzle touching the build plate. Preserve the vendor file for rollback.
  [[ -f "${Z_CALIBRATE_TARGET}" ]] || \
    die "KlipperScreen Z calibration panel was not found: ${Z_CALIBRATE_TARGET}"
  Z_CALIBRATE_PAYLOAD="${TEMP_DIR}/zcalibrate.py"
  cp -a "${Z_CALIBRATE_TARGET}" "${Z_CALIBRATE_PAYLOAD}"
  python3 - "${Z_CALIBRATE_PAYLOAD}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
safe_action = 'self._screen._ws.api.gcode_script("ACCEPT\\nG91\\nG0 Z5 F600\\nG90")'
stock_action = 'self._screen._ws.api.gcode_script("ACCEPT")'
if safe_action not in text:
    if stock_action not in text:
        raise SystemExit("Unable to locate the KlipperScreen Z ACCEPT action")
    text = text.replace(stock_action, safe_action, 1)
    path.write_text(text)
PY
  python3 -m py_compile "${Z_CALIBRATE_PAYLOAD}" || \
    die "The patched KlipperScreen Z calibration panel failed Python validation."
  cp -a "${Z_CALIBRATE_TARGET}" "${Z_CALIBRATE_TARGET}.hdr-backup-${STAMP}"
  as_root install -o "${PANEL_OWNER}" -g "${PANEL_GROUP}" -m 0644 \
    "${Z_CALIBRATE_PAYLOAD}" "${Z_CALIBRATE_TARGET}"

  # KlipperScreen's stock portrait dashboard gives the temperature graph three
  # fifths of a 600x1024 display and leaves the controls in a short scrolling
  # region. Keep the exact numeric heater readouts, remove the graph and passive
  # electronics sensors in portrait, and dedicate three fifths to controls.
  [[ -f "${MAIN_MENU_TARGET}" ]] || \
    die "KlipperScreen main-menu panel was not found: ${MAIN_MENU_TARGET}"
  MAIN_MENU_PAYLOAD="${TEMP_DIR}/main_menu.py"
  cp -a "${MAIN_MENU_TARGET}" "${MAIN_MENU_PAYLOAD}"
  python3 - "${MAIN_MENU_PAYLOAD}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

old_layout = '''        if self._screen.vertical_mode:
            self.main_menu.attach(self.create_left_panel(), 0, 0, 1, 3)
            self.labels["menu"] = self.arrangeMenuItems(items, 3, True)
            self.menu_scroll.add(self.labels["menu"])
            self.main_menu.attach(self.menu_scroll, 0, 3, 1, 2)
'''
new_layout = '''        if self._screen.vertical_mode:
            # Compact portrait dashboard: exact heater readings above a roomy
            # three-column control grid, without the oversized history graph.
            self.main_menu.attach(self.create_left_panel(), 0, 0, 1, 2)
            self.labels["menu"] = self.arrangeMenuItems(items, 3, True)
            self.menu_scroll.add(self.labels["menu"])
            self.main_menu.attach(self.menu_scroll, 0, 2, 1, 3)
'''
previous_layout = '''        if self._screen.vertical_mode:
            # Compact portrait dashboard: exact heater readings above a roomy
            # three-column control grid, without the oversized history graph.
            self.main_menu.attach(self.create_left_panel(), 0, 0, 1, 1)
            self.labels["menu"] = self.arrangeMenuItems(items, 3, True)
            self.menu_scroll.add(self.labels["menu"])
            self.main_menu.attach(self.menu_scroll, 0, 1, 1, 4)
'''
old_hide = '''            self.main_menu.attach(top, 0, 0, 1, 3)
            self.main_menu.attach(self.menu_scroll, 0, 3, 1, 2)
'''
new_hide = '''            self.main_menu.attach(top, 0, 0, 1, 2)
            self.main_menu.attach(self.menu_scroll, 0, 2, 1, 3)
'''
previous_hide = '''            self.main_menu.attach(top, 0, 0, 1, 1)
            self.main_menu.attach(self.menu_scroll, 0, 1, 1, 4)
'''
old_sensor = '''        elif self._config.get_main_config().getboolean("only_heaters", False):
            return False
        else:
'''
new_sensor = '''        elif self._screen.vertical_mode:
            # MCU/host sensors remain available elsewhere; omit them from the
            # small portrait home screen so its heater list never scrolls.
            return False
        elif self._config.get_main_config().getboolean("only_heaters", False):
            return False
        else:
'''
old_visibility = '''        if self.left_panel is None:
            logging.info("No left panel")
            return
        count = 0
'''
new_visibility = '''        if self.left_panel is None:
            logging.info("No left panel")
            return
        if self._screen.vertical_mode:
            force_hide = True
        count = 0
'''

for old, previous, new, label in (
    (old_layout, previous_layout, new_layout, "portrait layout"),
    (old_hide, previous_hide, new_hide, "portrait keypad restore"),
):
    if new in text:
        continue
    if previous in text:
        text = text.replace(previous, new, 1)
        continue
    if old not in text:
        raise SystemExit(f"Unable to locate KlipperScreen {label}")
    text = text.replace(old, new, 1)

for old, new, label in (
    (old_sensor, new_sensor, "portrait sensor filter"),
    (old_visibility, new_visibility, "portrait graph suppression"),
):
    if new in text:
        continue
    if old not in text:
        raise SystemExit(f"Unable to locate KlipperScreen {label}")
    text = text.replace(old, new, 1)

path.write_text(text)
PY
  python3 -m py_compile "${MAIN_MENU_PAYLOAD}" || \
    die "The compact KlipperScreen main-menu panel failed Python validation."
  cp -a "${MAIN_MENU_TARGET}" "${MAIN_MENU_TARGET}.hdr-backup-${STAMP}"
  as_root install -o "${PANEL_OWNER}" -g "${PANEL_GROUP}" -m 0644 \
    "${MAIN_MENU_PAYLOAD}" "${MAIN_MENU_TARGET}"
fi

SETTINGS_TMP="$(mktemp)"
cat >"${SETTINGS_TMP}" <<EOF
HDR_PAD7_DISPLAY="${DISPLAY_CONNECTOR}"
HDR_PAD7_TOUCH="${TOUCH_NAME}"
HDR_PAD7_LANDSCAPE_TOUCH_OFFSET="${LANDSCAPE_TOUCH_OFFSET}"
HDR_PAD7_PORTRAIT_TOUCH_OFFSET="${PORTRAIT_TOUCH_OFFSET}"
EOF
as_root install -m 0644 "${SETTINGS_TMP}" /etc/default/hdr-pad7-rotation
rm -f -- "${SETTINGS_TMP}"

# Older Pad 7 images commonly ship a fixed 90-monitor.conf rotation. Preserve
# it for rollback; the HDR 99-* file deliberately loads after that factory
# setting and therefore owns the final orientation.
if [[ -f /etc/X11/xorg.conf.d/90-monitor.conf ]]; then
  sudo cp -a /etc/X11/xorg.conf.d/90-monitor.conf \
    "/etc/X11/xorg.conf.d/90-monitor.conf.hdr-backup-${STAMP}"
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

APPLY_SERVICE_TMP="$(mktemp)"
cat >"${APPLY_SERVICE_TMP}" <<'EOF'
[Unit]
Description=Apply saved HDR Pad 7 orientation after KlipperScreen starts
After=KlipperScreen.service
Wants=KlipperScreen.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 5; angle=$(cat /etc/hdr-pad7-rotation.state 2>/dev/null || echo 0); HDR_PAD7_SKIP_KS_RESTART=1 /usr/local/sbin/hdr-pad7-rotate "$angle"'

[Install]
WantedBy=multi-user.target
EOF
sudo install -m 0644 "${APPLY_SERVICE_TMP}" /etc/systemd/system/hdr-pad7-apply.service
rm -f -- "${APPLY_SERVICE_TMP}"

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
    /^\[menu __main more hdr_full_bed_mesh\]$/ {orphan=1; next}
    orphan && /^\[/ {orphan=0}
    /^# HDR Performance Pad 7 rotation begin$/ {skip=1; next}
    /^# HDR Performance Pad 7 rotation end$/ {skip=0; next}
    /^# HDR Performance Pad 7 controls begin$/ {skip=1; next}
    /^# HDR Performance Pad 7 controls end$/ {skip=0; next}
    /^# HDR Performance Z calibration override begin$/ {skip=1; next}
    /^# HDR Performance Z calibration override end$/ {skip=0; next}
    !skip && !orphan {print}
  ' "${KLIPPERSCREEN_CONFIG}" >"${MENU_CLEAN}"
fi
if [[ ${ROTATION_ONLY} -eq 0 ]]; then
cat >"${MENU_BLOCK}" <<'EOF'

# HDR Performance Pad 7 controls begin
[menu __main hdr_macros]
name: Macros
icon: custom-script
panel: gcode_macros
enable: {{ printer.gcode_macros.count > 0 }}

[menu __main hdr_light_brightness]
name: Light Brightness
icon: light
panel: led
enable: {{ printer.leds.count > 0 }}

# Hide KlipperScreen's stock More > Z Calibrate entry. Reusing this exact menu
# path would inherit its `panel: zcalibrate` setting, which takes precedence
# over a gcode method and bypasses the Maxout cleaning sequence.
[menu __main more zoffset]
enable: False

# Use a unique menu path and temperature setup panel. KlipperScreen opens its
# TESTZ panel automatically when the cleaning macro reaches manual-probe mode.
[menu __main more hdr_zoffset_clean]
name: Z Calibrate + Clean
icon: z-farther
panel: z_offset_setup
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
else
cat >"${MENU_BLOCK}" <<'EOF'

# HDR Performance Pad 7 controls begin
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
fi

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
# Some older images leave this file without a final newline. Add one before
# appending so the first HDR service cannot be joined to the prior service.
if [[ -s "${ASVC_FILE}" ]] && [[ "$(tail -c 1 "${ASVC_FILE}" | wc -l)" -eq 0 ]]; then
  printf '\n' >>"${ASVC_FILE}"
fi
sed -i '/^hdr-pad7-rotate$/d' "${ASVC_FILE}"
for ORIENTATION in 0 90 180 270; do
  SERVICE_NAME="hdr-pad7-rotate-${ORIENTATION}"
  grep -qxF "${SERVICE_NAME}" "${ASVC_FILE}" || printf '%s\n' "${SERVICE_NAME}" >>"${ASVC_FILE}"
done

sudo systemctl daemon-reload
sudo systemctl enable --now \
  hdr-pad7-apply.service \
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
sudo systemctl restart KlipperScreen.service

printf '\nHDR Performance Pad 7 controls installed.\n'
printf 'Display: %s\nTouchscreen: %s\n' "${DISPLAY_CONNECTOR}" "${TOUCH_NAME}"
printf 'Touchscreen offsets: landscape %s degrees, portrait %s degrees\n' \
  "${LANDSCAPE_TOUCH_OFFSET}" "${PORTRAIT_TOUCH_OFFSET}"
printf 'KlipperScreen: More > Screen Rotation > choose an explicit orientation\n'
if [[ ${ROTATION_ONLY} -eq 0 ]]; then
  printf 'KlipperScreen: Main Menu > Macros\n'
  printf 'KlipperScreen: Main Menu > Light Brightness (0-255 slider plus Off/On)\n'
  printf 'Portrait dashboard: compact heater readouts, no history graph, expanded controls\n'
  printf 'Z Calibrate + Clean panel: %s\n' "${Z_SETUP_TARGET}"
  printf 'Z calibration safe lift: 5 mm after ACCEPT\n'
  printf 'Bed Level, Bed Mesh, Input Shaper, and Z Calibrate + Clean remain in More.\n'
  printf 'Motor release: Move > Disable Motors (the motor-off icon beside Home).\n'
  printf 'After releasing motors, home again before any controlled move.\n'
fi
