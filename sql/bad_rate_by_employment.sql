-- Bad Rate by Employment Status
-- Validates DAYS_EMPLOYED anomaly identified in EDA (pensioners default at 5.40% vs 8.66% employed)
SELECT
    CASE WHEN DAYS_EMPLOYED_ANOM = 1 THEN 'Pensioner / Non-employed'
         ELSE 'Employed'
    END                                         AS employment_status,
    COUNT(*)                                    AS applicants,
    SUM(TARGET)                                 AS bads,
    ROUND(AVG(TARGET) * 100, 2)                AS bad_rate_pct,
    ROUND(AVG(YEARS_EMPLOYED), 1)              AS avg_years_employed
FROM features
GROUP BY DAYS_EMPLOYED_ANOM
ORDER BY bad_rate_pct DESC;