#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
MOONRAKER_CONF="${HDR_MOONRAKER_CONF:-${CONFIG_DIR}/moonraker.conf}"
REPO_DIR="${HDR_REPO_DIR:-${HOME}/Neptune-3-Maxout-Configs}"
ORIGIN="https://github.com/HDR-Performance/Neptune-3-Maxout-Configs.git"
BRANCH="${HDR_BRANCH:-main}"
INCLUDE_NAME="moonraker-hdr-neptune-maxout.conf"
INCLUDE_PATH="${CONFIG_DIR}/${INCLUDE_NAME}"
STAMP="$(date +%Y%m%d-%H%M%S)"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "${CONFIG_DIR}" && "$(basename "${CONFIG_DIR}")" == config ]] || die "Unsafe config directory: ${CONFIG_DIR}"
[[ -f "${MOONRAKER_CONF}" ]] || die "Moonraker configuration not found: ${MOONRAKER_CONF}"
command -v git >/dev/null 2>&1 || die "git is required."

if [[ -e "${REPO_DIR}" && ! -d "${REPO_DIR}/.git" ]]; then
  die "${REPO_DIR} exists but is not the HDR Git repository. Move it manually before continuing."
fi

if [[ -d "${REPO_DIR}/.git" ]]; then
  current_origin="$(git -C "${REPO_DIR}" remote get-url origin 2>/dev/null || true)"
  [[ "${current_origin}" == "${ORIGIN}" || "${current_origin}" == "${ORIGIN%.git}" ]] || die "Existing repository origin is not ${ORIGIN}."
  git -C "${REPO_DIR}" config core.fileMode false
  [[ -z "$(git -C "${REPO_DIR}" status --porcelain)" ]] || die "Existing HDR repository has local changes; Moonraker requires a pristine repository."
  git -C "${REPO_DIR}" fetch --prune origin "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
  if git -C "${REPO_DIR}" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git -C "${REPO_DIR}" switch "${BRANCH}"
  else
    git -C "${REPO_DIR}" switch --track -c "${BRANCH}" "origin/${BRANCH}"
  fi
  git -C "${REPO_DIR}" pull --ff-only origin "${BRANCH}"
else
  git clone --branch "${BRANCH}" --single-branch "${ORIGIN}" "${REPO_DIR}"
  git -C "${REPO_DIR}" config core.fileMode false
fi

chmod +x "${REPO_DIR}/update.sh" "${REPO_DIR}/tools/moonraker-update-hook.sh"

MOONRAKER_BACKUP="${MOONRAKER_CONF}.hdr-update-manager-backup-${STAMP}"
cp -a "${MOONRAKER_CONF}" "${MOONRAKER_BACKUP}"
[[ ! -e "${INCLUDE_PATH}" ]] || cp -a "${INCLUDE_PATH}" "${INCLUDE_PATH}.hdr-backup-${STAMP}"

cat >"${INCLUDE_PATH}" <<EOF
# HDR Performance Neptune Maxout - managed by install-moonraker-update-manager.sh
# Repository intentionally lives outside printer_data/config to avoid overlapping watches.
[update_manager Neptune-Maxout-Configs]
type: git_repo
channel: dev
path: ${REPO_DIR}
origin: ${ORIGIN}
primary_branch: ${BRANCH}
install_script: tools/moonraker-update-hook.sh
is_system_service: False
EOF

if ! grep -Fqx "[include ${INCLUDE_NAME}]" "${MOONRAKER_CONF}"; then
  printf '\n[include %s]\n' "${INCLUDE_NAME}" >>"${MOONRAKER_CONF}"
fi

restart_moonraker() {
  if systemctl restart moonraker.service 2>/dev/null; then
    systemctl is-active --quiet moonraker.service
  else
    sudo systemctl restart moonraker.service
    sudo systemctl is-active --quiet moonraker.service
  fi
}

if ! restart_moonraker; then
  printf 'Moonraker failed after registering the updater; restoring %s\n' "${MOONRAKER_BACKUP}" >&2
  cp -a "${MOONRAKER_BACKUP}" "${MOONRAKER_CONF}"
  rm -f -- "${INCLUDE_PATH}"
  restart_moonraker || true
  die "Update Manager registration was rolled back."
fi

printf 'Registered Neptune-Maxout-Configs in Moonraker Update Manager.\n'
printf 'Repository: %s\n' "${REPO_DIR}"
printf 'Moonraker backup: %s\n' "${MOONRAKER_BACKUP}"

