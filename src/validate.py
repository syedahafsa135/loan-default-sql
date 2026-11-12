"""Phase 6: cross-check SQL results against pandas.

pandas reads the original CSV (not the database) and recomputes five
results independently. Each is compared with the matching file in
results/. Exit code 1 if anything disagrees.

Usage:
    python src/validate.py [path/to/Loan_default_cleaned.csv]
"""
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "results"
csv_path = Path(sys.argv[1] if len(sys.argv) > 1 else
                os.environ.get("LOAN_CSV", ROOT / "data" / "Loan_default_cleaned.csv"))

df = pd.read_csv(csv_path)
failures = []


def check(label, pandas_value, sql_value, tol=0.01):
    ok = np.allclose(np.asarray(pandas_value, dtype=float),
                     np.asarray(sql_value, dtype=float), atol=tol)
    print(f"[{'OK ' if ok else 'BAD'}] {label}")
    print(f"       pandas: {np.round(np.asarray(pandas_value, dtype=float), 2).tolist()}")
    print(f"       SQL   : {np.round(np.asarray(sql_value, dtype=float), 2).tolist()}")
    if not ok:
        failures.append(label)


# 1. Overall default rate (02_clean.sql)
sql = pd.read_csv(RES / "clean_checks.csv").iloc[0]
check("1. rows and default rate",
      [len(df), round(100 * df["Default"].mean(), 2)],
      [sql.n_rows, sql.default_rate_pct])

# 2. Default rate by employment type (06_basic_purpose_employment.sql)
p = (df.groupby("EmploymentType")["Default"].mean() * 100).round(2).sort_index()
s = pd.read_csv(RES / "q4b_default_by_employment.csv").set_index("employment_type")["default_rate_pct"].sort_index()
check("2. default rate by employment type", p.values, s.values)

# 3. Interest-rate deciles (09_adv_ntile_deciles.sql)
#    NTILE splits by row position, so reproduce that exactly: sort the same
#    way (rate desc, then LoanID) and cut into 10 near-equal row blocks.
#    pd.qcut would cut by value instead, putting tied rates in one bin and
#    giving slightly different group sizes.
d = df.sort_values(["InterestRate", "LoanID"], ascending=[False, True]).reset_index(drop=True)
blocks = np.array_split(np.arange(len(d)), 10)          # first blocks get the extra row, like NTILE
d["decile"] = np.concatenate([np.full(len(b), i + 1) for i, b in enumerate(blocks)])
p = (d.groupby("decile")["Default"].mean() * 100).round(2)
s = pd.read_csv(RES / "q7a_interest_rate_deciles.csv")["default_rate_pct"]
check("3. default rate by interest-rate decile", p.values, s.values)

# 4. Red-flag scorecard (11_adv_cte_scorecard.sql)
flags = ((df.Age < 30).astype(int) + (df.InterestRate >= 18).astype(int)
         + (df.LoanAmount / df.Income).round(4).ge(3).astype(int)
         + (df.MonthsEmployed < 24).astype(int))
p = df.groupby(flags)["Default"].agg(["size", "mean"])
s = pd.read_csv(RES / "q9_red_flag_scorecard.csv")
check("4a. scorecard loans per flag count", p["size"].values, s["loans"].values, tol=0)
check("4b. scorecard default rate per flag count", (100 * p["mean"]).round(2).values, s["default_rate_pct"].values)

# 5. Pareto: segments needed for half of defaults (13_adv_pareto_segments.sql)
age_band = pd.cut(df.Age, [0, 24, 34, 44, 54, 64, 200], labels=False)
inc_band = pd.cut(df.Income, [0, 29999, 59999, 89999, 119999, np.inf], labels=False)
seg = df.groupby([age_band, df.EmploymentType, inc_band])["Default"].agg(["size", "sum", "mean"])
seg = seg[seg["size"] >= 500].sort_values("mean", ascending=False)
cum = seg["sum"].cumsum() / df["Default"].sum()
n_half = int((cum < 0.5).sum()) + 1
share = 100 * seg["size"].iloc[:n_half].sum() / len(df)
s = pd.read_csv(RES / "q11b_pareto_summary.csv").iloc[0]
check("5. segments to half of defaults, and their loan share",
      [len(seg), n_half, round(share, 1)],
      [s.total_segments, s.segments_to_half_of_defaults, s.share_of_loans_at_that_point_pct], tol=0.05)

print("\nAll checks match." if not failures else f"\nMismatches: {failures}")
sys.exit(1 if failures else 0)
