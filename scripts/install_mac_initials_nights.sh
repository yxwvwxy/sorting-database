#!/usr/bin/env bash
# Schedule Mac city-initials capture for 2026-08-28 and 2026-08-29 at 21:30 local.
# Mac timezone should be America/New_York (ops ET).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="com.sortingdatabase.evening-initials"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
RUNNER="$ROOT/scripts/run_mac_evening_initials.sh"

chmod +x "$RUNNER" "$ROOT/scripts/mac_evening_initials.py" "$ROOT/scripts/uninstall_mac_initials_nights.sh"
mkdir -p "$HOME/Library/LaunchAgents" "$ROOT/logs"

if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
fi
rm -f "$PLIST"

cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>WorkingDirectory</key>
  <string>${ROOT}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER}</string>
  </array>
  <key>StartCalendarInterval</key>
  <array>
    <dict>
      <key>Month</key><integer>8</integer>
      <key>Day</key><integer>28</integer>
      <key>Hour</key><integer>21</integer>
      <key>Minute</key><integer>30</integer>
    </dict>
    <dict>
      <key>Month</key><integer>8</integer>
      <key>Day</key><integer>29</integer>
      <key>Hour</key><integer>21</integer>
      <key>Minute</key><integer>30</integer>
    </dict>
  </array>
  <key>StandardOutPath</key>
  <string>${ROOT}/logs/launchd-evening-initials-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${ROOT}/logs/launchd-evening-initials-stderr.log</string>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/${LABEL}"

# Best-effort wake shortly before each window (may prompt for admin password).
if command -v pmset >/dev/null 2>&1; then
  echo "Scheduling wake attempts at 21:28 on Aug 28 and Aug 29 (may need sudo)..."
  sudo pmset schedule wakeorpoweron "08/28/2026 21:28:00" 2>/dev/null \
    || pmset schedule wakeorpoweron "08/28/2026 21:28:00" 2>/dev/null \
    || echo "Could not schedule Aug 28 wake — keep Mac plugged in / awake that evening."
  sudo pmset schedule wakeorpoweron "08/29/2026 21:28:00" 2>/dev/null \
    || pmset schedule wakeorpoweron "08/29/2026 21:28:00" 2>/dev/null \
    || echo "Could not schedule Aug 29 wake — keep Mac plugged in / awake that evening."
fi

echo
echo "Installed LaunchAgent: ${PLIST}"
echo "Will run at 21:30 on 2026-08-28 and 2026-08-29 (Mac clock)."
echo "Timezone now: $(date +%Z\ %z) — should be EDT/EST (America/New_York)."
echo
echo "Uninstall after Windows has pulled the new code:"
echo "  $ROOT/scripts/uninstall_mac_initials_nights.sh"
echo "Logs: $ROOT/logs/mac-evening-initials-YYYYMMDD.log"
