#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
REPO="https://github.com/Jookeremasst/reyhanTunell.git"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
DASHBOARD_DIR="${DASHBOARD_DIR:-/opt/${APP_NAME}/web/dashboard}"
STATE_FILE="${CONFIG_DIR}/install.env"

if [[ "${EUID}" -ne 0 ]]; then echo "Error: update must be run as root. Use: sudo reyhanTunell update"; exit 1; fi
[[ -x "${BINARY_PATH}" ]] || { echo "Error: installed reyhanTunell binary was not found."; exit 1; }
[[ -f "${STATE_FILE}" ]] || { echo "Error: installation state was not found at ${STATE_FILE}."; exit 1; }
source "${STATE_FILE}"
DASHBOARD_DIR="${INSTALL_DASHBOARD_DIR:-${DASHBOARD_DIR}}"
WEB_DASHBOARD_PORT="${INSTALL_WEB_DASHBOARD_PORT:-8000}"
DASHBOARD_SESSION="${INSTALL_DASHBOARD_SESSION:-${APP_NAME}-web}"

command -v git >/dev/null 2>&1 || { echo "Error: git is required."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required."; exit 1; }
command -v go >/dev/null 2>&1 || { echo "Error: Go is required."; exit 1; }

current_version="$("${BINARY_PATH}" version | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p' | head -n1)"
current_version="${current_version:-0.0.0}"
installed_commit="${INSTALL_COMMIT:-}"
remote_commit="$(git ls-remote "${REPO}" HEAD 2>/dev/null | awk '{print $1}')"
[[ -n "${remote_commit}" ]] || { echo "Error: could not read the latest GitHub commit."; exit 1; }

echo "Installed version: v${current_version}"
echo "GitHub commit:    ${remote_commit:0:12}"

# Releases use semantic tags when available. Normal main-branch commits are also
# updateable, so UI/code changes do not need a version bump for detection.
latest_tag="$(git ls-remote --tags --refs "${REPO}" 2>/dev/null | awk -F/ '$3 ~ /^v?[0-9]+\\.[0-9]+\\.[0-9]+$/ {print $3}' | sed 's/^v//' | sort -V | tail -n1)"
if [[ -n "${latest_tag}" ]]; then echo "Latest release:   v${latest_tag}"; fi

if [[ -n "${installed_commit}" && "${installed_commit}" == "${remote_commit}" ]]; then
  echo "Already up to date."; exit 0
fi
if [[ -z "${installed_commit}" ]]; then
  echo "No installed commit marker found. Run the installer once to enable safe commit-based updates."; exit 0
fi

TMP_DIR="$(mktemp -d /tmp/${APP_NAME}-update.XXXXXX)"
BACKUP_DIR="/var/backups/${APP_NAME}"
BACKUP_FILE="${BACKUP_DIR}/${APP_NAME}-${current_version}-$(date +%Y%m%d-%H%M%S).tar.gz"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT
mkdir -p "${BACKUP_DIR}"

echo "Update available. Downloading GitHub main..."
curl -fsSL "https://github.com/Jookeremasst/reyhanTunell/archive/refs/heads/main.tar.gz" -o "${TMP_DIR}/source.tar.gz"
tar -xzf "${TMP_DIR}/source.tar.gz" -C "${TMP_DIR}"
SOURCE_DIR="$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -name '${APP_NAME}-*' | head -n1)"
[[ -n "${SOURCE_DIR}" && -f "${SOURCE_DIR}/go.mod" ]] || { echo "Error: invalid update archive."; exit 1; }

tar -czf "${BACKUP_FILE}" -C / "etc/${APP_NAME}" "var/lib/${APP_NAME}" "var/log/${APP_NAME}" 2>/dev/null || true
chmod 0600 "${BACKUP_FILE}"

NEW_BINARY="${TMP_DIR}/${APP_NAME}.new"
echo "Building new binary..."
cd "${SOURCE_DIR}"
go build -trimpath -ldflags "-s -w" -o "${NEW_BINARY}" .
"${NEW_BINARY}" version

if [[ -d "${SOURCE_DIR}/web/dashboard" && -f "${SOURCE_DIR}/web/dashboard/composer.json" ]]; then
  echo "Preparing Web Dashboard update..."
  LIVE_ENV="${DASHBOARD_DIR}/.env"
  [[ -f "${LIVE_ENV}" ]] && cp "${LIVE_ENV}" "${SOURCE_DIR}/web/dashboard/.env"
  mkdir -p "${SOURCE_DIR}/web/dashboard/bootstrap/cache" "${SOURCE_DIR}/web/dashboard/storage/framework/cache" "${SOURCE_DIR}/web/dashboard/storage/framework/sessions" "${SOURCE_DIR}/web/dashboard/storage/framework/views" "${SOURCE_DIR}/web/dashboard/storage/logs"
  cd "${SOURCE_DIR}/web/dashboard"
  composer install --no-dev --optimize-autoloader --no-interaction
  php artisan migrate --force --no-interaction
  if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then npm install --no-audit --no-fund; npm run build; fi
fi

echo "Installing new binary atomically..."
install -m 0755 "${NEW_BINARY}" "${BINARY_PATH}.new"
mv -f "${BINARY_PATH}.new" "${BINARY_PATH}"

if [[ -d "${SOURCE_DIR}/web/dashboard" && -d "${DASHBOARD_DIR}" ]]; then
  rsync -a --delete --exclude '.env' --exclude 'storage/' --exclude 'database/*.sqlite' "${SOURCE_DIR}/web/dashboard/" "${DASHBOARD_DIR}/"
  chown -R "${INSTALL_USER:-root}:${INSTALL_USER:-root}" "${DASHBOARD_DIR}" 2>/dev/null || true
  chmod -R ug+rwX "${DASHBOARD_DIR}/bootstrap/cache" "${DASHBOARD_DIR}/storage" "${DASHBOARD_DIR}/database" 2>/dev/null || true
fi

[[ -x /usr/local/bin/reyhanTunell-web-restart ]] && /usr/local/bin/reyhanTunell-web-restart

cat > "${STATE_FILE}.tmp" <<EOF
INSTALL_USER=${INSTALL_USER:-root}
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
echo "Tunnel configurations were preserved."
echo "Backup: ${BACKUP_FILE}"
