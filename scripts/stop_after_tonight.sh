#!/usr/bin/env bash
# One-shot: after tonight's 21:10 ET scrape, unload the scrape LaunchAgent.
# Installs a helper LaunchAgent that fires once at 21:25 local time today.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="com.sortingdatabase.scrape.stop"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
STOPPER="$ROOT/scripts/_stop_scrape_schedule_once.sh"
UNINSTALL="$ROOT/scripts/uninstall_mac_schedule.sh"

# Local calendar for "today 21:25" (Mac clock; should be Eastern for ops).
YEAR="$(date +%Y)"
MONTH="$(date +%m)"
DAY="$(date +%d)"
# Plist integers must not have leading zeros interpreted as octal.
MONTH=$((10#$MONTH))
DAY=$((10#$DAY))
HOUR=21
MINUTE=25

cat >"$STOPPER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="$ROOT"
LABEL_STOP="$LABEL"
PLIST_STOP="$PLIST"
"$UNINSTALL" || true
# Remove this one-shot helper.
if launchctl print "gui/\$(id -u)/\${LABEL_STOP}" >/dev/null 2>&1; then
  launchctl bootout "gui/\$(id -u)/\${LABEL_STOP}" 2>/dev/null || true
fi
rm -f "\$PLIST_STOP" "$STOPPER"
echo "\$(date '+%Y-%m-%d %H:%M:%S %Z') stopped scrape schedule after 21:10 run" >> "\$ROOT/logs/schedule-stop.log"
EOF
chmod +x "$STOPPER"
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
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${STOPPER}</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Year</key><integer>${YEAR}</integer>
    <key>Month</key><integer>${MONTH}</integer>
    <key>Day</key><integer>${DAY}</integer>
    <key>Hour</key><integer>${HOUR}</integer>
    <key>Minute</key><integer>${MINUTE}</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>${ROOT}/logs/schedule-stop-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${ROOT}/logs/schedule-stop-stderr.log</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/${LABEL}"

echo "Will stop scrape schedule tonight at ${YEAR}-$(printf '%02d' "$MONTH")-$(printf '%02d' "$DAY") ${HOUR}:$(printf '%02d' "$MINUTE") local ($(date +%Z))."
echo "21:10 scrape still runs; after ~${HOUR}:${MINUTE} LaunchAgent is removed."
echo "Cancel: launchctl bootout gui/$(id -u)/${LABEL} && rm -f ${PLIST}"
