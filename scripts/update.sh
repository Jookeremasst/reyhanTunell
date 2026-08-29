#!/usr/bin/env bash
set -euo pipefail

APP_NAME="reyhanTunell"
REPO="https://github.com/Jookeremasst/reyhanTunell.git"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="${INSTALL_DIR}/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
STATE_FILE="${CONFIG_DIR}/install.env"
API_SERVICE="${APP_NAME}.service"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: update must be run as root. Use: sudo ${APP_NAME} update"
  exit 1
fi

[[ -x "${BINARY_PATH}" ]] || { echo "Error: installed ${APP_NAME} binary was not found."; exit 1; }
[[ -f "${STATE_FILE}" ]] || { echo "Error: installation state was not found. Run the installer once."; exit 1; }
source "${STATE_FILE}"

for cmd in git curl tar go rsync systemctl; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "Error: ${cmd} is required."; exit 1; }
done

current_version="$("${BINARY_PATH}" version | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p' | head -n1)"
current_version="${current_version:-0.0.0}"
installed_commit="${INSTALL_COMMIT:-}"
remote_commit="$(git ls-remote "${REPO}" HEAD 2>/dev/null | awk '{print $1}')"
[[ -n "${remote_commit}" ]] || { echo "Error: could not read the latest GitHub commit."; exit 1; }

echo "Installed version: v${current_version}"
echo "GitHub commit:    ${remote_commit:0:12}"

latest_tag="$(git ls-remote --tags --refs "${REPO}" 2>/dev/null | awk -F/ '$3 ~ /^v?[0-9]+\.[0-9]+\.[0-9]+$/ {print $3}' | sed 's/^v//' | sort -V | tail -n1)"
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

tar -czf "${BACKUP_FILE}" -C / "etc/${APP_NAME}" "var/lib/${APP_NAME}" "var/log/${APP_NAME}" 2>/dev/null || true
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

cd "${SOURCE_DIR}"
NEW_BINARY="${TMP_DIR}/${APP_NAME}.new"
echo "Building new ${APP_NAME} binary..."
go build -trimpath -ldflags "-s -w" -o "${NEW_BINARY}" .
"${NEW_BINARY}" version

# Replace only the application binary and updater. Tunnel configuration is untouched.
install -m 0755 "${NEW_BINARY}" "${BINARY_PATH}.new"
mv -f "${BINARY_PATH}.new" "${BINARY_PATH}"
install -m 0755 "${SOURCE_DIR}/scripts/update.sh" "/usr/local/lib/${APP_NAME}/update.sh"

# Restart only the core API. Individual tunnel services are not restarted.
systemctl daemon-reload
systemctl restart "${API_SERVICE}"
if ! systemctl is-active --quiet "${API_SERVICE}"; then
  echo "Error: ${APP_NAME} service failed after update."
  systemctl --no-pager --full status "${API_SERVICE}" || true
  exit 1
fi

cat > "${STATE_FILE}.tmp" <<EOF
INSTALL_API_ADDRESS=${INSTALL_API_ADDRESS:-127.0.0.1:8765}
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
echo "Core application updated."
echo "Tunnel configurations and tunnel services were not changed."
echo "Backup: ${BACKUP_FILE}"
