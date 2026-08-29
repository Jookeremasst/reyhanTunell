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
WEB_BASE_PATH=""
WEB_USERNAME="admin"
WEB_PASSWORD="admin"

if [[ "${EUID}" -ne 0 ]]; then echo "Error: installer must be run as root. Use: sudo ./install.sh"; exit 1; fi
if [[ ! -f "${SCRIPT_DIR}/go.mod" ]]; then echo "Error: go.mod was not found."; exit 1; fi
if [[ ! -f "${DASHBOARD_DIR}/composer.json" ]]; then echo "Error: Web Dashboard files were not found at ${DASHBOARD_DIR}."; exit 1; fi

is_valid_port() { [[ "${1}" =~ ^[0-9]+$ ]] && (( ${1} >= 1024 && ${1} <= 65535 )); }
is_port_in_use() { ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq ":${1}$|:${1}[[:space:]]"; }
random_base_path() { tr -dc 'a-z0-9' </dev/urandom | head -c 15; echo; }

if ! command -v go >/dev/null 2>&1; then echo "Error: Go is not installed. Install Go and run this installer again."; exit 1; fi
INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
if ! id "${INSTALL_USER}" >/dev/null 2>&1; then INSTALL_USER=root; fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Installing required packages..."
  apt-get update
  apt-get install -y php-cli php-common php-mbstring php-xml php-curl php-zip php-bcmath php-intl php-mysql php-sqlite3 unzip tmux nodejs npm composer
fi

printf '\nWeb Dashboard setup\n'
printf 'Default Web Dashboard port: 8000\n\n'
while true; do
  read -r -p "Web Dashboard Port [8000]: " requested_port
  requested_port="${requested_port:-8000}"
  if ! is_valid_port "${requested_port}"; then echo "Error: enter a port number from 1024 to 65535."; continue; fi
  if is_port_in_use "${requested_port}"; then echo "Port ${requested_port} is already in use."; continue; fi
  WEB_DASHBOARD_PORT="${requested_port}"; break
done

read -r -p "Web Dashboard Username [admin]: " requested_username
WEB_USERNAME="${requested_username:-admin}"
if [[ ! "${WEB_USERNAME}" =~ ^[A-Za-z0-9_.-]{3,64}$ ]]; then echo "Error: invalid username."; exit 1; fi

while true; do
  read -r -s -p "Web Dashboard Password [admin]: " requested_password
  echo
  WEB_PASSWORD="${requested_password:-admin}"
  if [[ ${#WEB_PASSWORD} -lt 8 ]]; then echo "Error: password must be at least 8 characters."; continue; fi
  break
done

WEB_BASE_PATH="$(random_base_path)"
while [[ ${#WEB_BASE_PATH} -ne 15 ]]; do WEB_BASE_PATH="$(random_base_path)"; done

mkdir -p "${DASHBOARD_DIR}/bootstrap/cache" "${DASHBOARD_DIR}/storage/framework/cache" "${DASHBOARD_DIR}/storage/framework/sessions" "${DASHBOARD_DIR}/storage/framework/views" "${DASHBOARD_DIR}/storage/logs" "${DASHBOARD_DIR}/database"
chown -R "${INSTALL_USER}:${INSTALL_USER}" "${DASHBOARD_DIR}"
chmod -R ug+rwX "${DASHBOARD_DIR}/bootstrap/cache" "${DASHBOARD_DIR}/storage"

cd "${DASHBOARD_DIR}"
if [[ ! -f .env ]]; then cp .env.example .env; fi
set_env() { if grep -q "^${1}=" .env; then sed -i "s#^${1}=.*#${1}=${2}#" .env; else echo "${1}=${2}" >> .env; fi; }
set_env REYHAN_WEB_PORT "${WEB_DASHBOARD_PORT}"
set_env REYHAN_WEB_BASE_PATH "${WEB_BASE_PATH}"
set_env REYHAN_WEB_USERNAME "${WEB_USERNAME}"
set_env REYHAN_WEB_PASSWORD "${WEB_PASSWORD}"

run_as_user() { if [[ "${INSTALL_USER}" == root ]]; then "$@"; else runuser -u "${INSTALL_USER}" -- "$@"; fi; }
run_as_user composer install --no-dev --optimize-autoloader --no-interaction
if ! grep -q '^APP_KEY=base64:' .env; then run_as_user php artisan key:generate --force --no-interaction; fi
run_as_user php artisan migrate --force --no-interaction
run_as_user php artisan db:seed --force --no-interaction

if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
  run_as_user npm install --no-audit --no-fund
  run_as_user npm run build
fi

if tmux has-session -t "${DASHBOARD_SESSION}" 2>/dev/null; then tmux kill-session -t "${DASHBOARD_SESSION}" || true; fi
run_as_user tmux new-session -d -s "${DASHBOARD_SESSION}" "cd '${DASHBOARD_DIR}' && exec php artisan serve --host=0.0.0.0 --port=${WEB_DASHBOARD_PORT}"

cd "${SCRIPT_DIR}"
echo "Installing ${APP_NAME}..."
go build -trimpath -ldflags "-s -w" -o "${BINARY_PATH}" .
chmod 0755 "${BINARY_PATH}"
mkdir -p "${TUNNEL_DIR}" "${DATA_DIR}" "${LOG_DIR}"
chmod 0700 "${CONFIG_DIR}" "${TUNNEL_DIR}"
chmod 0755 "${DATA_DIR}" "${LOG_DIR}"

cat > /usr/local/bin/reyhanTunell-web-restart <<EOF
#!/usr/bin/env bash
set -e
SESSION="${DASHBOARD_SESSION}"
DIR="${DASHBOARD_DIR}"
PORT="${WEB_DASHBOARD_PORT}"
USER="${INSTALL_USER}"
if tmux has-session -t "\${SESSION}" 2>/dev/null; then tmux kill-session -t "\${SESSION}"; fi
if [[ "\${USER}" == root ]]; then tmux new-session -d -s "\${SESSION}" "cd '\${DIR}' && exec php artisan serve --host=0.0.0.0 --port=\${PORT}"; else runuser -u "\${USER}" -- tmux new-session -d -s "\${SESSION}" "cd '\${DIR}' && exec php artisan serve --host=0.0.0.0 --port=\${PORT}"; fi
echo "Web Dashboard restarted on port \${PORT}."
EOF
chmod 0755 /usr/local/bin/reyhanTunell-web-restart

if command -v systemctl >/dev/null 2>&1; then systemctl daemon-reload; fi

echo
echo "${APP_NAME} installed successfully."
echo "Version: $(${BINARY_PATH} version | tail -n 1)"
echo
echo "Web Dashboard Installation"
printf '%-20s %s\n' "Port" "${WEB_DASHBOARD_PORT}"
printf '%-20s %s\n' "Username" "${WEB_USERNAME}"
printf '%-20s %s\n' "Password" "${WEB_PASSWORD}"
printf '%-20s %s\n' "WebBasePath" "${WEB_BASE_PATH}"
printf '%-20s %s\n' "Dashboard URL" "http://127.0.0.1:${WEB_DASHBOARD_PORT}/${WEB_BASE_PATH}"
echo
echo "Restart command: reyhanTunell-web-restart"
echo "Attach: tmux attach -t ${DASHBOARD_SESSION}"
"${BINARY_PATH}" version
