# macOS: edit code (Windows runs the schedule)

**Windows** runs the :10 / :30 / :50 scrapes. **Mac** only edits and `git push`.

Mac path: `~/Projects/Sorting Database`

---

## Day-to-day sync

### Mac push

```bash
cd ~/Projects/Sorting\ Database
git checkout main
git pull origin main
# …edit…
git add -A
git commit -m "your message"
git push origin main
```

### Windows pull (other machine)

```powershell
cd "$HOME\Projects\Sorting Database"
git checkout main
git pull origin main
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

Full Windows guide: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)

---

## Uninstall Mac schedule

```bash
cd ~/Projects/Sorting\ Database
./scripts/uninstall_mac_schedule.sh
```

---

## Optional: Mac as scrape backup

Usually not needed. Only one machine should run the schedule at a time.

```bash
chmod +x scripts/*.sh
./scripts/install_mac_schedule.sh
./scripts/run_scrape.sh   # dry run
```
