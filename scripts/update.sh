#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
REPO="https://github.com/Jookeremasst/reyhanTunell.git"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
STATE_FILE="${CONFIG_DIR}/install.env"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: update must be run as root. Use: sudo reyhanTunell update"
  exit 1
fi

[[ -x "${BINARY_PATH}" ]] || { echo "Error: installed reyhanTunell binary was not found."; exit 1; }
[[ -f "${STATE_FILE}" ]] || { echo "Error: installation state was not found at ${STATE_FILE}. Run the installer once."; exit 1; }
source "${STATE_FILE}"

DASHBOARD_DIR="${INSTALL_DASHBOARD_DIR:-}"
WEB_DASHBOARD_PORT="${INSTALL_WEB_DASHBOARD_PORT:-8000}"
DASHBOARD_SESSION="${INSTALL_DASHBOARD_SESSION:-${APP_NAME}-web}"
INSTALL_USER="${INSTALL_USER:-root}"

[[ -n "${DASHBOARD_DIR}" ]] || { echo "Error: dashboard installation path is not recorded."; exit 1; }

for cmd in git curl tar go rsync php composer; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "Error: ${cmd} is required."; exit 1; }
done

current_version="$("${BINARY_PATH}" version | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p' | head -n1)"
current_version="${current_version:-0.0.0}"
installed_commit="${INSTALL_COMMIT:-}"
remote_commit="$(git ls-remote "${REPO}" HEAD 2>/dev/null | awk '{print $1}')"
[[ -n "${remote_commit}" ]] || { echo "Error: could not read the latest GitHub commit."; exit 1; }

echo "Installed version: v${current_version}"
echo "GitHub commit:    ${remote_commit:0:12}"

latest_tag="$(git ls-remote --tags --refs "${REPO}" 2>/dev/null | awk -F/ '$3 ~ /^v?[0-9]+\\.[0-9]+\\.[0-9]+$/ {print $3}' | sed 's/^v//' | sort -V | tail -n1)"
if [[ -n "${latest_tag}" ]]; then
  echo "Latest release:   v${latest_tag}"
  UPDATE_REF="v${latest_tag}"
else
  UPDATE_REF="main"
fi

if [[ -n "${installed_commit}" && "${installed_commit}" == "${remote_commit}" ]]; then
  echo "Already up to date."
  exit 0
fi

if [[ -z "${installed_commit}" ]]; then
  echo "No installed commit marker found. The installation will be migrated and updated."
else
  echo "Update available."
fi

TMP_DIR="$(mktemp -d /tmp/${APP_NAME}-update.XXXXXX)"
BACKUP_DIR="/var/backups/${APP_NAME}"
BACKUP_FILE="${BACKUP_DIR}/${APP_NAME}-${current_version}-$(date +%Y%m%d-%H%M%S).tar.gz"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT
mkdir -p "${BACKUP_DIR}"

# Keep all persistent tunnel data outside the application source tree.
# The update never replaces /etc/reyhanTunell/tunnels.
tar -czf "${BACKUP_FILE}" \
  -C / \
  "etc/${APP_NAME}" \
  "var/lib/${APP_NAME}" \
  "var/log/${APP_NAME}" \
  2>/dev/null || true
chmod 0600 "${BACKUP_FILE}"

ARCHIVE_URL="https://github.com/Jookeremasst/reyhanTunell/archive/refs/heads/main.tar.gz"
if [[ "${UPDATE_REF}" != "main" ]]; then
  ARCHIVE_URL="https://github.com/Jookeremasst/reyhanTunell/archive/refs/tags/${UPDATE_REF}.tar.gz"
fi

