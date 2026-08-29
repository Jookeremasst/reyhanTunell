#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="__DASHBOARD_SESSION__"
DASHBOARD_DIR="__DASHBOARD_DIR__"
DASHBOARD_USER="__INSTALL_USER__"
DASHBOARD_PORT="__DASHBOARD_PORT__"

if ! id "$DASHBOARD_USER" >/dev/null 2>&1; then
  echo "Dashboard user does not exist: $DASHBOARD_USER"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  if [[ "${EUID}" -eq 0 ]]; then
    runuser -u "$DASHBOARD_USER" -- tmux kill-session -t "$SESSION_NAME" || true
  else
    tmux kill-session -t "$SESSION_NAME" || true
  fi
fi

if [[ "${EUID}" -eq 0 ]]; then
  runuser -u "$DASHBOARD_USER" -- tmux new-session -d -s "$SESSION_NAME" "cd '$DASHBOARD_DIR' && exec php artisan serve --host=0.0.0.0 --port=$DASHBOARD_PORT"
else
  tmux new-session -d -s "$SESSION_NAME" "cd '$DASHBOARD_DIR' && exec php artisan serve --host=0.0.0.0 --port=$DASHBOARD_PORT"
fi

echo "Web Dashboard restarted on port $DASHBOARD_PORT."
