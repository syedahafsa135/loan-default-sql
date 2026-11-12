/* =====================================================================
   13_adv_pareto_segments.sql  |  Phase 5, advanced query 7
   Question : Split the book into segments (age band x employment type
              x income band). Ranked from riskiest down, how few
              segments hold half of all defaults?
   Concepts : CTE, DENSE_RANK, running SUM() OVER for a Pareto curve,
              filtering on a running total.
   Takeaway : Risk is concentrated but not extreme. The riskiest 40 of
              120 segments hold half of all defaults while making up
              28.6% of loans. The top segment (18-24, unemployed, under
              30k) defaults at 40.04%. Young, low-income borrowers fill
              the top of the list whatever their employment type.
   ===================================================================== */

-- name: q11_pareto_segments
WITH seg AS (
    SELECT age_band, employment_type, income_band,
           COUNT(*)          AS loans,
           SUM(is_default)   AS defaults,
           AVG(is_default)   AS rate
    FROM loans
    GROUP BY age_band, employment_type, income_band
    HAVING COUNT(*) >= 500
),
pareto AS (
    SELECT seg.*,
           DENSE_RANK() OVER (ORDER BY rate DESC)                                  AS risk_rank,
           SUM(loans)    OVER (ORDER BY rate DESC ROWS UNBOUNDED PRECEDING) * 1.0
         / (SELECT COUNT(*) FROM loans)                                            AS cum_loan_share,
           SUM(defaults) OVER (ORDER BY rate DESC ROWS UNBOUNDED PRECEDING) * 1.0
         / (SELECT SUM(is_default) FROM loans)                                     AS cum_default_share
    FROM seg
)
SELECT risk_rank, age_band, employment_type, income_band, loans,
       ROUND(100 * rate, 2)              AS default_rate_pct,
       ROUND(100 * cum_loan_share, 1)    AS cum_share_of_loans_pct,
       ROUND(100 * cum_default_share, 1) AS cum_share_of_defaults_pct
FROM pareto
WHERE cum_default_share <= 0.55           -- show the segments up to ~half of defaults
ORDER BY risk_rank;

-- name: q11b_pareto_summary
-- How many segments in total, and how many to reach 50% of defaults?
WITH seg AS (
    SELECT COUNT(*) AS loans, SUM(is_default) AS defaults, AVG(is_default) AS rate
    FROM loans
    GROUP BY age_band, employment_type, income_band
    HAVING COUNT(*) >= 500
),
pareto AS (
    SELECT loans, defaults,
           SUM(defaults) OVER (ORDER BY rate DESC ROWS UNBOUNDED PRECEDING) * 1.0
         / (SELECT SUM(is_default) FROM loans) AS cum_default_share,
           SUM(loans)    OVER (ORDER BY rate DESC ROWS UNBOUNDED PRECEDING) * 1.0
         / (SELECT COUNT(*) FROM loans)        AS cum_loan_share
    FROM seg
)
SELECT (SELECT COUNT(*) FROM seg)                                  AS total_segments,
       (SELECT SUM(loans) FROM seg)                                AS loans_in_segments,
       COUNT(*) + 1                                                AS segments_to_half_of_defaults,
       ROUND(100 * (SELECT MIN(cum_loan_share) FROM pareto WHERE cum_default_share >= 0.5), 1)
                                                                   AS share_of_loans_at_that_point_pct
FROM pareto
WHERE cum_default_share < 0.5;
