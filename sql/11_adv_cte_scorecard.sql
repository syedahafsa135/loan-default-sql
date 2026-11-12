/* =====================================================================
   11_adv_cte_scorecard.sql  |  Phase 5, advanced query 5
   Question : A loan officer can't run a model. If we flag the four
              attributes the model comparison found most important
              (Age, InterestRate, LoanToIncome, MonthsEmployed), how
              well does a simple count of red flags separate risk?
   Concepts : multi-step CTE chain, CASE flags, window SUM for share of
              loans and share of defaults.
   Flags    : thresholds are simple round numbers chosen after looking
              at queries 07 and 09. This is a descriptive rule of
              thumb, not a tested model.
                 age < 30
                 interest_rate >= 18
                 loan_to_income >= 3
                 months_employed < 24
   Takeaway : Each extra flag roughly doubles the default rate: 4.94%
              with no flags, 10.45%, 20.37%, 34.58%, then 53.17% with all
              four. Loans with two or more flags are 23.8% of the book
              but hold 47.4% of defaults. A third of loans (no flags)
              default at under 5%.
   ===================================================================== */

-- name: q9_red_flag_scorecard
WITH flags AS (
    SELECT is_default,
           (age < 30)               AS f_young,
           (interest_rate >= 18)    AS f_high_rate,
           (loan_to_income >= 3)    AS f_high_lti,
           (months_employed < 24)   AS f_short_job
    FROM loans
),
scored AS (
    SELECT is_default,
           f_young + f_high_rate + f_high_lti + f_short_job AS red_flags
    FROM flags
),
summary AS (
    SELECT red_flags,
           COUNT(*)          AS loans,
           SUM(is_default)   AS defaults
    FROM scored
    GROUP BY red_flags
)
SELECT red_flags,
       loans,
       ROUND(100.0 * defaults / loans, 2)                       AS default_rate_pct,
       ROUND(100.0 * loans    / SUM(loans)    OVER (), 1)       AS share_of_loans_pct,
       ROUND(100.0 * defaults / SUM(defaults) OVER (), 1)       AS share_of_defaults_pct
FROM summary
ORDER BY red_flags;
