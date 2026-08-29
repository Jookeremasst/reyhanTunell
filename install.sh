#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
TUNNEL_DIR="${CONFIG_DIR}/tunnels"
LOG_DIR="/var/log/${APP_NAME}"
DATA_DIR="/var/lib/${APP_NAME}"
WEB_DASHBOARD_PORT="8000"
WEB_SERVICE_NAME="${APP_NAME}-web.service"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: installer must be run as root."
    echo "Use: sudo ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/go.mod" ]]; then
    echo "Error: go.mod was not found."
    echo "Run this installer from a reyhanTunell source tree."
    exit 1
fi

is_valid_port() {
    [[ "${1}" =~ ^[0-9]+$ ]] && (( ${1} >= 1024 && ${1} <= 65535 ))
}

is_port_in_use() {
    if command -v ss >/dev/null 2>&1; then
        ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq ":${1}$|:${1}[[:space:]]"
    else
        return 1
    fi
}

if [[ -f "${SCRIPT_DIR}/composer.json" ]]; then
    echo
    echo "Web Dashboard setup"
    echo "The web dashboard needs a TCP port."
    echo "Default port: 8000"

    while true; do
        read -r -p "Web Dashboard Port [8000]: " requested_port
        requested_port="${requested_port:-8000}"

        if ! is_valid_port "${requested_port}"; then
            echo "Error: enter a port number from 1024 to 65535."
            continue
        fi

        if is_port_in_use "${requested_port}"; then
            echo "Port ${requested_port} is already in use."
            echo "Please choose another port."
            continue
        fi

        WEB_DASHBOARD_PORT="${requested_port}"
        break
    done

    echo "Web Dashboard port: ${WEB_DASHBOARD_PORT}"
fi

echo "Installing ${APP_NAME}..."
echo "Source: ${SCRIPT_DIR}"

if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is not installed."
    echo "Install Go and run this installer again."
    exit 1
fi

if command -v apt-get >/dev/null 2>&1 && [[ -f "${SCRIPT_DIR}/composer.json" ]]; then
    echo "Installing PHP and required PHP extensions..."
    apt-get update
    apt-get install -y \
        php-cli php-common php-mbstring php-xml php-curl php-zip \
        php-bcmath php-intl php-mysql php-sqlite3 unzip

    if ! command -v composer >/dev/null 2>&1; then
        echo "Installing Composer..."
        apt-get install -y composer
    fi
fi

if [[ -f "${SCRIPT_DIR}/composer.json" ]]; then
    echo "Installing PHP dependencies..."
    cd "${SCRIPT_DIR}"
    composer install --no-dev --optimize-autoloader

    if [[ ! -f ".env" ]]; then
        cp .env.example .env
    fi

    if ! grep -q '^APP_KEY=base64:' .env 2>/dev/null; then
        php artisan key:generate --force
    fi

    if [[ -d "storage" ]]; then
        chmod -R ug+rwX storage bootstrap/cache
    fi

    echo "Configuring Web Dashboard port..."
    if grep -q '^REYHAN_WEB_PORT=' .env; then
        sed -i "s/^REYHAN_WEB_PORT=.*/REYHAN_WEB_PORT=${WEB_DASHBOARD_PORT}/" .env
    else
        printf '\nREYHAN_WEB_PORT=%s\n' "${WEB_DASHBOARD_PORT}" >> .env
    fi
fi

echo "Building ${APP_NAME}..."
cd "${SCRIPT_DIR}"
go build -trimpath -ldflags "-s -w" -o "${BINARY_PATH}" .
chmod 0755 "${BINARY_PATH}"

mkdir -p "${TUNNEL_DIR}" "${DATA_DIR}" "${LOG_DIR}"
chmod 0700 "${CONFIG_DIR}" "${TUNNEL_DIR}"
chmod 0755 "${DATA_DIR}" "${LOG_DIR}"

if [[ -f "${SCRIPT_DIR}/composer.json" ]] && command -v systemctl >/dev/null 2>&1; then
    echo "Creating Web Dashboard service..."

    # The dashboard service runs the standard Laravel development server for now.
    # It is managed by systemd so it starts automatically after reboot.
    cat > "/etc/systemd/system/${WEB_SERVICE_NAME}" <<EOF
[Unit]
Description=reyhanTunell Web Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=${SCRIPT_DIR}
ExecStart=/usr/bin/php artisan serve --host=0.0.0.0 --port=${WEB_DASHBOARD_PORT}
Restart=on-failure
RestartSec=3
Environment=APP_ENV=production
Environment=APP_DEBUG=false

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "${WEB_SERVICE_NAME}"
    systemctl restart "${WEB_SERVICE_NAME}"

    sleep 1
    if systemctl is-active --quiet "${WEB_SERVICE_NAME}"; then
        echo "Web Dashboard service is running."
    else
        echo "Warning: Web Dashboard service did not start."
        echo "Check: systemctl status ${WEB_SERVICE_NAME}"
        echo "Logs: journalctl -u ${WEB_SERVICE_NAME} -n 50 --no-pager"
    fi
fi

if [[ -x "${BINARY_PATH}" ]]; then
    echo
echo "${APP_NAME} installed successfully."
    echo "Binary: ${BINARY_PATH}"
    echo "Config: ${CONFIG_DIR}"
    if [[ -f "${SCRIPT_DIR}/composer.json" ]]; then
        echo "Web Dashboard: http://0.0.0.0:${WEB_DASHBOARD_PORT}"
        echo "Web Dashboard service: ${WEB_SERVICE_NAME}"
    fi
    echo
echo "You can now run from any directory:"
    echo "  sudo ${APP_NAME}"
    echo
    "${BINARY_PATH}" version
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi
