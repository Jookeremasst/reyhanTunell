#!/usr/bin/env bash
set -euo pipefail

# This helper is intentionally small. The installer/update command owns the
# marker location and writes the commit only after a successful installation.
# It can be used by future installer revisions without touching tunnel state.

MARKER="${1:-/etc/reyhanTunell/installed_commit}"
COMMIT="${2:-}"

if [[ -z "$COMMIT" ]]; then
    echo "Usage: $0 <marker> <commit>" >&2
    exit 1
fi

install -d -m 0755 "$(dirname "$MARKER")"
printf '%s\n' "$COMMIT" > "$MARKER"
chmod 0644 "$MARKER"
