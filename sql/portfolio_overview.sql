-- Portfolio Overview
-- Equivalent Snowflake query: SELECT * FROM feature_mart.portfolio_overview
SELECT
    COUNT(*)                                    AS total_applicants,
    SUM(TARGET)                                 AS total_bads,
    ROUND(AVG(TARGET) * 100, 2)                AS bad_rate_pct,
    ROUND(AVG(EXT_SOURCE_WEIGHTED), 4)         AS avg_ext_source_weighted,
    ROUND(AVG(AGE_YEARS), 1)                   AS avg_age_years,
    ROUND(AVG(YEARS_EMPLOYED), 1)              AS avg_years_employed,
    ROUND(AVG(CREDIT_INCOME_RATIO), 2)         AS avg_credit_income_ratio,
    ROUND(AVG(ANNUITY_INCOME_RATIO), 4)        AS avg_annuity_income_ratio
FROM features;