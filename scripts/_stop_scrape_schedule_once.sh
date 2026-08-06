#!/usr/bin/env bash
set -euo pipefail
ROOT="/Users/vivienneyang/Projects/Sorting Database"
LABEL_STOP="com.sortingdatabase.scrape.stop"
PLIST_STOP="/Users/vivienneyang/Library/LaunchAgents/com.sortingdatabase.scrape.stop.plist"
"/Users/vivienneyang/Projects/Sorting Database/scripts/uninstall_mac_schedule.sh" || true
# Remove this one-shot helper.
if launchctl print "gui/$(id -u)/${LABEL_STOP}" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/${LABEL_STOP}" 2>/dev/null || true
fi
rm -f "$PLIST_STOP" "/Users/vivienneyang/Projects/Sorting Database/scripts/_stop_scrape_schedule_once.sh"
echo "$(date '+%Y-%m-%d %H:%M:%S %Z') stopped scrape schedule after 21:10 run" >> "$ROOT/logs/schedule-stop.log"
