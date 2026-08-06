#!/usr/bin/env bash
# Install LaunchAgent: scrape at :10 / :30 / :50 every hour (Mac local time).
# Prefer setting the Mac timezone to America/New_York so times match ops ET.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="com.sortingdatabase.scrape"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
RUNNER="$ROOT/scripts/run_scrape.sh"

chmod +x "$RUNNER"
mkdir -p "$HOME/Library/LaunchAgents" "$ROOT/logs"

# Unload existing job if present.
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
    <dict><key>Minute</key><integer>10</integer></dict>
    <dict><key>Minute</key><integer>30</integer></dict>
    <dict><key>Minute</key><integer>50</integer></dict>
  </array>
  <key>StandardOutPath</key>
  <string>${ROOT}/logs/launchd-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${ROOT}/logs/launchd-stderr.log</string>
  <key>ProcessType</key>
  <string>Interactive</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/${LABEL}"

echo "Installed LaunchAgent: ${PLIST}"
echo "Schedule: every hour at :10 / :30 / :50 (Mac clock)."
echo "Timezone now: $(date +%Z\ %z) — set Mac to Eastern if ops times must match ET."
echo
echo "Useful commands:"
echo "  launchctl print gui/$(id -u)/${LABEL}"
echo "  # run once now:"
echo "  launchctl kickstart -k gui/$(id -u)/${LABEL}"
echo "  # uninstall:"
echo "  $ROOT/scripts/uninstall_mac_schedule.sh"
echo
echo "Logs: $ROOT/logs/scrape-YYYYMMDD.log"
