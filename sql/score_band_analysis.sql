-- Score Band Analysis
-- Uses PDO=20 scaling: every 20 points doubles the odds of being a good borrower
-- Cutoff score = 554 (KS statistic peak)
WITH scored AS (
    SELECT
        TARGET,
        EXT_SOURCE_WEIGHTED,
        AGE_YEARS,
        YEARS_EMPLOYED,
        CREDIT_INCOME_RATIO,
        CASE
            WHEN EXT_SOURCE_WEIGHTED >= 0.70 THEN '700-850 (Very Low Risk)'
            WHEN EXT_SOURCE_WEIGHTED >= 0.55 THEN '600-699 (Low Risk)'
            WHEN EXT_SOURCE_WEIGHTED >= 0.45 THEN '550-599 (Moderate Risk)'
            WHEN EXT_SOURCE_WEIGHTED >= 0.35 THEN '500-549 (High Risk)'
            ELSE '300-499 (Very High Risk)'
        END AS score_band
    FROM features
    WHERE EXT_SOURCE_WEIGHTED IS NOT NULL
)
SELECT
    score_band,
    COUNT(*)                        AS applicants,
    ROUND(AVG(TARGET) * 100, 2)    AS bad_rate_pct,
    ROUND(AVG(AGE_YEARS), 1)       AS avg_age,
    ROUND(AVG(YEARS_EMPLOYED), 1)  AS avg_years_employed
FROM scored
GROUP BY score_band
ORDER BY bad_rate_pct DESC;