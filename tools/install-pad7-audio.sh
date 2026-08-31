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
IS_CM4=0
IS_CB1=0
TEMP_DIR=""
SESSION_USER="${HDR_RUN_USER:-$(id -un)}"
SESSION_UID="$(id -u "${SESSION_USER}")"
SESSION_HOME="$(getent passwd "${SESSION_USER}" | cut -d: -f6)"
[[ -n "${SESSION_HOME}" ]] || SESSION_HOME="${HOME}"
SESSION_RUNTIME="/run/user/${SESSION_UID}"
SESSION_BUS="unix:path=${SESSION_RUNTIME}/bus"

cleanup() {
  [[ -z "${TEMP_DIR}" ]] || rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

run_session() {
  if [[ "$(id -un)" != "${SESSION_USER}" ]]; then
    command -v runuser >/dev/null 2>&1 || die "runuser is required for the ${SESSION_USER} audio session."
    runuser -u "${SESSION_USER}" -- env \
      HOME="${SESSION_HOME}" \
      XDG_RUNTIME_DIR="${SESSION_RUNTIME}" \
      DBUS_SESSION_BUS_ADDRESS="${SESSION_BUS}" \
      "$@"
  else
    env HOME="${SESSION_HOME}" \
      XDG_RUNTIME_DIR="${SESSION_RUNTIME}" \
      DBUS_SESSION_BUS_ADDRESS="${SESSION_BUS}" \
      "$@"
  fi
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
[[ -f "${KS_GTK}" ]] || die "KlipperScreen button factory not found: ${KS_GTK}"
systemctl cat KlipperScreen.service >/dev/null 2>&1 || die "KlipperScreen.service was not found."

model=""
[[ -r /proc/device-tree/model ]] && model="$(tr -d '\0' </proc/device-tree/model)"
if [[ "${model}" == *"Compute Module 4"* ]]; then
  IS_CM4=1
elif [[ "${model}" == *"BQ-H616"* ]]; then
  IS_CB1=1
fi

if [[ ${IS_CM4} -eq 1 ]]; then
  if ! command -v pw-play >/dev/null 2>&1 || \
     ! command -v wpctl >/dev/null 2>&1 || \
     ! command -v wireplumber >/dev/null 2>&1; then
    command -v apt-get >/dev/null 2>&1 || die "CM4 audio requires apt-get to install PipeWire and WirePlumber."
    printf 'Installing the tested CM4 HDMI audio stack (PipeWire and WirePlumber)...\n'
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      pipewire pipewire-pulse wireplumber pipewire-alsa
  fi

  WIREPLUMBER_DIR="${SESSION_HOME}/.config/wireplumber/wireplumber.conf.d"
  WIREPLUMBER_CONFIG="${WIREPLUMBER_DIR}/51-hdr-pad7-hdmi.conf"
  mkdir -p "${WIREPLUMBER_DIR}"
  [[ ! -f "${WIREPLUMBER_CONFIG}" ]] || \
    cp -a "${WIREPLUMBER_CONFIG}" "${WIREPLUMBER_CONFIG}.hdr-audio-backup-${STAMP}"
  cat >"${WIREPLUMBER_CONFIG}" <<'EOF'
# HDR Performance - keep Pad 7 HDMI0 ready for short KlipperScreen sounds.
monitor.alsa.rules = [
  {
    matches = [
      { node.name = "~alsa_output.*hdmi.*" }
    ]
    actions = {
      update-props = {
        session.suspend-timeout-seconds = 0
        node.pause-on-idle = false
      }
    }
  }
]
EOF

  if [[ ${EUID} -eq 0 ]]; then
    chown -R "${SESSION_USER}:$(id -gn "${SESSION_USER}")" "${SESSION_HOME}/.config/wireplumber"
  fi
  [[ -S "${SESSION_RUNTIME}/bus" ]] || die "The ${SESSION_USER} D-Bus session is unavailable; log in normally before refreshing CM4 audio."
  run_session systemctl --user daemon-reload
  run_session systemctl --user enable --now pipewire.socket pipewire-pulse.socket
  run_session systemctl --user enable --now wireplumber.service
  run_session systemctl --user restart wireplumber.service pipewire.service pipewire-pulse.service
  sleep 3

  HDMI_SINK_ID="$(run_session wpctl status -n 2>/dev/null | sed -nE '/alsa_output.*hdmi.*hdmi-stereo/ {s/.*[[:space:]]([0-9]+)\.[[:space:]].*/\1/p; q;}')"
  [[ -n "${HDMI_SINK_ID}" ]] || die "PipeWire started, but the Pad 7 HDMI sink was not found."
  run_session wpctl set-default "${HDMI_SINK_ID}"
  run_session wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
else
  command -v aplay >/dev/null 2>&1 || die "CB1 audio requires aplay from the alsa-utils package."
fi

TEMP_DIR="$(mktemp -d -t hdr-pad7-audio.XXXXXX)"
if [[ -z "${SOURCE_SOUND}" ]]; then
  SOURCE_SOUND="${TEMP_DIR}/maxout-laser.wav"
  download_file "${RAW_BASE}/assets/maxout-laser.wav" "${SOURCE_SOUND}"
fi
[[ -s "${SOURCE_SOUND}" ]] || die "The Maxout laser sound is missing or empty."

sudo install -d -m 0755 "${SOUND_DIR}"
sudo install -m 0644 "${SOURCE_SOUND}" "${SOUND_FILE}"

# The stock Pad 7 CB1 image already has a working SoX/ALSA click path wired
# into KlipperScreen. Reuse it instead of adding the CM4/PipeWire hook or a
# second GTK click handler.
if [[ ${IS_CB1} -eq 1 && -x /etc/scripts/ks_click.sh && -f /etc/scripts/sound.sh ]] && \
   command -v play >/dev/null 2>&1; then
  sudo cp -a /etc/scripts/sound.sh "/etc/scripts/sound.sh.hdr-audio-backup-${STAMP}"
  CB1_SOUND_TMP="${TEMP_DIR}/sound.sh"
  cat >"${CB1_SOUND_TMP}" <<EOF
#!/bin/bash
# Neptune Maxout KlipperScreen sound using the Pad 7 CB1 factory ALSA path.
export AUDIODRIVER=alsa
play -q ${SOUND_FILE} >/dev/null 2>&1 &
EOF
  sudo install -m 0755 "${CB1_SOUND_TMP}" /etc/scripts/sound.sh
  sudo systemctl restart KlipperScreen.service
  printf '\nNeptune Maxout Pad 7 CB1 laser sound installed.\n'
  printf 'Sound: %s\n' "${SOUND_FILE}"
  printf 'CB1 sound hook: /etc/scripts/ks_click.sh -> /etc/scripts/sound.sh\n'
  exit 0
fi

cat >"${TEMP_DIR}/hdr-maxout-sound" <<'EOF'
#!/usr/bin/env bash
set -u

SOUND="/usr/local/share/neptune-maxout/sounds/maxout-laser.wav"
KS_CONFIG="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}/KlipperScreen.conf"

[[ -r "${SOUND}" ]] || exit 0
if [[ -r "${KS_CONFIG}" ]] && ! grep -Eiq '^[[:space:]]*theme[[:space:]]*[:=][[:space:]]*neptune-maxout([[:space:]]|$)' "${KS_CONFIG}"; then
  exit 0
fi

exec 9>"/tmp/hdr-maxout-sound.lock"
flock -n 9 || exit 0
date --iso-8601=ns >"/tmp/hdr-maxout-sound.last"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"
if command -v pw-play >/dev/null 2>&1; then
  pw-play "${SOUND}" >/dev/null 2>&1 || true
elif command -v paplay >/dev/null 2>&1; then
  paplay "${SOUND}" >/dev/null 2>&1 || true
else
  device="default"
  if aplay -l 2>/dev/null | grep -q 'vc4hdmi0'; then
    device="plughw:CARD=vc4hdmi0,DEV=0"
  fi
  aplay -q -D "${device}" "${SOUND}" >/dev/null 2>&1 || true
fi
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

if [[ ${IS_CM4} -eq 1 ]]; then
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
if [[ ${IS_CM4} -eq 1 ]]; then
  printf 'CM4 audio: PipeWire + WirePlumber, HDMI0 default, 100%% volume, suspend disabled.\n'
fi
