"""Run one or more .sql files against data/loans.db.

Usage:
    python src/run_sql.py sql/01_audit.sql [sql/02_clean.sql ...]
    python src/run_sql.py --all          # every file in sql/, in name order

A statement preceded by a line `-- name: some_name` has its result saved to
results/some_name.csv and printed as a table. Other statements just run.
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "loans.db"
OUT = ROOT / "results"


def statements(sql_text):
    """Yield (name, statement) pairs; name comes from a `-- name:` line."""
    buf, name = [], None
    for line in sql_text.splitlines():
        stripped = line.strip()
        if stripped.lower().startswith("-- name:"):
            name = stripped.split(":", 1)[1].strip()
            continue
        buf.append(line)
        joined = "\n".join(buf)
        if sqlite3.complete_statement(joined):
            if joined.strip().strip(";").strip():
                yield name, joined
            buf, name = [], None


def run(path, con):
    print(f"\n=== {path.name} ===")
    for name, stmt in statements(path.read_text(encoding="utf-8")):
        if name:
            df = pd.read_sql_query(stmt, con)
            df.to_csv(OUT / f"{name}.csv", index=False)
            print(f"\n-- {name} ({len(df)} rows)")
            with pd.option_context("display.width", 200, "display.max_columns", 30):
                print(df.head(40).to_string(index=False))
        else:
            con.executescript(stmt)
    con.commit()


if __name__ == "__main__":
    args = sys.argv[1:]
    files = sorted((ROOT / "sql").glob("*.sql")) if args == ["--all"] else [Path(a) for a in args]
    OUT.mkdir(exist_ok=True)
    with sqlite3.connect(DB) as con:
        for f in files:
            run(f if f.is_absolute() else ROOT / f, con)
