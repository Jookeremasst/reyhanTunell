#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
TUNNEL_DIR="${CONFIG_DIR}/tunnels"
LOG_DIR="/var/log/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: installer must be run as root."
    echo "Use: sudo ./install.sh"
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is not installed."
    echo "Install Go and run this installer again."
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/go.mod" ]]; then
    echo "Error: go.mod was not found."
    echo "Run this installer from a reyhanTunell source tree."
    exit 1
fi

echo "Installing ${APP_NAME}..."
echo "Source: ${SCRIPT_DIR}"

echo "Building ${APP_NAME}..."
cd "${SCRIPT_DIR}"
go build -trimpath -ldflags "-s -w" -o "${BINARY_PATH}" .

chmod 0755 "${BINARY_PATH}"

mkdir -p "${TUNNEL_DIR}" "${DATA_DIR}" "${LOG_DIR}"
chmod 0700 "${CONFIG_DIR}" "${TUNNEL_DIR}"
chmod 0755 "${DATA_DIR}" "${LOG_DIR}"

# Keep existing tunnel configuration. The installer only creates missing paths.

action="installed"
if [[ -x "${BINARY_PATH}" ]]; then
    echo
    echo "${APP_NAME} ${action} successfully."
    echo "Binary: ${BINARY_PATH}"
    echo "Config: ${CONFIG_DIR}"
    echo
    echo "You can now run from any directory:"
    echo "  sudo ${APP_NAME}"
    echo
    "${BINARY_PATH}" version
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi
