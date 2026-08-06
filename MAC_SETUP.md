# macOS local scrape (every 20 minutes)

Runs at **:10 / :30 / :50** each hour via LaunchAgent. Same scraper as Windows; logs go to `logs/scrape-YYYYMMDD.log`.

## Setup

1. Ensure `.venv` works and `local.env` / `.env` has `UNIUNI_*` + `SUPABASE_*`.
2. Set Mac timezone to **Eastern** (System Settings → General → Date & Time) so schedule matches ops ET.
3. Install the schedule:

```bash
chmod +x scripts/*.sh
./scripts/install_mac_schedule.sh
```

4. Optional smoke test (runs immediately, does not wait for :10/:30/:50):

```bash
./scripts/run_scrape.sh
# or
launchctl kickstart -k "gui/$(id -u)/com.sortingdatabase.scrape"
```

## Notes

- Headless by default (no browser window).
- If a run is still going, the next trigger skips (`logs/scrape.lock`).
- Session reuse: `.uniuni-auth-state.json` (login only when expired).
- First Playwright run may need Accessibility / Screen Recording / Automation prompts — approve once while logged in at the Mac GUI.
- Keep the Mac awake around scrape times (or disable sleep while plugged in).

## Uninstall

```bash
./scripts/uninstall_mac_schedule.sh
```
