/* =====================================================================
   01_audit.sql  |  Phase 2: data audit of loans_raw
   Question : Is the raw table complete, unique and within sensible
              ranges, and how is the target ("Default") coded?
   Takeaway : see notes.md (filled in from these results).
   ===================================================================== */

-- name: audit_row_and_id_counts
-- Every row should have its own LoanID.
SELECT COUNT(*)                         AS n_rows,
       COUNT(DISTINCT LoanID)           AS n_distinct_ids,
       COUNT(*) - COUNT(DISTINCT LoanID) AS duplicate_ids
FROM loans_raw;

-- name: audit_full_row_duplicates
-- Rows identical on every column except the ID.
SELECT COUNT(*) AS duplicated_rows
FROM (
    SELECT COUNT(*) AS c
    FROM loans_raw
    GROUP BY Age, Income, LoanAmount, CreditScore, MonthsEmployed, NumCreditLines,
             InterestRate, LoanTerm, DTIRatio, Education, EmploymentType,
             MaritalStatus, HasMortgage, HasDependents, LoanPurpose, HasCoSigner, "Default"
    HAVING COUNT(*) > 1
);

-- name: audit_nulls
-- NULL count per column (a blank in the CSV loads as NULL).
SELECT SUM(LoanID IS NULL)         AS LoanID,         SUM(Age IS NULL)            AS Age,
       SUM(Income IS NULL)         AS Income,         SUM(LoanAmount IS NULL)     AS LoanAmount,
       SUM(CreditScore IS NULL)    AS CreditScore,    SUM(MonthsEmployed IS NULL) AS MonthsEmployed,
       SUM(NumCreditLines IS NULL) AS NumCreditLines, SUM(InterestRate IS NULL)   AS InterestRate,
       SUM(LoanTerm IS NULL)       AS LoanTerm,       SUM(DTIRatio IS NULL)       AS DTIRatio,
       SUM(Education IS NULL)      AS Education,      SUM(EmploymentType IS NULL) AS EmploymentType,
       SUM(MaritalStatus IS NULL)  AS MaritalStatus,  SUM(HasMortgage IS NULL)    AS HasMortgage,
       SUM(HasDependents IS NULL)  AS HasDependents,  SUM(LoanPurpose IS NULL)    AS LoanPurpose,
       SUM(HasCoSigner IS NULL)    AS HasCoSigner,    SUM("Default" IS NULL)        AS Default_
FROM loans_raw;

-- name: audit_numeric_ranges
-- Min / max / mean of each numeric column, one row per column.
SELECT 'Age' AS col, MIN(Age) AS min_v, MAX(Age) AS max_v, ROUND(AVG(Age), 2) AS mean_v FROM loans_raw
UNION ALL SELECT 'Income', MIN(Income), MAX(Income), ROUND(AVG(Income), 2) FROM loans_raw
UNION ALL SELECT 'LoanAmount', MIN(LoanAmount), MAX(LoanAmount), ROUND(AVG(LoanAmount), 2) FROM loans_raw
UNION ALL SELECT 'CreditScore', MIN(CreditScore), MAX(CreditScore), ROUND(AVG(CreditScore), 2) FROM loans_raw
UNION ALL SELECT 'MonthsEmployed', MIN(MonthsEmployed), MAX(MonthsEmployed), ROUND(AVG(MonthsEmployed), 2) FROM loans_raw
UNION ALL SELECT 'NumCreditLines', MIN(NumCreditLines), MAX(NumCreditLines), ROUND(AVG(NumCreditLines), 2) FROM loans_raw
UNION ALL SELECT 'InterestRate', MIN(InterestRate), MAX(InterestRate), ROUND(AVG(InterestRate), 2) FROM loans_raw
UNION ALL SELECT 'LoanTerm', MIN(LoanTerm), MAX(LoanTerm), ROUND(AVG(LoanTerm), 2) FROM loans_raw
UNION ALL SELECT 'DTIRatio', MIN(DTIRatio), MAX(DTIRatio), ROUND(AVG(DTIRatio), 3) FROM loans_raw;

-- name: audit_employment_vs_age
-- Can MonthsEmployed exceed a working life that starts at 16?
-- (Part 1 of the data science project capped these at (Age - 16) * 12.)
SELECT SUM(MonthsEmployed > (Age - 16) * 12) AS over_working_life,
       ROUND(100.0 * SUM(MonthsEmployed > (Age - 16) * 12) / COUNT(*), 2) AS pct_rows
FROM loans_raw;

-- name: audit_categorical_levels
-- Distinct levels of every text column, with counts.
SELECT 'Education' AS col, Education AS level, COUNT(*) AS n FROM loans_raw GROUP BY Education
UNION ALL SELECT 'EmploymentType', EmploymentType, COUNT(*) FROM loans_raw GROUP BY EmploymentType
UNION ALL SELECT 'MaritalStatus', MaritalStatus, COUNT(*) FROM loans_raw GROUP BY MaritalStatus
UNION ALL SELECT 'HasMortgage', HasMortgage, COUNT(*) FROM loans_raw GROUP BY HasMortgage
UNION ALL SELECT 'HasDependents', HasDependents, COUNT(*) FROM loans_raw GROUP BY HasDependents
UNION ALL SELECT 'LoanPurpose', LoanPurpose, COUNT(*) FROM loans_raw GROUP BY LoanPurpose
UNION ALL SELECT 'HasCoSigner', HasCoSigner, COUNT(*) FROM loans_raw GROUP BY HasCoSigner
UNION ALL SELECT 'LoanTerm', CAST(LoanTerm AS TEXT), COUNT(*) FROM loans_raw GROUP BY LoanTerm
ORDER BY col, level;

-- name: audit_target
-- How is "Default" coded, and what is the base rate?
SELECT "Default" AS default_flag,
       COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM loans_raw
GROUP BY "Default";
