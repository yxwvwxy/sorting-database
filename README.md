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

## City dashboard (login required)

Live site (GitHub Pages from this repo’s `docs/`):

**https://yxwvwxy.github.io/sorting-database/**

- Scraper + dashboard now live in **one** repo: [`sorting-database`](https://github.com/yxwvwxy/sorting-database)
- Must sign in before data loads (`city_volume_series` / `list_scrape_batches` are `authenticated` only)
- Or click **Login as Guest** (read-only; same RLS as signed-in users)
- `last_mile` → city; `transit` → warehouse  
- Source of truth for Pages: [`docs/index.html`](docs/index.html) (keep [`web/index.html`](web/index.html) in sync for optional Supabase Storage publish)
- Legacy Pages URL [`sorting-city-dashboard`](https://yxwvwxy.github.io/sorting-city-dashboard/) redirects here; that separate repo is archived

Create a login user:

```bash
.venv/bin/python scripts/create_dashboard_user.py --username NAME --password 'your-password'
```

Local preview of the HTML (still needs a real Auth user):

```bash
.venv/bin/python -m http.server 8080 --directory docs
# http://localhost:8080
```

Optional Streamlit (local only):

```bash
./scripts/run_dashboard.sh
```

## Windows runner + Mac editor

**Windows** 跑定时；**Mac** 改代码后 push。说明：[WINDOWS_SETUP.md](WINDOWS_SETUP.md) · [MAC_SETUP.md](MAC_SETUP.md)

```bash
# Mac — 推送
cd ~/Projects/Sorting\ Database
git checkout main && git pull origin main
# …edit…
git add -A && git commit -m "your message" && git push origin main
```

```powershell
# Windows — 拉取
cd "$HOME\Projects\Sorting Database"
git checkout main
git pull origin main
# 或: powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

## Batch resolution

- **21:10 ET**: use saved batch (`.current-batch.json`), do not open Slot Assignment  
- **From 21:30 ET**: poll Slot Assignment until Batch No changes; page value is source of truth  
- Scrapes at **:10 / :30 / :50** each hour  
- **First scrape of a new ops-day batch** (after Batch No switches): open **Workflow Management**, read Step 2 warehouse initials for **RIC / ALB / SWF / SYR / BOS→PVD2**, save to `city_initial_volume`, and **skip chute/隔口 scrape** that run  
- Later runs: normal Sorting Production Analysis chute/feed/hourly scrape  
- City totals in `city_volume_series`: **initial + chute volumes** for those five cities  
- Manual initials only: `python -m src.main --initials-only --headed --subbatch NJSUB-YYYYMMDD2100`