echo "Downloading project source: ${UPDATE_REF}..."
curl -fsSL "${ARCHIVE_URL}" -o "${TMP_DIR}/source.tar.gz"
tar -xzf "${TMP_DIR}/source.tar.gz" -C "${TMP_DIR}"
SOURCE_DIR="$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -name '${APP_NAME}-*' | head -n1)"
[[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/go.mod" ]] || { echo "Error: invalid update archive."; exit 1; }

# Preserve the live Laravel environment. It contains the generated APP_KEY,
# WebBasePath, dashboard credentials, selected port, and local database settings.
LIVE_ENV="${DASHBOARD_DIR}/.env"
if [[ -f "${LIVE_ENV}" ]]; then
  cp "${LIVE_ENV}" "${SOURCE_DIR}/web/dashboard/.env"
fi

# Preserve the local Laravel database. Migrations are applied to this database,
# but the database file itself is never replaced by source synchronization.
LIVE_SQLITE=""
if [[ -f "${DASHBOARD_DIR}/database/database.sqlite" ]]; then
  LIVE_SQLITE="${DASHBOARD_DIR}/database/database.sqlite"
  cp "${LIVE_SQLITE}" "${SOURCE_DIR}/web/dashboard/database/database.sqlite"
fi

# Prepare the complete Laravel application from the repository.
if [[ -f "${SOURCE_DIR}/web/dashboard/composer.json" ]]; then
  echo "Updating Web Dashboard dependencies..."
  cd "${SOURCE_DIR}/web/dashboard"
  mkdir -p bootstrap/cache storage/framework/cache storage/framework/sessions storage/framework/views storage/logs
  composer install --no-dev --optimize-autoloader --no-interaction
  php artisan migrate --force --no-interaction

  if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
    npm install --no-audit --no-fund
    npm run build
  fi
fi

# Build the new Go binary before changing the live installation.
cd "${SOURCE_DIR}"
NEW_BINARY="${TMP_DIR}/${APP_NAME}.new"
echo "Building new ${APP_NAME} binary..."
go build -trimpath -ldflags "-s -w" -o "${NEW_BINARY}" .
"${NEW_BINARY}" version

# Stop only the web dashboard. Tunnel services are not stopped or changed.
if tmux has-session -t "${DASHBOARD_SESSION}" 2>/dev/null; then
  tmux kill-session -t "${DASHBOARD_SESSION}" || true
fi

# Replace application source atomically where possible. Persistent runtime data
# remains excluded from synchronization.
echo "Installing updated Web Dashboard..."
mkdir -p "${DASHBOARD_DIR}"
rsync -a --delete \
  --exclude '.env' \
  --exclude 'vendor/' \
  --exclude 'node_modules/' \
  --exclude 'public/build/' \
  --exclude 'storage/' \
  --exclude 'database/*.sqlite' \
  "${SOURCE_DIR}/web/dashboard/" "${DASHBOARD_DIR}/"

# Install the freshly built dependencies after source synchronization.
cd "${DASHBOARD_DIR}"
composer install --no-dev --optimize-autoloader --no-interaction
if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
  npm install --no-audit --no-fund
  npm run build
fi
php artisan migrate --force --no-interaction

# Restore the live environment and local database explicitly.
if [[ -f "${LIVE_ENV}" ]]; then
  cp "${LIVE_ENV}" "${DASHBOARD_DIR}/.env"
fi
if [[ -n "${LIVE_SQLITE}" && -f "${LIVE_SQLITE}" ]]; then
  cp "${LIVE_SQLITE}" "${DASHBOARD_DIR}/database/database.sqlite"
fi

# Fix ownership after rsync. Do not touch /etc/reyhanTunell/tunnels.
if id "${INSTALL_USER}" >/dev/null 2>&1; then
  chown -R "${INSTALL_USER}:${INSTALL_USER}" "${DASHBOARD_DIR}"
fi
chmod -R ug+rwX "${DASHBOARD_DIR}/bootstrap/cache" "${DASHBOARD_DIR}/storage" "${DASHBOARD_DIR}/database" 2>/dev/null || true

# Install the new core binary only after the dashboard update is ready.
install -m 0755 "${NEW_BINARY}" "${BINARY_PATH}.new"
mv -f "${BINARY_PATH}.new" "${BINARY_PATH}"

# Restart only the dashboard. Existing tunnel processes and their configurations
# are left untouched.
if [[ -x /usr/local/bin/reyhanTunell-web-restart ]]; then
  /usr/local/bin/reyhanTunell-web-restart
fi

cat > "${STATE_FILE}.tmp" <<EOF
INSTALL_USER=${INSTALL_USER}
INSTALL_DASHBOARD_DIR=${DASHBOARD_DIR}
INSTALL_WEB_DASHBOARD_PORT=${WEB_DASHBOARD_PORT}
INSTALL_DASHBOARD_SESSION=${DASHBOARD_SESSION}
INSTALL_VERSION=$("${BINARY_PATH}" version | sed -n 's/.*v//p' | tail -n1)
INSTALL_COMMIT=${remote_commit}
EOF
chmod 0600 "${STATE_FILE}.tmp"
mv -f "${STATE_FILE}.tmp" "${STATE_FILE}"

echo
echo "Update completed successfully."
echo "Previous version: v${current_version}"
echo "Current version: $("${BINARY_PATH}" version | tail -n1)"
echo "Commit: ${remote_commit:0:12}"
echo "Web Dashboard updated from the same project source."
echo "Tunnel configurations were preserved."
echo "Backup: ${BACKUP_FILE}"
