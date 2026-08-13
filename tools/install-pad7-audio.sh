#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
KS_DIR="${HDR_KLIPPERSCREEN_DIR:-${HOME}/KlipperScreen}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
KS_CONFIG="${CONFIG_DIR}/KlipperScreen.conf"
KS_GTK="${KS_DIR}/ks_includes/KlippyGtk.py"
SOUND_DIR="/usr/local/share/neptune-maxout/sounds"
SOUND_FILE="${SOUND_DIR}/maxout-laser.wav"
HELPER="/usr/local/bin/hdr-maxout-sound"
STAMP="$(date +%Y%m%d-%H%M%S)"
SOURCE_SOUND="${HDR_SOUND_FILE:-}"
BOOT_CHANGED=0
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
  local url="$1" destination="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "${url}" --output "${destination}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${destination}" "${url}"
  else
    die "curl or wget is required."
  fi
}

command -v systemctl >/dev/null 2>&1 || die "systemd is required."
command -v aplay >/dev/null 2>&1 || die "aplay is required (install the alsa-utils package)."
[[ -f "${KS_GTK}" ]] || die "KlipperScreen button factory not found: ${KS_GTK}"
systemctl cat KlipperScreen.service >/dev/null 2>&1 || die "KlipperScreen.service was not found."

TEMP_DIR="$(mktemp -d -t hdr-pad7-audio.XXXXXX)"
if [[ -z "${SOURCE_SOUND}" ]]; then
  SOURCE_SOUND="${TEMP_DIR}/maxout-laser.wav"
  download_file "${RAW_BASE}/assets/maxout-laser.wav" "${SOURCE_SOUND}"
fi
[[ -s "${SOURCE_SOUND}" ]] || die "The Maxout laser sound is missing or empty."

sudo install -d -m 0755 "${SOUND_DIR}"
sudo install -m 0644 "${SOURCE_SOUND}" "${SOUND_FILE}"

cat >"${TEMP_DIR}/hdr-maxout-sound" <<'EOF'
#!/usr/bin/env bash
set -u

SOUND="/usr/local/share/neptune-maxout/sounds/maxout-laser.wav"
KS_CONFIG="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}/KlipperScreen.conf"

[[ -r "${SOUND}" ]] || exit 0
if [[ -r "${KS_CONFIG}" ]] && ! grep -Eiq '^[[:space:]]*theme[[:space:]]*[:=][[:space:]]*neptune-maxout([[:space:]]|$)' "${KS_CONFIG}"; then
  exit 0
fi

device="default"
if aplay -l 2>/dev/null | grep -q 'vc4hdmi0'; then
  device="plughw:CARD=vc4hdmi0,DEV=0"
fi

exec 9>"/tmp/hdr-maxout-sound.lock"
flock -n 9 || exit 0
aplay -q -D "${device}" "${SOUND}" >/dev/null 2>&1 || true
EOF
sudo install -m 0755 "${TEMP_DIR}/hdr-maxout-sound" "${HELPER}"

cp -a "${KS_GTK}" "${KS_GTK}.hdr-audio-backup-${STAMP}"
python3 - "${KS_GTK}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

method_marker = "# HDR Performance Maxout sound method begin"
if method_marker not in text:
    needle = "    @staticmethod\n    def Button_busy(widget, busy):"
    method = '''    # HDR Performance Maxout sound method begin
    @staticmethod
    def _hdr_play_click_sound(_widget):
        helper = "/usr/local/bin/hdr-maxout-sound"
        if os.path.isfile(helper):
            try:
                os.spawnl(os.P_NOWAIT, helper, helper)
            except OSError:
                logging.exception("Unable to play the Neptune Maxout UI sound")
    # HDR Performance Maxout sound method end

'''
    if needle not in text:
        raise SystemExit("KlipperScreen Button_busy insertion point was not found")
    text = text.replace(needle, method + needle, 1)

hook = '        b.connect("clicked", self._hdr_play_click_sound)  # HDR Maxout sound hook\n'
if hook not in text:
    needle = '        b.connect("clicked", self.screen.lock_screen.reset_timeout)\n'
    if needle not in text:
        raise SystemExit("KlipperScreen Button click insertion point was not found")
    text = text.replace(needle, needle + hook, 1)

path.write_text(text)
PY

KS_PYTHON="${HOME}/.KlipperScreen-env/bin/python"
[[ -x "${KS_PYTHON}" ]] || KS_PYTHON="$(command -v python3)"
"${KS_PYTHON}" -m py_compile "${KS_GTK}"

model=""
[[ -r /proc/device-tree/model ]] && model="$(tr -d '\0' </proc/device-tree/model)"
if [[ "${model}" == *"Compute Module 4"* ]]; then
  BOOT_CONFIG=""
  for candidate in /boot/firmware/config.txt /boot/config.txt; do
    [[ -f "${candidate}" ]] && { BOOT_CONFIG="${candidate}"; break; }
  done
  [[ -n "${BOOT_CONFIG}" ]] || die "CM4 boot config was not found."
  sudo cp -a "${BOOT_CONFIG}" "${BOOT_CONFIG}.hdr-audio-backup-${STAMP}"
  if grep -Eq '^[[:space:]]*hdmi_drive[[:space:]]*=[[:space:]]*1([[:space:]]*(#.*)?)?$' "${BOOT_CONFIG}"; then
    sudo sed -i -E 's/^([[:space:]]*)hdmi_drive[[:space:]]*=[[:space:]]*1([[:space:]]*(#.*)?)?$/\1hdmi_drive=2 # HDR Pad 7 HDMI audio/' "${BOOT_CONFIG}"
    BOOT_CHANGED=1
  elif ! grep -Eq '^[[:space:]]*hdmi_drive[[:space:]]*=[[:space:]]*2([[:space:]]*(#.*)?)?$' "${BOOT_CONFIG}"; then
    printf '\n# HDR Performance Pad 7 CM4 speaker audio\nhdmi_drive=2\n' | sudo tee -a "${BOOT_CONFIG}" >/dev/null
    BOOT_CHANGED=1
  fi
fi

sudo systemctl restart KlipperScreen.service

printf '\nNeptune Maxout Pad 7 sound installed.\n'
printf 'Sound: %s\n' "${SOUND_FILE}"
printf 'Button hook: %s\n' "${KS_GTK}"
if [[ ${BOOT_CHANGED} -eq 1 ]]; then
  printf 'CM4 HDMI audio was enabled. Reboot the Pad 7 once before testing sound.\n'
else
  printf 'Test: %s\n' "${HELPER}"
fi
