#!/usr/bin/env bash
# Upload web/index.html to the public Supabase Storage dashboard bucket.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
exec "$ROOT/.venv/bin/python" - <<'PY'
import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv("local.env")
load_dotenv(".env")
sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
html = Path("web/index.html").read_bytes()
sb.storage.from_("dashboard").upload(
    path="index.html",
    file=html,
    file_options={"content-type": "text/html; charset=utf-8", "upsert": "true"},
)
print(
    "Published:",
    "https://xllimmgxkttjzaikimtu.supabase.co/storage/v1/object/public/dashboard/index.html",
)
PY
