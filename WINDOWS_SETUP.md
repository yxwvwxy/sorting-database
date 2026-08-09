# Windows local scrape (every 20 minutes)

Runs at **:10 / :30 / :50** each hour. Each run inserts a full snapshot into Supabase (`subbatch`, `chute_volume`, `feed_station`, `hourly_throughput`) keyed by `scraped_at`.

Batch ID:

- **21:10 ET** → reuse saved batch only (do **not** open Slot Assignment)
- **From 21:30 ET** until Slot `Batch No` **changes** from the pre-switch value → **every run** opens Slot Assignment
  - still old → scrape with the **old** batch; check again next run
  - changed → page value is the new ops-day batch (evening of D → ops day D+1); **stop** Slot checks until the next 21:30
- If a Slot check **fails** (login/timeout/skip) → not confirmed; later runs must check again
- If 21:30 was missed and this ops day is not confirmed yet → daytime runs also check until the page changes
- Manual refresh: `.\scripts\run_scrape.bat --refresh-batch`
- Normal runs are **headless** and reuse `.uniuni-auth-state.json` (saved only after a usable login)

## Lock (`logs\scrape.lock`)

Prevents overlapping runs. If a run crashes and leaves the lock, it is treated as stale after **15 minutes** (schedule is every 20 minutes). A live overlap still skips with exit code 2.

## Setup

1. Install Python 3.11+ and copy this repo folder onto the PC.
2. In PowerShell from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

3. Copy `.env.example` → `.env` and fill `UNIUNI_*`, `SUPABASE_*` (Sheet vars optional).
4. Set Windows timezone to **Eastern Time**.
5. Test one run:

```bat
.\scripts\run_scrape.bat
```

6. Register Task Scheduler jobs:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1
```

## Power (do later)

- Stay plugged in  
- Lid closed: sleep → **Never** (or “Stay awake when lid closed”)  
- Screen can turn off; PC should not sleep  

## Logs

- `logs\scrape-YYYYMMDD.log`
- Overlap skip → exit code **2** (`Skip: previous scrape still running`)
- Stale lock cleared → logged, then the run continues
- Success → log ends with `Saved scrape snapshot`

## Manual overrides

```bat
.\scripts\run_scrape.bat --subbatch NJSUB-202608032100
.\scripts\run_scrape.bat --dry-run --headed
```
