# Windows local scrape (every 20 minutes)

Runs at **:10 / :30 / :50** each hour. Each run inserts a full snapshot into Supabase (`subbatch`, `chute_volume`, `feed_station`, `hourly_throughput`) keyed by `scraped_at`.

Batch ID:

- **Page is source of truth**: whatever `Batch No` Slot Assignment shows is the batch to scrape (no assumption that Aug 6 must be `…052100`)
- **21:10 ET** → reuse saved batch (do **not** open Slot Assignment)
- **From 21:30 ET onward** → open Slot Assignment each run until the Batch No **changes**
  - still old → keep old batch; check again at 21:50 / 22:10 / 1:10am / …
  - changed (even to an unusual ID like `…062100`) → save that page value under the window’s operation date (evening of D → ops day D+1), then stop polling until the next 21:30
- Manual refresh: `.\scripts\run_scrape.bat --refresh-batch`
- Normal runs are **headless** and reuse `.uniuni-auth-state.json`

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
- If a run is still going, the next trigger skips (`scrape.lock`)

## Manual overrides

```bat
.\scripts\run_scrape.bat --subbatch NJSUB-202608032100
.\scripts\run_scrape.bat --dry-run --headed
```
