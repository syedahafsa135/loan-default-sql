"""Prepare the Kaggle Loan Default file for the model-comparison notebook.

Re-creates the two record-level fixes described in the Project 1 report
(Data Preprocessing: Case Study on Loan Default Dataset, sections 3.1 and 3.4.3):

1. Remove apostrophes from the Education labels (Bachelor's -> Bachelors),
   because WEKA's CSV loader treats them as quote characters.
2. Cap MonthsEmployed at (Age - 16) * 12, assuming a minimum working age of 16.
   The report found 17,274 records (6.76%) above this cap.

All other steps (ratio attributes, feature removal, binning, scaling, sampling
and SMOTE) happen inside the notebook's pipeline, so they are fitted on
training data only.

Usage:
    python src/prepare_data.py                      # reads data/Loan_default.csv
    python src/prepare_data.py path/to/Loan_default.csv
"""
import sys
from pathlib import Path

import pandas as pd

RAW = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("data/Loan_default.csv")
OUT = Path("data/Loan_default_cleaned.csv")

df = pd.read_csv(RAW)
assert df.shape == (255347, 18), f"expected 255,347 rows x 18 columns, got {df.shape}"

df["Education"] = df["Education"].str.replace("'", "", regex=False)

cap = (df["Age"] - 16) * 12
over = df["MonthsEmployed"] > cap
print(f"MonthsEmployed above (Age - 16) x 12: {over.sum():,} records ({over.mean():.2%})")
df.loc[over, "MonthsEmployed"] = cap[over]

OUT.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(OUT, index=False)
print(f"saved {OUT} with shape {df.shape}")
