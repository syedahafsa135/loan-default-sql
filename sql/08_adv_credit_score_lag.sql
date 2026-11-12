/* =====================================================================
   08_adv_credit_score_lag.sql  |  Phase 5, advanced query 2
   Question : Along the credit score scale, in 50-point steps, where
              does default risk fall fastest, and what share of all
              defaults sits below each score?
   Concepts : CTE, LAG, running SUM() OVER (cumulative share)
   Takeaway : There is no cliff. Default falls in small steps (never
              more than 0.71 points per 50 points of score), from 13.67%
              at 300-349 to 9.81% at 800-849. Scores below 550 hold
              45.5% of loans and 49.4% of defaults, barely more than
              their share. A cut-off on credit score alone would
              reject many good borrowers for little gain.
   ===================================================================== */

-- name: q6_credit_score_steps
WITH buckets AS (
    SELECT (credit_score / 50) * 50     AS score_from,   -- 300, 350, ... 800
           COUNT(*)                     AS loans,
           SUM(is_default)              AS defaults
    FROM loans
    GROUP BY score_from
)
SELECT score_from,
       score_from + 49                                                  AS score_to,
       loans,
       ROUND(100.0 * defaults / loans, 2)                               AS default_rate_pct,
       ROUND(100.0 * defaults / loans
             - LAG(100.0 * defaults / loans) OVER (ORDER BY score_from), 2) AS change_vs_prev_pp,
       -- running share of all defaults, lowest scores first
       ROUND(100.0 * SUM(defaults) OVER (ORDER BY score_from)
                   / SUM(defaults) OVER (), 1)                          AS cum_share_of_defaults_pct,
       ROUND(100.0 * SUM(loans) OVER (ORDER BY score_from)
                   / SUM(loans) OVER (), 1)                             AS cum_share_of_loans_pct
FROM buckets
ORDER BY score_from;
