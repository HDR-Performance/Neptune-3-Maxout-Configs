#!/usr/bin/env bash
set -Eeuo pipefail

MCU_PATH="${1:-}"
WAIT_SECONDS="${HDR_MCU_WAIT_SECONDS:-60}"
STAMP="$(date +%Y%m%d-%H%M%S)"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -n "${MCU_PATH}" ]] || die "Usage: $0 /dev/serial/by-id/YOUR_SKR_ID"
[[ "${MCU_PATH}" == /dev/serial/by-id/* ]] || die "The MCU path must be under /dev/serial/by-id/."
[[ "${WAIT_SECONDS}" =~ ^[0-9]+$ ]] || die "HDR_MCU_WAIT_SECONDS must be an integer."
command -v systemctl >/dev/null 2>&1 || die "systemd is required."
command -v udevadm >/dev/null 2>&1 || die "udevadm is required."

if [[ ! -e "${MCU_PATH}" ]]; then
  printf 'WARNING: %s is not present now. The recovery files will still use this exact stable ID.\n' "${MCU_PATH}" >&2
fi

MCU_REAL="$(readlink -f "${MCU_PATH}" 2>/dev/null || true)"
SERIAL_SHORT=""
if [[ -n "${MCU_REAL}" && -e "${MCU_REAL}" ]]; then
  SERIAL_SHORT="$(udevadm info --query=property --name="${MCU_REAL}" 2>/dev/null | sed -n 's/^ID_SERIAL_SHORT=//p' | head -n1)"
fi
[[ -n "${SERIAL_SHORT}" ]] || SERIAL_SHORT="$(basename "${MCU_PATH}" | sed -n 's/^usb-.*_\([^_]*\)-if[0-9][0-9]*$/\1/p')"
[[ -n "${SERIAL_SHORT}" ]] || die "Could not determine ID_SERIAL_SHORT. Connect the SKR and run this installer again."

sudo -v
sudo install -d -m 0755 /usr/local/lib/hdr-performance /etc/systemd/system/klipper.service.d

for target in \
  /usr/local/lib/hdr-performance/wait-for-printer-mcu \
  /usr/local/lib/hdr-performance/recover-printer-mcu \
  /etc/systemd/system/klipper.service.d/20-hdr-skr-usb-wait.conf \
  /etc/systemd/system/hdr-skr-usb-reconnect.service \
  /etc/udev/rules.d/99-hdr-skr-usb-reconnect.rules; do
  if sudo test -e "${target}"; then
    sudo cp -a "${target}" "${target}.hdr-backup-${STAMP}"
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT

cat >"${tmp_dir}/wait-for-printer-mcu" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
for _ in \$(seq 1 ${WAIT_SECONDS}); do
  [[ -e "${MCU_PATH}" ]] && exit 0
  sleep 1
done
echo "HDR: SKR MCU did not appear at ${MCU_PATH} within ${WAIT_SECONDS} seconds" >&2
exit 1
EOF

cat >"${tmp_dir}/recover-printer-mcu" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
systemctl restart klipper.service
EOF

cat >"${tmp_dir}/20-hdr-skr-usb-wait.conf" <<'EOF'
[Unit]
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
ExecStartPre=/usr/local/lib/hdr-performance/wait-for-printer-mcu
Restart=always
RestartSec=5
EOF

cat >"${tmp_dir}/hdr-skr-usb-reconnect.service" <<'EOF'
[Unit]
Description=Restart Klipper when the HDR SKR printer MCU reconnects

[Service]
Type=oneshot
ExecStart=/usr/local/lib/hdr-performance/recover-printer-mcu
EOF

cat >"${tmp_dir}/99-hdr-skr-usb-reconnect.rules" <<EOF
ACTION=="add", SUBSYSTEM=="tty", ENV{ID_SERIAL_SHORT}=="${SERIAL_SHORT}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="hdr-skr-usb-reconnect.service"
EOF

sudo install -m 0755 "${tmp_dir}/wait-for-printer-mcu" /usr/local/lib/hdr-performance/wait-for-printer-mcu
sudo install -m 0755 "${tmp_dir}/recover-printer-mcu" /usr/local/lib/hdr-performance/recover-printer-mcu
sudo install -m 0644 "${tmp_dir}/20-hdr-skr-usb-wait.conf" /etc/systemd/system/klipper.service.d/20-hdr-skr-usb-wait.conf
sudo install -m 0644 "${tmp_dir}/hdr-skr-usb-reconnect.service" /etc/systemd/system/hdr-skr-usb-reconnect.service
sudo install -m 0644 "${tmp_dir}/99-hdr-skr-usb-reconnect.rules" /etc/udev/rules.d/99-hdr-skr-usb-reconnect.rules

sudo udevadm control --reload-rules
sudo systemctl daemon-reload

printf 'Installed HDR SKR USB recovery for:\n  %s\n' "${MCU_PATH}"
printf 'Klipper will wait up to %s seconds at boot and restart after this MCU reconnects.\n' "${WAIT_SECONDS}"
printf 'Reboot once when convenient, or run: sudo systemctl restart klipper\n'
