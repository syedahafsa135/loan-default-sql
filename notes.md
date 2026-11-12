# Working notes

Notes from the audit (Phase 2), the cleaning decisions (Phase 3) and the validation (Phase 6). Every number here comes from a query in `sql/`, and its output is saved in `results/`.

## Source

- `Loan_default_cleaned.csv`: the output of Part 1 (preprocessing) of my data science project on the Kaggle Loan Default Prediction dataset. It has 255,347 rows and 18 columns.
- Compared with the raw `Loan_default.csv`, it differs in two ways only:
  1. **MonthsEmployed** is capped at (Age − 16) × 12 for 17,274 rows (6.76%), where the raw value was longer than the borrower's possible working life.
  2. **Education** labels have their apostrophes removed (`Bachelor's` → `Bachelors`, `Master's` → `Masters`; 127,907 rows).

  Every other value is identical. I checked this by joining the two files on LoanID in pandas.

## Phase 2: data audit (`sql/01_audit.sql`)

| Check | Result | Decision |
|---|---|---|
| Duplicate LoanIDs | 0 of 255,347 | Make `loan_id` the primary key so it stays that way |
| Fully duplicated rows (ignoring ID) | 0 | Nothing to drop |
| NULLs | 0 in every column | No imputation needed |
| MonthsEmployed > working life | 0 (raw file: 17,274) | Confirms the Part 1 cap is in this file |
| Target coding | `Default` is 0/1: 225,694 (88.39%) vs 29,653 (11.61%) | Rename to `is_default`; `DEFAULT` is a reserved SQL word and must be quoted |
| Numeric ranges | Age 18–69, Income 15,000–149,999, LoanAmount 5,000–249,999, CreditScore 300–849, InterestRate 2–25%, DTI 0.1–0.9, NumCreditLines 1–4, MonthsEmployed 0–119 | All plausible; no outliers to remove |
| Category balance | Every category is split almost evenly (each employment type ≈ 25%, each loan purpose ≈ 20%, each term ≈ 20%) | Not a problem for SQL, but a sign of **synthetic data** (see caveats) |

### Issues and caveats to carry into the README

1. **No dates.** There is no origination date, issue date or loan status. That means:
   - No volume-over-time view and no true vintage analysis.
   - The "current loans haven't had time to default" caveat can't be measured here. We don't know how old each loan is, so some loans labelled 0 may still default. Treat 11.61% as a floor for the true default rate.
   - Window functions run over **ordered bands** instead (age, credit score, deciles), and `12_adv_cohort_matrix.sql` stands in for a vintage table.
2. **Likely synthetic.** The near-perfectly even categories and the near-zero correlations between attributes (from Part 1) suggest the data was generated, not taken from a real lender. The patterns are useful for practising analysis, but shouldn't be presented as how real borrowers behave.
3. **Age and fairness.** Age is the strongest signal in the data. In real lending, age-based rules raise legal and fairness concerns, so any rule here is analytical, not a lending recommendation.
4. **Weak credit score signal.** Half the loans (130,223) are in the FICO "Poor" band, and the default rate only falls from 13.67% to 9.81% across the whole scale. This is unusual for real credit data and is another hint the data is synthetic.

## Phase 3: cleaning decisions (`sql/02_clean.sql`)

- `loan_id TEXT PRIMARY KEY`, so the database itself rejects duplicates.
- Yes/No columns → 0/1 integers, with `CHECK (col IN (0,1))`.
- Two ratios from Part 1: `loan_to_income` = LoanAmount / Income and `principal_per_month` = LoanAmount / LoanTerm.
- Bands for GROUP BY:
  - `credit_band`: the common FICO ranges (300–579 Poor, 580–669 Fair, 670–739 Good, 740–799 Very good, 800+ Exceptional)
  - `age_band`: 18–24, then 10-year bands, then 65–69
  - `income_band`: 30k steps
  - `rate_band`: 5-point steps
  - `dti_band`: 0.2 steps
  - Each band label starts with a number so it sorts correctly.
- Indexes on employment type, purpose and age (the most-grouped columns).

**Done-when check:** `loans` has 255,347 rows, 0 duplicate IDs and 29,653 defaults, a rate of 11.61%. This matches the earlier analysis exactly.

## Phase 6: validation (`src/validate.py`)

pandas reads the CSV (not the database) and recomputes five results independently:

| Check | Result |
|---|---|
| Rows and overall default rate | Match (255,347, 11.61%) |
| Default rate by employment type | Match on all 4 |
| Interest-rate deciles | Match on all 10 |
| Red-flag scorecard (loans and rate per flag count) | Match on all 5 rows |
| Pareto: segments to half of defaults, and their loan share | Match (120 segments, 40 needed, 28.6% of loans) |

**A difference worth explaining:** `pd.qcut(df.InterestRate, 10)` doesn't give the same deciles as SQL's `NTILE(10)`.

- `NTILE` splits by **row position**, so every group has 25,534 or 25,535 loans.
- `qcut` splits by **value** and keeps tied rates together. There are only 2,301 distinct rates, so its groups range from 25,471 to 25,622 loans, and some decile rates move by up to 0.02 points (for example 13.45% vs 13.43%).
- To match exactly, `validate.py` sorts the same way as the SQL (rate descending, then LoanID) and cuts into equal row blocks.
