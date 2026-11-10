# Windows = scrape runner · Mac = editor

**Roles**

| Machine | Job |
|---------|-----|
| **Windows PC** | Install deps, keep `.env` / login state, Task Scheduler every 20 minutes |
| **Mac** | Edit in Cursor → `git commit` + `git push` |

Do **not** sync the whole project with OneDrive on Windows; pull with Git.  
`.env`, `.uniuni-auth-state.json`, `.current-batch.json`, and `logs/` are gitignored and stay on the Windows box only.

**Important: only one machine should run the schedule at a time.**  
After Windows is the live runner, on Mac:

```bash
cd ~/Projects/Sorting\ Database
./scripts/uninstall_mac_schedule.sh
```

---

## A. Mac: edit and push

```bash
cd ~/Projects/Sorting\ Database
git checkout main
git pull origin main
# …edit in Cursor…
git add -A
git commit -m "your message"
git push origin main
```

Then pull on **Windows** (section C).

---

## B. Windows: one-time setup

### 1) System

- Windows 10/11, **plugged in**
- Time zone: **Eastern Time (US & Canada)**
- Sleep: plugged in **Never**; lid close may blank the screen, but do not sleep
- Install [Git for Windows](https://git-scm.com/download/win)
- Install [Python 3.11+](https://www.python.org/downloads/) (check **Add python.exe to PATH**)

### 2) Clone

```powershell
cd $HOME\Projects
git clone https://github.com/yxwvwxy/sorting-database.git "Sorting Database"
cd "Sorting Database"
git checkout main
```

### 3) venv + Playwright

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

### 4) Secrets (Windows only)

```powershell
copy .env.example .env
notepad .env
```

At least: `UNIUNI_USERNAME` / `UNIUNI_PASSWORD`, `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`  
(Copy from Mac `local.env` / `.env` by hand; never commit.)

### 5) Test run

```bat
.\scripts\run_scrape.bat
```

Success: `logs\scrape-YYYYMMDD.log` ends with `Saved scrape snapshot`.  
Debug: `.\scripts\run_scrape.bat --headed --dry-run`

### 6) Register schedule (:10 / :30 / :50)

```powershell
cd "$HOME\Projects\Sorting Database"
powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1
```

Task names: `SortingDataScrape20Min-10` / `-30` / `-50`

---

## C. Windows: pull after a Mac push

In **PowerShell**:

```powershell
cd "$HOME\Projects\Sorting Database"
git checkout main
git pull origin main
```

Or:

```powershell
cd "$HOME\Projects\Sorting Database"
powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

If `requirements.txt` changed:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

You usually do **not** need to reinstall Playwright. The next :10 / :30 / :50 run picks up the new code.

---

## D. Runtime behavior

- Each hour at **:10 / :30 / :50** ET  
- Each run writes chute + feed  
- **hourly**: current incomplete hour updates every scrape; after the hour ends it finalizes once; recovery backfills unfinished hours  
- Query failures retry / force re-login; a full failure lets the bat start another browser pass  
- Overlapping run → skip (`logs\scrape.lock`; stale lock expires after about **15 minutes**)  
- UniMap session: `.uniuni-auth-state.json`

**Batch**

- **16:10 ET** → saved batch only (C last scrape); do not open Slot Assignment  
- **From 16:30 ET** until Slot `Batch No` changes → poll Slot each run  
  - Still old → keep old batch, check again next run  
  - Changed → use the page batch (open of D → ops day D+1, phase A)  
- From **23:10** watch for batch 2; from **06:10** watch for batch 3 (see scraper docs)  
- Before ops day **2026-11-09** (calendar open **2026-11-08** 16:30) the close/open pair was 19:10 / 19:30  
- Slot check failure → not confirmed; keep polling  
- Manual: `.\scripts\run_scrape.bat --refresh-batch`

---

## E. Logs and troubleshooting

| Location | Use |
|----------|-----|
| `logs\scrape-YYYYMMDD.log` | Per-run output |
| Task Scheduler → History | Whether the task fired |
| `.\scripts\run_scrape.bat --headed` | See where UniMap stalls |

- Overlap skip → exit code **2**  
- Success → log ends with `Saved scrape snapshot`  
- Repeated failures: make sure nobody else shares `nj600`; delete `.uniuni-auth-state.json` to re-login  

---

## F. Stop Windows schedule (hand back to Mac)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\unregister_scheduled_tasks.ps1
```

Then on Mac: `./scripts/install_mac_schedule.sh`
