/* =====================================================================
   12_adv_cohort_matrix.sql  |  Phase 5, advanced query 6
   Question : How do age and time in the current job combine? A
              cohort matrix: rows are age bands, columns are years in
              the job.
   Concepts : CTE, pivot with conditional aggregation, window MAX/MIN
              across a row.
   Note     : A true vintage analysis (default rate by when a loan
              was issued) needs an origination date. This dataset has
              none, so this borrower-cohort matrix stands in for it.
   Takeaway : Age and job tenure add up rather than cancel out. In
              every age band, borrowers under 2 years into their job
              default more than those with 5+ years, and the gap is
              widest for the young (12.85 points at 18-24, 3.73 at
              65-69). The extremes: 28.78% for 18-24s under 2 years in
              the job vs 3.47% for 65-69s with 5+ years.
   ===================================================================== */

-- name: q10_age_by_job_tenure_matrix
WITH cohorts AS (
    SELECT age_band,
           CASE WHEN months_employed < 24 THEN 'job_0_2y'
                WHEN months_employed < 60 THEN 'job_2_5y'
                ELSE                           'job_5y_plus' END AS tenure,
           is_default
    FROM loans
),
matrix AS (
    SELECT age_band,
           COUNT(*) AS loans,
           ROUND(100.0 * AVG(CASE WHEN tenure = 'job_0_2y'    THEN is_default END), 2) AS job_0_2y_pct,
           ROUND(100.0 * AVG(CASE WHEN tenure = 'job_2_5y'    THEN is_default END), 2) AS job_2_5y_pct,
           ROUND(100.0 * AVG(CASE WHEN tenure = 'job_5y_plus' THEN is_default END), 2) AS job_5y_plus_pct,
           ROUND(100.0 * AVG(is_default), 2)                                           AS all_tenures_pct
    FROM cohorts
    GROUP BY age_band
)
SELECT matrix.*,
       ROUND(job_0_2y_pct - job_5y_plus_pct, 2)                AS tenure_gap_pp,
       MAX(all_tenures_pct) OVER () - MIN(all_tenures_pct) OVER () AS age_band_spread_pp
FROM matrix
ORDER BY age_band;
