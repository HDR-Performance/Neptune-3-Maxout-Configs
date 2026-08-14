#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
UPDATER="${REPO_DIR}/update.sh"

[[ -f "${UPDATER}" ]] || { printf 'ERROR: Missing updater: %s\n' "${UPDATER}" >&2; exit 1; }

printf 'HDR Neptune Maxout: applying the installed printer package after repository update.\n'
exec env HDR_MOONRAKER_HOOK=1 bash "${UPDATER}" --yes

