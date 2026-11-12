/* =====================================================================
   02_clean.sql  |  Phase 3: build the analysis table `loans`
   Question : What does a clean, query-friendly version of loans_raw
              look like?
   Decisions (see notes.md for why):
     - LoanID is the PRIMARY KEY, so a duplicate ID cannot get in.
     - "Default" (a reserved word) becomes is_default (0/1).
     - Yes/No columns become 0/1 integers.
     - Numeric columns get readable bands for GROUP BY. Credit score
       bands follow the common FICO ranges.
     - Two ratios from Part 1 of the data science project are added:
       loan_to_income and principal_per_month.
   Takeaway : loans has 255,347 rows, no duplicate IDs, and an
              is_default rate of 11.61%, the same as the earlier analysis.
   ===================================================================== */

DROP TABLE IF EXISTS loans;

CREATE TABLE loans (
    loan_id              TEXT PRIMARY KEY,
    age                  INTEGER NOT NULL,
    income               INTEGER NOT NULL,
    loan_amount          INTEGER NOT NULL,
    credit_score         INTEGER NOT NULL,
    months_employed      INTEGER NOT NULL,
    num_credit_lines     INTEGER NOT NULL,
    interest_rate        REAL    NOT NULL,
    loan_term            INTEGER NOT NULL,
    dti_ratio            REAL    NOT NULL,
    education            TEXT    NOT NULL,
    employment_type      TEXT    NOT NULL,
    marital_status       TEXT    NOT NULL,
    has_mortgage         INTEGER NOT NULL CHECK (has_mortgage IN (0, 1)),
    has_dependents       INTEGER NOT NULL CHECK (has_dependents IN (0, 1)),
    loan_purpose         TEXT    NOT NULL,
    has_cosigner         INTEGER NOT NULL CHECK (has_cosigner IN (0, 1)),
    is_default           INTEGER NOT NULL CHECK (is_default IN (0, 1)),
    -- derived
    loan_to_income       REAL    NOT NULL,
    principal_per_month  REAL    NOT NULL,
    credit_band          TEXT    NOT NULL,
    age_band             TEXT    NOT NULL,
    income_band          TEXT    NOT NULL,
    rate_band            TEXT    NOT NULL,
    dti_band             TEXT    NOT NULL
);

INSERT INTO loans
SELECT
    LoanID,
    Age,
    CAST(Income AS INTEGER),
    CAST(LoanAmount AS INTEGER),
    CreditScore,
    MonthsEmployed,
    NumCreditLines,
    InterestRate,
    LoanTerm,
    DTIRatio,
    Education,
    EmploymentType,
    MaritalStatus,
    HasMortgage   = 'Yes',
    HasDependents = 'Yes',
    LoanPurpose,
    HasCoSigner   = 'Yes',
    "Default",
    ROUND(1.0 * LoanAmount / Income, 4),
    ROUND(1.0 * LoanAmount / LoanTerm, 2),
    CASE WHEN CreditScore < 580 THEN '1 Poor (300-579)'
         WHEN CreditScore < 670 THEN '2 Fair (580-669)'
         WHEN CreditScore < 740 THEN '3 Good (670-739)'
         WHEN CreditScore < 800 THEN '4 Very good (740-799)'
         ELSE                        '5 Exceptional (800+)' END,
    CASE WHEN Age < 25 THEN '18-24'
         WHEN Age < 35 THEN '25-34'
         WHEN Age < 45 THEN '35-44'
         WHEN Age < 55 THEN '45-54'
         WHEN Age < 65 THEN '55-64'
         ELSE               '65-69' END,
    CASE WHEN Income < 30000  THEN '1 <30k'
         WHEN Income < 60000  THEN '2 30-60k'
         WHEN Income < 90000  THEN '3 60-90k'
         WHEN Income < 120000 THEN '4 90-120k'
         ELSE                      '5 120k+' END,
    CASE WHEN InterestRate < 7  THEN '1 2-7%'
         WHEN InterestRate < 12 THEN '2 7-12%'
         WHEN InterestRate < 17 THEN '3 12-17%'
         WHEN InterestRate < 22 THEN '4 17-22%'
         ELSE                        '5 22-25%' END,
    CASE WHEN DTIRatio < 0.3 THEN '1 <0.3'
         WHEN DTIRatio < 0.5 THEN '2 0.3-0.5'
         WHEN DTIRatio < 0.7 THEN '3 0.5-0.7'
         ELSE                     '4 0.7+' END
FROM loans_raw;

CREATE INDEX idx_loans_employment ON loans (employment_type);
CREATE INDEX idx_loans_purpose    ON loans (loan_purpose);
CREATE INDEX idx_loans_age        ON loans (age);

-- name: clean_checks
-- Done-when check: no duplicate IDs, and the default rate matches 11.61%.
SELECT COUNT(*)                            AS n_rows,
       COUNT(*) - COUNT(DISTINCT loan_id)  AS duplicate_ids,
       SUM(is_default)                     AS n_defaults,
       ROUND(100.0 * AVG(is_default), 2)   AS default_rate_pct,
       (SELECT COUNT(*) FROM loans_raw)    AS n_raw_rows
FROM loans;

-- name: clean_band_sizes
-- Every band should be big enough to report a rate on.
SELECT 'credit_band' AS band_type, credit_band AS band, COUNT(*) AS n FROM loans GROUP BY credit_band
UNION ALL SELECT 'age_band',    age_band,    COUNT(*) FROM loans GROUP BY age_band
UNION ALL SELECT 'income_band', income_band, COUNT(*) FROM loans GROUP BY income_band
UNION ALL SELECT 'rate_band',   rate_band,   COUNT(*) FROM loans GROUP BY rate_band
UNION ALL SELECT 'dti_band',    dti_band,    COUNT(*) FROM loans GROUP BY dti_band
ORDER BY band_type, band;
