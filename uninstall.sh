#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
BINARY_PATH="/usr/local/bin/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
PURGE=false

if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: uninstaller must be run as root."
    echo "Use: sudo bash ./uninstall.sh"
    exit 1
fi

if [[ "${1:-}" == "--purge" ]]; then
    PURGE=true
elif [[ "${1:-}" != "" ]]; then
    echo "Usage: sudo bash ./uninstall.sh [--purge]"
    exit 1
fi

shopt -s nullglob
services=("/etc/systemd/system/${APP_NAME}-"*.service)
for service in "${services[@]}"; do
    name="$(basename "${service}")"
    systemctl disable --now "${name}" 2>/dev/null || true
    rm -f "${service}"
done

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi

rm -f "${BINARY_PATH}"

if [[ "${PURGE}" == true ]]; then
    rm -rf "${CONFIG_DIR}" "${DATA_DIR}" "${LOG_DIR}"
    echo "${APP_NAME} and all local configuration/data/log files were removed."
else
    echo "${APP_NAME} binary and systemd services were removed."
    echo "Configuration, data, and logs were kept."
    echo "Use --purge only if you also want to remove them."
fi
