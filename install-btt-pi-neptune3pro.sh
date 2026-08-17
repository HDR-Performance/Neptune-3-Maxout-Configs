#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
TEMP_DIR="$(mktemp -d -t hdr-btt-pi-install.XXXXXX)"
INSTALLER="${TEMP_DIR}/install.sh"

cleanup() {
  rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

printf '%s\n' 'HDR Performance dedicated installer'
printf '%s\n' 'Target: Neptune 3 Pro / stock Robin Nano / BTT Pi V1.2'
printf '%s\n' 'Mode: manual SSH installation; Pad 7 features and OTA are disabled'
printf '\n'

if command -v curl >/dev/null 2>&1; then
  curl --fail --location --silent --show-error \
    "${RAW_BASE}/install.sh" --output "${INSTALLER}"
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "${INSTALLER}" "${RAW_BASE}/install.sh"
else
  printf 'ERROR: curl or wget is required.\n' >&2
  exit 1
fi

chmod +x "${INSTALLER}"
"${INSTALLER}" "$@" \
  --package neptune3pro-robin \
  --host btt-pi \
  --pad7-ui off \
  --pad7-theme off \
  --skr-usb off \
  --moonraker-updater off
