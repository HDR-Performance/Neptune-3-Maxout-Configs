#!/usr/bin/env bash
set -Eeuo pipefail

RAW_BASE="${HDR_RAW_BASE:-https://raw.githubusercontent.com/HDR-Performance/Neptune-3-Maxout-Configs/main}"
CONFIG_DIR="${HDR_CONFIG_DIR:-${HOME}/printer_data/config}"
SERVICE_SCRIPT="/usr/local/lib/hdr-performance/hdr-speed-profile-service.py"
SERVICE_FILE="/etc/systemd/system/hdr-speed-profile.service"

[[ -f "${CONFIG_DIR}/printer.cfg" ]] || { printf 'ERROR: printer.cfg not found.\n' >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { printf 'ERROR: python3 is required.\n' >&2; exit 1; }
command -v systemctl >/dev/null 2>&1 || { printf 'ERROR: systemd is required.\n' >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f -- "${tmp}"' EXIT
curl --fail --location --silent --show-error "${RAW_BASE}/tools/hdr-speed-profile-service.py" --output "${tmp}"
python3 -m py_compile "${tmp}"

if ! sudo -n true 2>/dev/null; then
  [[ -t 0 ]] || { printf 'ERROR: one-time speed service installation requires sudo. Run the SSH installer interactively.\n' >&2; exit 1; }
  sudo -v
fi
sudo install -d -m 0755 /usr/local/lib/hdr-performance
sudo install -m 0755 "${tmp}" "${SERVICE_SCRIPT}"
service_tmp="$(mktemp)"
trap 'rm -f -- "${tmp}" "${service_tmp}"' EXIT
cat >"${service_tmp}" <<EOF
[Unit]
Description=HDR Performance persistent Klipper speed profiles
After=klipper.service
Requires=klipper.service

[Service]
Type=simple
User=root
Environment=HDR_CONFIG_DIR=${CONFIG_DIR}
Environment=HDR_KLIPPY_SOCKET=$(dirname "${CONFIG_DIR}")/comms/klippy.sock
ExecStart=/usr/bin/python3 ${SERVICE_SCRIPT}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
sudo install -m 0644 "${service_tmp}" "${SERVICE_FILE}"
sudo systemctl daemon-reload
sudo systemctl enable --now hdr-speed-profile.service
systemctl is-active --quiet hdr-speed-profile.service
printf 'HDR persistent speed-profile service installed.\n'
