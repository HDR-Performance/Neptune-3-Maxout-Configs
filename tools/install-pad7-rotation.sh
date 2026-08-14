#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="HDR-Performance/Neptune-3-Maxout-Configs"
BRANCH="${HDR_BRANCH:-main}"
RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}}"
TEMP_DIR="$(mktemp -d -t hdr-pad7-rotation.XXXXXX)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

download() {
  local name="$1"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --silent --show-error "${RAW_BASE}/tools/${name}" -o "${TEMP_DIR}/${name}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${TEMP_DIR}/${name}" "${RAW_BASE}/tools/${name}"
  else
    echo "curl or wget is required." >&2
    exit 1
  fi
}

download install-pad7-ui.sh
download hdr-pad7-rotate
chmod +x "${TEMP_DIR}/install-pad7-ui.sh" "${TEMP_DIR}/hdr-pad7-rotate"
cd "${TEMP_DIR}"
exec ./install-pad7-ui.sh --rotation-only
