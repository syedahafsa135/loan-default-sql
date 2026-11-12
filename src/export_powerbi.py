"""Phase 7: export the dashboard view to CSV for Power BI.

Usage:
    python src/export_powerbi.py

Writes powerbi/loans_dashboard.csv (one row per loan, about 30 MB,
git-ignored). The small summary tables Power BI can also use are
already in results/.
"""
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / "powerbi" / "loans_dashboard.csv"
out.parent.mkdir(exist_ok=True)

with sqlite3.connect(ROOT / "data" / "loans.db") as con:
    df = pd.read_sql_query("SELECT * FROM loans_dashboard", con)

df.to_csv(out, index=False)
print(f"Wrote {len(df):,} rows x {df.shape[1]} columns to {out.relative_to(ROOT)}")
