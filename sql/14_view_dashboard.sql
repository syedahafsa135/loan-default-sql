/* =====================================================================
   14_view_dashboard.sql  |  Phase 7: the table behind the Power BI page
   Question : What single, flat table does the dashboard need?
   Concepts : CREATE VIEW, so the dashboard reads SQL logic instead of
              repeating it in Power BI.
   Takeaway : One row per loan with every band and the red-flag count.
              src/export_powerbi.py writes it to
              powerbi/loans_dashboard.csv.
   ===================================================================== */

DROP VIEW IF EXISTS loans_dashboard;

CREATE VIEW loans_dashboard AS
SELECT loan_id,
       is_default,
       loan_amount,
       income,
       interest_rate,
       credit_score,
       age,
       ROUND(loan_to_income, 2)                                AS loan_to_income,
       credit_band, age_band, income_band, rate_band, dti_band,
       employment_type, loan_purpose, education, loan_term,
       CASE WHEN months_employed < 24 THEN '1 Under 2 years'
            WHEN months_employed < 60 THEN '2 2-5 years'
            ELSE                           '3 5+ years' END       AS job_tenure,
       (age < 30) + (interest_rate >= 18)
     + (loan_to_income >= 3) + (months_employed < 24)          AS red_flags
FROM loans;

-- name: dashboard_view_check
-- Same rows as loans, same defaults.
SELECT COUNT(*) AS n_rows, SUM(is_default) AS n_defaults,
       ROUND(100.0 * AVG(is_default), 2) AS default_rate_pct
FROM loans_dashboard;
