/* =====================================================================
   10_adv_rank_partition.sql  |  Phase 5, advanced query 4
   Question : Within each employment type, which loan purpose is the
              riskiest, and how far is it above that group's average?
   Concepts : CTE, RANK() OVER (PARTITION BY ...), window AVG per
              partition, filtering on a window result.
   Takeaway : The ordering is the same in every group: Business loans
              rank riskiest and Home loans safest for all four
              employment types. The gaps are small (+0.5 to +0.9 points
              above the group rate for Business, -1.0 to -1.7 for Home),
              so purpose adjusts risk but doesn't drive it.
   ===================================================================== */

-- name: q8_purpose_rank_within_employment
WITH seg AS (
    SELECT employment_type,
           loan_purpose,
           COUNT(*)            AS loans,
           SUM(is_default)     AS defaults,
           AVG(is_default)     AS rate
    FROM loans
    GROUP BY employment_type, loan_purpose
),
ranked AS (
    SELECT seg.*,
           RANK() OVER (PARTITION BY employment_type ORDER BY rate DESC) AS rank_in_group,
           -- loan-weighted group rate, so it equals the employment type's real rate
           SUM(defaults) OVER (PARTITION BY employment_type) * 1.0
         / SUM(loans)    OVER (PARTITION BY employment_type)              AS group_rate
    FROM seg
)
SELECT employment_type,
       rank_in_group,
       loan_purpose,
       loans,
       ROUND(100 * rate, 2)                AS default_rate_pct,
       ROUND(100 * group_rate, 2)          AS employment_type_rate_pct,
       ROUND(100 * (rate - group_rate), 2) AS gap_pp
FROM ranked
WHERE rank_in_group IN (1, 5)             -- riskiest and safest purpose per group
ORDER BY employment_type_rate_pct DESC, rank_in_group;
