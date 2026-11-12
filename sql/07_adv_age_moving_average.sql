/* =====================================================================
   07_adv_age_moving_average.sql  |  Phase 5, advanced query 1
   Question : How does default risk change with each year of age, once
              the year-to-year noise is smoothed out?
   Concepts : CTE, window AVG with a ROWS frame (moving average),
              LAG for year-on-year change.
   Note     : The data has no dates, so this "moving average" runs over
              age, an ordered dimension, not over time.
   Takeaway : Age is the strongest single signal in the data. The
              smoothed rate falls almost every year, from 22.2% at 18
              to 4.6% at 69, nearly five times lower. Single years jump
              by up to 3.4 points, which is why the moving average is
              the better line to read.
   ===================================================================== */

-- name: q5_age_moving_average
WITH by_age AS (
    SELECT age,
           COUNT(*)                    AS loans,
           AVG(is_default)             AS rate
    FROM loans
    GROUP BY age
)
SELECT age,
       loans,
       ROUND(100 * rate, 2)                                            AS default_rate_pct,
       -- centred 5-year moving average: 2 ages either side
       ROUND(100 * AVG(rate) OVER (ORDER BY age
                                   ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING), 2) AS moving_avg_5yr_pct,
       -- change from the previous age, in percentage points
       ROUND(100 * (rate - LAG(rate) OVER (ORDER BY age)), 2)          AS change_vs_prev_age_pp
FROM by_age
ORDER BY age;
