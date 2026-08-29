#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
TUNNEL_DIR="${CONFIG_DIR}/tunnels"
LOG_DIR="/var/log/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"
API_ADDRESS="127.0.0.1:8765"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: installer must be run as root. Use: sudo ./install.sh"
  exit 1
fi
if [[ ! -f "${SCRIPT_DIR}/go.mod" ]]; then
  echo "Error: go.mod was not found."
  exit 1
fi
if ! command -v go >/dev/null 2>&1; then
  echo "Error: Go is not installed. Install Go and run this installer again."
  exit 1
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Installing required packages..."
  apt-get update
  apt-get install -y git curl rsync tmux
fi

mkdir -p "${TUNNEL_DIR}" "${DATA_DIR}" "${LOG_DIR}"
chmod 0700 "${CONFIG_DIR}" "${TUNNEL_DIR}"
chmod 0755 "${DATA_DIR}" "${LOG_DIR}"

cd "${SCRIPT_DIR}"
echo "Building ${APP_NAME}..."
go build -trimpath -ldflags "-s -w" -o "${BINARY_PATH}" .
chmod 0755 "${BINARY_PATH}"

mkdir -p "/usr/local/lib/${APP_NAME}"
install -m 0755 "${SCRIPT_DIR}/scripts/update.sh" "/usr/local/lib/${APP_NAME}/update.sh"

cat > "/etc/systemd/system/${APP_NAME}.service" <<EOF
[Unit]
Description=reyhanTunell Core API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${BINARY_PATH} api ${API_ADDRESS}
Restart=on-failure
RestartSec=2
User=root
Group=root
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=${CONFIG_DIR} ${DATA_DIR} ${LOG_DIR}

[Install]
WantedBy=multi-user.target
EOF

INSTALL_COMMIT=""
if command -v git >/dev/null 2>&1 && git -C "${SCRIPT_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
  INSTALL_COMMIT="$(git -C "${SCRIPT_DIR}" rev-parse HEAD)"
fi
if [[ -z "${INSTALL_COMMIT}" ]]; then
  INSTALL_COMMIT="$(git ls-remote https://github.com/Jookeremasst/reyhanTunell.git HEAD 2>/dev/null | awk '{print $1}')"
fi

INSTALL_VERSION="$("${BINARY_PATH}" version | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p' | head -n1)"
INSTALL_VERSION="${INSTALL_VERSION:-0.1.0}"

cat > "/etc/${APP_NAME}/install.env" <<EOF
INSTALL_API_ADDRESS=${API_ADDRESS}
INSTALL_VERSION=${INSTALL_VERSION}
INSTALL_COMMIT=${INSTALL_COMMIT}
EOF
chmod 0600 "/etc/${APP_NAME}/install.env"

systemctl daemon-reload
systemctl enable --now "${APP_NAME}.service"

if ! systemctl is-active --quiet "${APP_NAME}.service"; then
  echo "Error: ${APP_NAME} service failed to start."
  systemctl --no-pager --full status "${APP_NAME}.service" || true
  exit 1
fi

echo
echo "=============================================="
echo "       ${APP_NAME} installed successfully"
echo "=============================================="
printf '%-18s %s\n' "Version" "v${INSTALL_VERSION}"
printf '%-18s %s\n' "API" "${API_ADDRESS}"
printf '%-18s %s\n' "Service" "${APP_NAME}.service"
echo
echo "Tunnel configurations: ${TUNNEL_DIR}"
echo "Update: sudo ${APP_NAME} update"
echo "Menu:   sudo ${APP_NAME} menu"
echo
"${BINARY_PATH}" version
