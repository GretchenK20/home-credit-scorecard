-- Bureau Risk Segmentation
-- Segments applicants by number of active credit obligations
SELECT
    CASE
        WHEN BUREAU_ACTIVE_COUNT IS NULL         THEN 'No Bureau History'
        WHEN BUREAU_ACTIVE_COUNT = 0              THEN 'No Active Loans'
        WHEN BUREAU_ACTIVE_COUNT BETWEEN 1 AND 2  THEN '1-2 Active Loans'
        WHEN BUREAU_ACTIVE_COUNT BETWEEN 3 AND 5  THEN '3-5 Active Loans'
        ELSE '6+ Active Loans'
    END                                           AS bureau_segment,
    COUNT(*)                                      AS applicants,
    ROUND(AVG(TARGET) * 100, 2)                  AS bad_rate_pct,
    ROUND(AVG(BUREAU_MEAN_DAYS_CREDIT), 0)       AS avg_days_since_credit
FROM features
GROUP BY bureau_segment
ORDER BY bad_rate_pct DESC;