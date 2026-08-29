#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
BINARY_PATH="/usr/local/bin/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"
DASHBOARD_SESSION="${APP_NAME}-web"
PURGE=false

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: uninstaller must be run as root."
  echo "Use: sudo bash ./uninstall.sh"
  exit 1
fi

if [[ "${1:-}" == "--purge" ]]; then PURGE=true
elif [[ "${1:-}" != "" ]]; then echo "Usage: sudo bash ./uninstall.sh [--purge]"; exit 1; fi

if command -v tmux >/dev/null 2>&1 && tmux has-session -t "${DASHBOARD_SESSION}" 2>/dev/null; then
  tmux kill-session -t "${DASHBOARD_SESSION}" || true
fi

shopt -s nullglob
services=("/etc/systemd/system/${APP_NAME}-"*.service)
for service in "${services[@]}"; do
  name="$(basename "${service}")"
  systemctl disable --now "${name}" 2>/dev/null || true
  rm -f "${service}"
done

systemctl daemon-reload 2>/dev/null || true
rm -f "${BINARY_PATH}"

if [[ "${PURGE}" == true ]]; then
  rm -rf "${CONFIG_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  echo "${APP_NAME}, services, configuration, data and logs were removed."
else
  echo "${APP_NAME} binary, services and Web Dashboard session were removed."
  echo "Configuration, data and logs were kept. Use --purge to remove them too."
fi
