#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
BACKUP_ROOT="${HDR_BACKUP_ROOT:-${HOME}/printer_data/config_backups}"
SOURCE_BACKUP="${1:-}"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -n "${HOME:-}" && "${HOME}" != "/" ]] || die "HOME is not safe or is not set."
[[ -n "${CONFIG_DIR}" && "${CONFIG_DIR}" != "/" && "${CONFIG_DIR}" != "${HOME}" ]] || die "Unsafe config directory: ${CONFIG_DIR}"
[[ -d "${CONFIG_DIR}" ]] || die "Current config directory is invalid: ${CONFIG_DIR}"
[[ "$(basename "${CONFIG_DIR}")" == "config" ]] || die "Config directory must end in /config: ${CONFIG_DIR}"
CONFIG_DIR="$(cd "${CONFIG_DIR}" && pwd -P)"

if [[ -z "${SOURCE_BACKUP}" ]]; then
  SOURCE_BACKUP="$(find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort -r | head -n 1 || true)"
fi

[[ -n "${SOURCE_BACKUP}" && -d "${SOURCE_BACKUP}" ]] || die "Backup directory not found. Pass its full path as the first argument."
SOURCE_BACKUP="$(cd "${SOURCE_BACKUP}" && pwd -P)"
[[ -f "${SOURCE_BACKUP}/.hdr-backup-info" || -f "${SOURCE_BACKUP}/printer.cfg" ]] || die "Selected directory is not a recognized HDR backup: ${SOURCE_BACKUP}"
case "${SOURCE_BACKUP}" in
  "${CONFIG_DIR}"|"${CONFIG_DIR}"/*) die "The backup cannot be inside the config directory." ;;
esac

printf 'Current config: %s\n' "${CONFIG_DIR}"
printf 'Restore from:   %s\n' "${SOURCE_BACKUP}"
printf '\nType RESTORE to replace the complete current config: '
read -r confirmation
[[ "${confirmation}" == "RESTORE" ]] || die "Restore cancelled."

timestamp="$(date +%Y%m%d-%H%M%S)"
SAFETY_BACKUP="${BACKUP_ROOT}/${timestamp}-before-restore"
mkdir -p "${SAFETY_BACKUP}"
cp -a "${CONFIG_DIR}/." "${SAFETY_BACKUP}/"
[[ -n "$(find "${SAFETY_BACKUP}" -mindepth 1 -maxdepth 1 -print -quit)" ]] || die "Safety backup failed; restore stopped."

find "${CONFIG_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
cp -a "${SOURCE_BACKUP}/." "${CONFIG_DIR}/"
rm -f -- "${CONFIG_DIR}/.hdr-backup-info"

printf '\nRestore completed. Klipper was NOT restarted.\n'
printf 'Pre-restore safety backup: %s\n' "${SAFETY_BACKUP}"
printf 'Review printer.cfg, then restart from Mainsail when ready.\n'
