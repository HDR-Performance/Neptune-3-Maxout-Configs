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
WATCH_SERVICE="hdr-neptune-maxout-update.service"
WATCH_PATH="hdr-neptune-maxout-update.path"
RUN_USER="$(id -un)"
RUN_HOME="${HOME}"
TEMP_DIR=""

cleanup() {
  [[ -z "${TEMP_DIR}" ]] || rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -d "${CONFIG_DIR}" && "$(basename "${CONFIG_DIR}")" == config ]] || die "Unsafe config directory: ${CONFIG_DIR}"
[[ -f "${MOONRAKER_CONF}" ]] || die "Moonraker configuration not found: ${MOONRAKER_CONF}"
command -v git >/dev/null 2>&1 || die "git is required."
command -v systemctl >/dev/null 2>&1 || die "systemd is required."

if [[ -e "${REPO_DIR}" && ! -d "${REPO_DIR}/.git" ]]; then
  die "${REPO_DIR} exists but is not the HDR Git repository. Move it manually before continuing."
fi

if [[ -d "${REPO_DIR}/.git" ]]; then
  current_origin="$(git -C "${REPO_DIR}" remote get-url origin 2>/dev/null || true)"
  [[ "${current_origin}" == "${ORIGIN}" || "${current_origin}" == "${ORIGIN%.git}" ]] || die "Existing repository origin is not ${ORIGIN}."
  git -C "${REPO_DIR}" config core.fileMode false
  [[ -z "$(git -C "${REPO_DIR}" status --porcelain)" ]] || die "Existing HDR repository has local changes; Moonraker requires a pristine repository."
  branch_fetch="+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
  if ! git -C "${REPO_DIR}" config --get-all remote.origin.fetch | grep -Fqx "${branch_fetch}"; then
    git -C "${REPO_DIR}" config --add remote.origin.fetch "${branch_fetch}"
  fi
  git -C "${REPO_DIR}" fetch --prune origin
  if git -C "${REPO_DIR}" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git -C "${REPO_DIR}" switch "${BRANCH}"
  else
    git -C "${REPO_DIR}" switch --track -c "${BRANCH}" "origin/${BRANCH}"
  fi
  git -C "${REPO_DIR}" branch --set-upstream-to="origin/${BRANCH}" "${BRANCH}"
  git -C "${REPO_DIR}" pull --ff-only origin "${BRANCH}"
else
  git clone --branch "${BRANCH}" --single-branch "${ORIGIN}" "${REPO_DIR}"
  git -C "${REPO_DIR}" config core.fileMode false
fi

chmod +x "${REPO_DIR}/update.sh" "${REPO_DIR}/tools/moonraker-update-hook.sh"

TEMP_DIR="$(mktemp -d -t hdr-moonraker-updater.XXXXXX)"
cat >"${TEMP_DIR}/${WATCH_SERVICE}" <<EOF
[Unit]
Description=HDR Neptune Maxout package-aware configuration update
After=network-online.target moonraker.service

[Service]
Type=oneshot
User=${RUN_USER}
Environment=HOME=${RUN_HOME}
Environment=HDR_MOONRAKER_HOOK=1
ExecStart=/bin/bash ${REPO_DIR}/tools/moonraker-update-hook.sh
EOF

cat >"${TEMP_DIR}/${WATCH_PATH}" <<EOF
[Unit]
Description=Watch the HDR Neptune Maxout repository for Moonraker updates

[Path]
PathChanged=${REPO_DIR}/.git/logs/HEAD
Unit=${WATCH_SERVICE}

[Install]
WantedBy=multi-user.target
EOF

sudo install -m 0644 "${TEMP_DIR}/${WATCH_SERVICE}" "/etc/systemd/system/${WATCH_SERVICE}"
sudo install -m 0644 "${TEMP_DIR}/${WATCH_PATH}" "/etc/systemd/system/${WATCH_PATH}"
sudo systemctl daemon-reload
sudo systemctl enable --now "${WATCH_PATH}"

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
printf 'Package update watcher: %s\n' "${WATCH_PATH}"

