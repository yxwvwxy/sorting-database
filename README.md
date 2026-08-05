# Sorting Database (local scraper)

Local / Windows UniMap scraper for NJ sorting data → Supabase.

This repo is the **local 20-minute scrape** program (Task Scheduler on Windows).  
The older GitHub Actions daily scraper stays in [`sorting-data-scrape`](https://github.com/yxwvwxy/sorting-data-scrape) and is disabled.

## Quick start (Mac)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m playwright install chromium
cp .env.example .env   # fill secrets
python -m src.main --dry-run
```

## Windows

See [WINDOWS_SETUP.md](WINDOWS_SETUP.md).

## Batch resolution

- **21:10 ET**: use saved batch (`.current-batch.json`), do not open Slot Assignment  
- **From 21:30 ET**: poll Slot Assignment until Batch No changes; page value is source of truth  
- Scrapes at **:10 / :30 / :50** each hour; each run inserts a full snapshot keyed by `scraped_at`
