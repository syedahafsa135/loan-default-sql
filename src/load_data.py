"""Phase 1: load the cleaned CSV into SQLite as `loans_raw`.

Usage:
    python src/load_data.py [path/to/Loan_default_cleaned.csv]

The CSV path can also come from the LOAN_CSV environment variable.
The database is written to data/loans.db (git-ignored).
"""
import os
import sqlite3
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "loans.db"
DEFAULT_CSV = ROOT / "data" / "Loan_default_cleaned.csv"

csv_path = Path(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("LOAN_CSV", DEFAULT_CSV))
if not csv_path.exists():
    sys.exit(f"CSV not found: {csv_path}\nSee data/README.md for where to get it.")

df = pd.read_csv(csv_path)
print(f"Read {len(df):,} rows x {df.shape[1]} columns from {csv_path.name}")

DB.parent.mkdir(exist_ok=True)
with sqlite3.connect(DB) as con:
    df.to_sql("loans_raw", con, if_exists="replace", index=False)
    n = con.execute("SELECT COUNT(*) FROM loans_raw").fetchone()[0]
print(f"loans_raw in {DB.relative_to(ROOT)}: {n:,} rows")
