/* =====================================================================
   04_basic_income_band.sql  |  Phase 4, basic query 2
   Question : How does default rate change with income, and does a
              bigger loan relative to income make it worse?
   Concepts : GROUP BY, HAVING, conditional aggregation
   Takeaway : Borrowers earning under 30k default at 21.96%, more than
              twice the 9.03% of those on 120k+. But inside every
              income band, loans up to 2x income default at about 9%
              (8.69-9.36%). The risk comes from borrowing a lot
              relative to income (24.37% when the loan is over 2x
              income in the <30k band), not from low income itself.
   ===================================================================== */

-- name: q2_default_by_income_band
SELECT income_band,
       COUNT(*)                                       AS loans,
       ROUND(100.0 * AVG(is_default), 2)              AS default_rate_pct,
       ROUND(AVG(loan_to_income), 2)                  AS avg_loan_to_income,
       -- same band, split by whether the loan is more than 2x annual income
       ROUND(100.0 * AVG(CASE WHEN loan_to_income >  2 THEN is_default END), 2) AS rate_loan_over_2x_income,
       ROUND(100.0 * AVG(CASE WHEN loan_to_income <= 2 THEN is_default END), 2) AS rate_loan_up_to_2x_income
FROM loans
GROUP BY income_band
HAVING COUNT(*) >= 1000
ORDER BY income_band;
