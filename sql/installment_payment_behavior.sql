-- Installment Payment Behavior vs Default Rate
-- INST_LATE_RATE is the strongest behavioral signal (IV confirmed in WOE selection)
-- Negative avg_payment_shortfall for on-time payers = overpayment (good signal)
SELECT
    CASE
        WHEN INST_LATE_RATE IS NULL        THEN 'No Installment History'
        WHEN INST_LATE_RATE = 0             THEN 'Never Late'
        WHEN INST_LATE_RATE < 0.10          THEN 'Rarely Late (<10%)'
        WHEN INST_LATE_RATE < 0.25          THEN 'Sometimes Late (10-25%)'
        ELSE 'Frequently Late (25%+)'
    END                                      AS payment_behavior,
    COUNT(*)                                 AS applicants,
    ROUND(AVG(TARGET) * 100, 2)             AS bad_rate_pct,
    ROUND(AVG(INST_MEAN_PAYMENT_DIFF), 4)   AS avg_payment_shortfall
FROM features
GROUP BY payment_behavior
ORDER BY bad_rate_pct DESC;