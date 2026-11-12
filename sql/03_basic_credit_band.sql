/* =====================================================================
   03_basic_credit_band.sql  |  Phase 4, basic query 1
   Question : Do borrowers with lower credit scores default more?
   Concepts : GROUP BY, HAVING, a scalar subquery for the overall rate
   Takeaway : Yes, but only gently. Default falls steadily from 12.47%
              (Poor) to 9.81% (Exceptional), a lift of 1.07 vs 0.85.
              Half of all loans (130,223) sit in the Poor band, so
              credit score alone separates risk weakly in this data.
   ===================================================================== */

-- name: q1_default_by_credit_band
SELECT credit_band,
       COUNT(*)                                     AS loans,
       SUM(is_default)                              AS defaults,
       ROUND(100.0 * AVG(is_default), 2)            AS default_rate_pct,
       ROUND(AVG(is_default) / (SELECT AVG(is_default) FROM loans), 2) AS lift_vs_overall
FROM loans
GROUP BY credit_band
HAVING COUNT(*) >= 1000          -- only report bands big enough to trust
ORDER BY credit_band;
