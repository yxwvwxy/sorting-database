#!/usr/bin/env bash
# Keep Mac awake during the 21:30–22:30 initials poll window, then exit.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p "$ROOT/logs"

DAY="$(date +%Y%m%d)"
LOG="$ROOT/logs/mac-evening-initials-${DAY}.log"
LOCK="$ROOT/logs/mac-evening-initials.lock"

if [[ -f "$LOCK" ]]; then
  old_pid="$(awk 'NR==1 {print $1}' "$LOCK" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skip: initials poll already running (pid $old_pid)" >>"$LOG"
    exit 0
  fi
  rm -f "$LOCK"
fi

echo "$$ $(date '+%Y-%m-%d %H:%M:%S')" >"$LOCK"
cleanup() { rm -f "$LOCK"; }
trap cleanup EXIT

{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') mac evening initials start ====="
  # -i: idle sleep; -s: system sleep (AC). Covers ~70 min poll window.
  /usr/bin/caffeinate -i -s -t 4200 \
    "$ROOT/.venv/bin/python" "$ROOT/scripts/mac_evening_initials.py"
  code=$?
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') mac evening initials done (exit ${code}) ====="
  exit "$code"
} >>"$LOG" 2>&1
