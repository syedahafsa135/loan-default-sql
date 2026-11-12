/* =====================================================================
   06_basic_purpose_employment.sql  |  Phase 4, basic query 4
   Question : Which loan purposes and employment types default most,
              and which purpose x employment segments are above 14%?
   Concepts : GROUP BY on one and two columns, HAVING on an aggregate
   Takeaway : Employment matters more than purpose. Unemployed
              borrowers default at 13.55% vs 9.46% for full-time;
              purposes only range from 10.23% (Home) to 12.33%
              (Business). Only one purpose x employment segment is
              above 14%: unemployed borrowers taking business loans
              (14.37%, 12,930 loans).
   ===================================================================== */

-- name: q4a_default_by_purpose
SELECT loan_purpose,
       COUNT(*)                          AS loans,
       ROUND(100.0 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY loan_purpose
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct DESC;

-- name: q4b_default_by_employment
SELECT employment_type,
       COUNT(*)                          AS loans,
       ROUND(100.0 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY employment_type
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct DESC;

-- name: q4c_high_risk_segments
-- HAVING filters on the aggregate itself: keep only segments above 14%.
SELECT loan_purpose,
       employment_type,
       COUNT(*)                          AS loans,
       ROUND(100.0 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY loan_purpose, employment_type
HAVING COUNT(*) >= 1000
   AND AVG(is_default) > 0.14
ORDER BY default_rate_pct DESC;
