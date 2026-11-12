/* =====================================================================
   09_adv_ntile_deciles.sql  |  Phase 5, advanced query 3
   Question : If loans are sorted into ten equal groups by interest
              rate (and, separately, by loan-to-income), how much of
              the default risk sits in the top groups?
   Concepts : NTILE(10), CTE chain, cumulative SUM() OVER for a gains
              table (the share of defaults captured from the top down).
   Takeaway : Interest rate ranks risk smoothly. The top-rate decile
              (22.71-25%) defaults at 19.02% against 5.76% for the
              lowest, and the top three deciles hold 44.0% of defaults.
              Loan-to-income behaves differently: the risk is packed
              into the top decile (loan 4.8x income or more, 25.90%,
              22.3% of all defaults), and it is fairly flat below that.
   ===================================================================== */

-- name: q7a_interest_rate_deciles
WITH ranked AS (
    SELECT is_default,
           interest_rate,
           NTILE(10) OVER (ORDER BY interest_rate DESC, loan_id) AS decile   -- 1 = highest rates
    FROM loans
),
per_decile AS (
    SELECT decile,
           COUNT(*)                AS loans,
           SUM(is_default)         AS defaults,
           MIN(interest_rate)      AS rate_from,
           MAX(interest_rate)      AS rate_to
    FROM ranked
    GROUP BY decile
)
SELECT decile,
       rate_from, rate_to,
       loans,
       ROUND(100.0 * defaults / loans, 2)                                  AS default_rate_pct,
       ROUND(100.0 * SUM(defaults) OVER (ORDER BY decile) / SUM(defaults) OVER (), 1)
                                                                           AS cum_defaults_captured_pct
FROM per_decile
ORDER BY decile;

-- name: q7b_loan_to_income_deciles
WITH ranked AS (
    SELECT is_default,
           loan_to_income,
           NTILE(10) OVER (ORDER BY loan_to_income DESC, loan_id) AS decile  -- 1 = biggest loans vs income
    FROM loans
),
per_decile AS (
    SELECT decile,
           COUNT(*)                         AS loans,
           SUM(is_default)                  AS defaults,
           ROUND(MIN(loan_to_income), 2)    AS lti_from,
           ROUND(MAX(loan_to_income), 2)    AS lti_to
    FROM ranked
    GROUP BY decile
)
SELECT decile,
       lti_from, lti_to,
       loans,
       ROUND(100.0 * defaults / loans, 2)                                  AS default_rate_pct,
       ROUND(100.0 * SUM(defaults) OVER (ORDER BY decile) / SUM(defaults) OVER (), 1)
                                                                           AS cum_defaults_captured_pct
FROM per_decile
ORDER BY decile;
