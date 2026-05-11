#!/usr/bin/env python3
"""Download the official NYC TLC Taxi Zone Lookup CSV into seeds/.

Usage:
    python scripts/download_seed_data.py
"""

import csv
import io
import sys
import urllib.request
from pathlib import Path

TAXI_ZONE_URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
SEED_DIR = Path(__file__).resolve().parent.parent / "seeds"
OUTPUT_FILE = SEED_DIR / "taxi_zone_lookup.csv"

EXPECTED_HEADERS = {"LocationID", "Borough", "Zone", "service_zone"}


def download_and_validate() -> None:
    print(f"Downloading taxi zone lookup from {TAXI_ZONE_URL} ...")
    req = urllib.request.Request(TAXI_ZONE_URL, headers={"User-Agent": "nyc-tlc-trips-dbt/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:  # noqa: S310 — trusted URL
        raw = resp.read().decode("utf-8-sig")

    reader = csv.DictReader(io.StringIO(raw))
    headers = set(reader.fieldnames or [])
    if not EXPECTED_HEADERS.issubset(headers):
        print(f"ERROR: unexpected headers {headers}", file=sys.stderr)
        sys.exit(1)

    rows = list(reader)
    if len(rows) < 200:
        print(f"ERROR: only {len(rows)} rows — expected 260+", file=sys.stderr)
        sys.exit(1)

    SEED_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["LocationID", "Borough", "Zone", "service_zone"])
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row[k] for k in writer.fieldnames})

    print(f"Wrote {len(rows)} zones to {OUTPUT_FILE}")


if __name__ == "__main__":
    download_and_validate()
