"""Set app_metadata.roles (and optional default_tab) for dashboard users."""
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
    parser.add_argument("--username", required=True)
    parser.add_argument(
        "--roles",
        required=True,
        help="Comma-separated roles, e.g. city,feed or feed",
    )
    parser.add_argument(
        "--default-tab",
        choices=("city", "feed"),
        default=None,
        help="Landing tab when the user has both city and feed roles",
    )
    args = parser.parse_args()

    load_dotenv(ROOT / "local.env")
    load_dotenv(ROOT / ".env")
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if not url or not key:
        print("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY", file=sys.stderr)
        return 1

    email = f"{normalize_username(args.username)}@{USERNAME_DOMAIN}"
    roles = [r.strip() for r in args.roles.split(",") if r.strip()]
    sb = create_client(url, key)

    page = sb.auth.admin.list_users()
    users = page if isinstance(page, list) else getattr(page, "users", [])
    match = None
    for u in users:
        u_email = getattr(u, "email", None)
        if u_email and u_email.lower() == email.lower():
            match = u
            break
    if not match:
        print(f"User not found for username {args.username!r} ({email})", file=sys.stderr)
        return 1

    uid = getattr(match, "id")
    meta = {"roles": roles}
    if args.default_tab:
        meta["default_tab"] = args.default_tab
    sb.auth.admin.update_user_by_id(uid, {"app_metadata": meta})
    print(f"Updated {args.username}: {meta}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
