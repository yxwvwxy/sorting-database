#!/usr/bin/env bash
set -euo pipefail

LABEL="com.sortingdatabase.evening-initials"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"

if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
fi
rm -f "$PLIST"
echo "Removed LaunchAgent ${LABEL}"
