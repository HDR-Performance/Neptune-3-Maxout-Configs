#!/usr/bin/env python3
"""HDR persistent Klipper speed-profile service.

Registers a narrow Klipper remote method, atomically updates only the managed
[printer] motion ceilings, verifies a timestamped backup, and restarts Klipper.
"""

import hashlib
import json
import os
import re
import shutil
import socket
import subprocess
import time
from pathlib import Path

CONFIG_DIR = Path(os.environ.get("HDR_CONFIG_DIR", "/home/biqu/printer_data/config"))
PRINTER_CFG = CONFIG_DIR / "printer.cfg"
IDENTITY = CONFIG_DIR / ".hdr-performance-install"
SOCKET = Path(os.environ.get("HDR_KLIPPY_SOCKET", "/home/biqu/printer_data/comms/klippy.sock"))
BEGIN = "# HDR_SPEED_LIMITS_BEGIN"
END = "# HDR_SPEED_LIMITS_END"

PROFILES = {
    "neptune3-robin": {"NORMAL": (500, 3000, 5), "FAST": (600, 4000, 6), "LUDICROUS": (700, 5000, 8)},
    "neptune3pro-robin": {"NORMAL": (500, 3000, 5), "FAST": (600, 4000, 6), "LUDICROUS": (700, 5000, 8)},
    "neptune3plus-robin": {"NORMAL": (500, 3000, 5), "FAST": (600, 4000, 6), "LUDICROUS": (700, 5000, 8)},
    "neptune3max-robin": {"NORMAL": (800, 2500, 5), "FAST": (900, 4000, 7), "LUDICROUS": (1000, 5000, 10)},
    "neptune3-skr3ez": {"NORMAL": (500, 5000, 5), "FAST": (750, 7500, 7), "LUDICROUS": (900, 10000, 10)},
    "neptune3pro-skr3ez": {"NORMAL": (500, 5000, 5), "FAST": (750, 7500, 7), "LUDICROUS": (900, 10000, 10)},
    "neptune3plus-skr3ez": {"NORMAL": (500, 5000, 5), "FAST": (750, 7500, 7), "LUDICROUS": (900, 10000, 10)},
    "neptune3max-skr3ez": {"NORMAL": (800, 5000, 5), "FAST": (900, 7500, 7), "LUDICROUS": (1000, 10000, 10)},
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_id():
    if not IDENTITY.is_file():
        raise RuntimeError("HDR package identity is missing")
    for line in IDENTITY.read_text(encoding="utf-8").splitlines():
        if line.startswith("package_id="):
            return line.split("=", 1)[1].strip()
    raise RuntimeError("package_id is missing from HDR package identity")


def replace_one(block, key, value):
    pattern = re.compile(rf"(?m)^(\s*{re.escape(key)}\s*:\s*)[^#\r\n]+(\s*(?:#.*)?)$")
    updated, count = pattern.subn(rf"\g<1>{value}\g<2>", block)
    if count != 1:
        raise RuntimeError(f"managed block must contain exactly one {key}, found {count}")
    return updated


def apply_profile(profile):
    profile = str(profile).upper()
    package = package_id()
    if package not in PROFILES or profile not in PROFILES[package]:
        raise RuntimeError(f"unsupported package/profile: {package}/{profile}")
    original = PRINTER_CFG.read_text(encoding="utf-8")
    if original.count(BEGIN) != 1 or original.count(END) != 1:
        raise RuntimeError("printer.cfg does not contain one verified HDR speed block")
    start = original.index(BEGIN)
    stop = original.index(END, start) + len(END)
    block = original[start:stop]
    velocity, accel, scv = PROFILES[package][profile]
    block = replace_one(block, "max_velocity", velocity)
    block = replace_one(block, "max_accel", accel)
    block = replace_one(block, "square_corner_velocity", scv)
    updated = original[:start] + block + original[stop:]
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup_dir = CONFIG_DIR.parent / "config_backups" / f"{stamp}-{package}-before-speed-{profile.lower()}"
    backup_dir.mkdir(parents=True, exist_ok=False)
    backup = backup_dir / "printer.cfg"
    shutil.copy2(PRINTER_CFG, backup)
    if digest(backup) != digest(PRINTER_CFG):
        raise RuntimeError("printer.cfg backup verification failed")

    temporary = PRINTER_CFG.with_name(".printer.cfg.hdr-speed.tmp")
    temporary.write_text(updated, encoding="utf-8")
    if temporary.read_text(encoding="utf-8") != updated:
        temporary.unlink(missing_ok=True)
        raise RuntimeError("temporary printer.cfg verification failed")
    os.replace(temporary, PRINTER_CFG)
    (CONFIG_DIR / ".hdr-speed-profile").write_text(
        f"package_id={package}\nprofile={profile}\nvelocity={velocity}\naccel={accel}\nsquare_corner_velocity={scv}\nbackup={backup}\n",
        encoding="utf-8",
    )
    subprocess.run(["systemctl", "restart", "klipper"], check=True)


def serve():
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                client.connect(str(SOCKET))
                request = {"id": 1, "method": "register_remote_method", "params": {
                    "remote_method": "hdr_set_speed_profile",
                    "response_template": {"action": "hdr_set_speed_profile"},
                }}
                client.sendall(json.dumps(request).encode() + b"\x03")
                pending = b""
                while True:
                    chunk = client.recv(4096)
                    if not chunk:
                        break
                    pending += chunk
                    while b"\x03" in pending:
                        raw, pending = pending.split(b"\x03", 1)
                        if not raw:
                            continue
                        message = json.loads(raw.decode())
                        if message.get("action") == "hdr_set_speed_profile":
                            apply_profile(message.get("params", {}).get("profile", ""))
        except Exception as exc:
            print(f"HDR speed profile service: {exc}", flush=True)
            time.sleep(3)


if __name__ == "__main__":
    serve()
