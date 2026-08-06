"""Create a Supabase Auth user for the city dashboard (username + password)."""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

ROOT = Path(__file__).resolve().parents[1]
USERNAME_DOMAIN = "sorting-db.local"


def normalize_username(username: str) -> str:
    return re.sub(r"\s+", ".", username.strip().lower())


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--username", help="Login username (no email)")
    group.add_argument("--email", help="Legacy: full email login")
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    load_dotenv(ROOT / "local.env")
    load_dotenv(ROOT / ".env")
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not url or not key:
        print("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY", file=sys.stderr)
        return 1

    if args.username:
        display = args.username.strip()
        if not display or "@" in display:
            print("Username must be non-empty and must not contain @", file=sys.stderr)
            return 1
        local = normalize_username(display)
        if not local:
            print("Username is empty after normalization", file=sys.stderr)
            return 1
        email = f"{local}@{USERNAME_DOMAIN}"
    else:
        email = args.email.strip()
        display = email

    sb = create_client(url, key)
    sb.auth.admin.create_user(
        {
            "email": email,
            "password": args.password,
            "email_confirm": True,
            "user_metadata": {"username": display},
        }
    )
    print("Created user:", display)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
