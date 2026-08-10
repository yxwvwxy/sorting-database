#!/usr/bin/env bash
# Local scrape entrypoint (macOS / Linux). Mirrors scripts/run_scrape.bat.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -x "$ROOT/.venv/bin/python" ]]; then
  echo "Missing .venv. Create it and install deps before scheduling." >&2
  exit 1
fi

mkdir -p "$ROOT/logs"
DAY="$(date +%Y%m%d)"
LOG="$ROOT/logs/scrape-${DAY}.log"
LOCK="$ROOT/logs/scrape.lock"

if [[ -f "$LOCK" ]]; then
  old_pid="$(awk 'NR==1 {print $1}' "$LOCK" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skip: previous scrape still running (pid $old_pid)" >>"$LOG"
    exit 0
  fi
  rm -f "$LOCK"
fi

echo "$$ $(date '+%Y-%m-%d %H:%M:%S')" >"$LOCK"
cleanup() { rm -f "$LOCK"; }
trap cleanup EXIT

{
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') start ====="
  set +e
  code=1
  for attempt in 1 2; do
    if [[ "$attempt" -gt 1 ]]; then
      echo "Whole-run retry ${attempt}/2 after failure (fresh browser in 25s)..."
      sleep 25
    fi
    "$ROOT/.venv/bin/python" -m src.main "$@"
    code=$?
    if [[ "$code" -eq 0 ]]; then
      break
    fi
    echo "Run attempt ${attempt}/2 failed (exit ${code})."
  done
  set -e
  echo "===== $(date '+%Y-%m-%d %H:%M:%S %Z') done (exit ${code}) ====="
  exit "$code"
} >>"$LOG" 2>&1
