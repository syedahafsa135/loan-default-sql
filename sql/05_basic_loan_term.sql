/* =====================================================================
   05_basic_loan_term.sql  |  Phase 4, basic query 3
   Question : Are longer loans riskier?
   Concepts : GROUP BY, HAVING, MIN/MAX inside groups
   Takeaway : No. Every term from 12 to 60 months defaults at
              11.57-11.70%, with the same average rate and amount.
              Term carries no risk signal here, which matches it being
              a weak attribute in the earlier feature selection.
   ===================================================================== */

-- name: q3_default_by_loan_term
SELECT loan_term                               AS term_months,
       COUNT(*)                                AS loans,
       ROUND(100.0 * AVG(is_default), 2)       AS default_rate_pct,
       ROUND(AVG(interest_rate), 2)            AS avg_interest_rate,
       ROUND(AVG(loan_amount))                 AS avg_loan_amount
FROM loans
GROUP BY loan_term
HAVING COUNT(*) >= 1000
ORDER BY loan_term;
