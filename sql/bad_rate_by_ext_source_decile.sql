-- Bad Rate by EXT_SOURCE_WEIGHTED Decile
-- Near-perfectly monotonic: decile 1 = 22.99% bad rate, decile 10 = ~2% bad rate
-- EXT_SOURCE_WEIGHTED is the strongest predictor (IV = 0.6292)
WITH deciles AS (
    SELECT
        TARGET,
        EXT_SOURCE_WEIGHTED,
        NTILE(10) OVER (ORDER BY EXT_SOURCE_WEIGHTED ASC) AS decile
    FROM features
    WHERE EXT_SOURCE_WEIGHTED IS NOT NULL
)
SELECT
    decile,
    COUNT(*)                            AS applicants,
    SUM(TARGET)                         AS bads,
    ROUND(AVG(TARGET) * 100, 2)        AS bad_rate_pct,
    ROUND(MIN(EXT_SOURCE_WEIGHTED), 4) AS score_min,
    ROUND(MAX(EXT_SOURCE_WEIGHTED), 4) AS score_max
FROM deciles
GROUP BY decile
ORDER BY decile ASC;