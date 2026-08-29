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
DASHBOARD_DIR="${SCRIPT_DIR}/web/dashboard"
DASHBOARD_SESSION="${APP_NAME}-web"
WEB_DASHBOARD_PORT=8000

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: installer must be run as root."
  echo "Use: sudo ./install.sh"
  exit 1
fi

if [[ ! -f "${SCRIPT_DIR}/go.mod" ]]; then
  echo "Error: go.mod was not found."
  exit 1
fi

if [[ ! -f "${DASHBOARD_DIR}/composer.json" ]]; then
  echo "Error: Web Dashboard files were not found at ${DASHBOARD_DIR}."
  exit 1
fi

is_valid_port() { [[ "${1}" =~ ^[0-9]+$ ]] && (( ${1} >= 1024 && ${1} <= 65535 )); }
is_port_in_use() {
  ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq ":${1}$|:${1}[[:space:]]"
}

if ! command -v go >/dev/null 2>&1; then
  echo "Error: Go is not installed. Install Go and run this installer again."
  exit 1
fi

INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
if ! id "${INSTALL_USER}" >/dev/null 2>&1; then INSTALL_USER=root; fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Installing required packages..."
  apt-get update
  apt-get install -y php-cli php-common php-mbstring php-xml php-curl php-zip php-bcmath php-intl php-mysql php-sqlite3 unzip tmux nodejs npm composer
fi

printf '\nWeb Dashboard setup\n'
printf 'The web dashboard needs a TCP port.\n'
printf 'Default port: 8000\n\n'
while true; do
  read -r -p "Web Dashboard Port [8000]: " requested_port
  requested_port="${requested_port:-8000}"
  if ! is_valid_port "${requested_port}"; then
    echo "Error: enter a port number from 1024 to 65535."
    continue
  fi
  if is_port_in_use "${requested_port}"; then
    echo "Port ${requested_port} is already in use."
    continue
  fi
  WEB_DASHBOARD_PORT="${requested_port}"
  break
done

# Prepare Laravel directories before Composer runs.
mkdir -p "${DASHBOARD_DIR}/bootstrap/cache" \
         "${DASHBOARD_DIR}/storage/framework/cache" \
         "${DASHBOARD_DIR}/storage/framework/sessions" \
         "${DASHBOARD_DIR}/storage/framework/views" \
         "${DASHBOARD_DIR}/storage/logs" \
         "${DASHBOARD_DIR}/database"
chown -R "${INSTALL_USER}:${INSTALL_USER}" "${DASHBOARD_DIR}"
chmod -R ug+rwX "${DASHBOARD_DIR}/bootstrap/cache" "${DASHBOARD_DIR}/storage"

cd "${DASHBOARD_DIR}"
if [[ ! -f .env ]]; then cp .env.example .env; fi
sed -i "s/^REYHAN_WEB_PORT=.*/REYHAN_WEB_PORT=${WEB_DASHBOARD_PORT}/" .env || true
if ! grep -q '^REYHAN_WEB_PORT=' .env; then echo "REYHAN_WEB_PORT=${WEB_DASHBOARD_PORT}" >> .env; fi

run_as_user() { if [[ "${INSTALL_USER}" == root ]]; then "$@"; else runuser -u "${INSTALL_USER}" -- "$@"; fi; }

if [[ ! -f vendor/autoload.php ]]; then
  run_as_user composer install --no-dev --optimize-autoloader --no-interaction
else
  run_as_user composer install --no-dev --optimize-autoloader --no-interaction
fi

if ! grep -q '^APP_KEY=base64:' .env; then
  run_as_user php artisan key:generate --force --no-interaction
fi

if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
  run_as_user npm install --no-audit --no-fund
  run_as_user npm run build
fi

# Stop an old development dashboard session before starting the new one.
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "${DASHBOARD_SESSION}" 2>/dev/null; then
  tmux kill-session -t "${DASHBOARD_SESSION}" || true
fi

run_as_user tmux new-session -d -s "${DASHBOARD_SESSION}" "cd '${DASHBOARD_DIR}' && exec php artisan serve --host=0.0.0.0 --port=${WEB_DASHBOARD_PORT}"

cd "${SCRIPT_DIR}"
echo "Installing ${APP_NAME}..."
go build -trimpath -ldflags "-s -w" -o "${BINARY_PATH}" .
chmod 0755 "${BINARY_PATH}"
mkdir -p "${TUNNEL_DIR}" "${DATA_DIR}" "${LOG_DIR}"
chmod 0700 "${CONFIG_DIR}" "${TUNNEL_DIR}"
chmod 0755 "${DATA_DIR}" "${LOG_DIR}"

if command -v systemctl >/dev/null 2>&1; then systemctl daemon-reload; fi

echo
echo "${APP_NAME} installed successfully."
echo "Binary: ${BINARY_PATH}"
echo "Web Dashboard: http://0.0.0.0:${WEB_DASHBOARD_PORT}"
echo "Dashboard tmux session: ${DASHBOARD_SESSION}"
echo
echo "Attach with: tmux attach -t ${DASHBOARD_SESSION}"
"${BINARY_PATH}" version
