"""Manual Bundle Management export. The scheduled path is run_scrape.bat."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.bundle_export import main

if __name__ == "__main__":
    raise SystemExit(main())
