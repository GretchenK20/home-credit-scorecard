with application as (
    select * from read_csv_auto('/Users/gretchenkolthoff/Downloads/home-credit-scorecard/data/raw/application_train.csv')
),
bureau_agg as (
    select * from {{ ref('bureau_agg') }}
),
joined as (
    select
        app.SK_ID_CURR,
        app.TARGET,
        app.EXT_SOURCE_1,
        app.EXT_SOURCE_2,
        app.EXT_SOURCE_3,
        abs(app.DAYS_BIRTH) / 365.25                              as AGE_YEARS,
        case
            when app.DAYS_EMPLOYED = 365243 then null
            else abs(app.DAYS_EMPLOYED) / 365.25
        end                                                        as YEARS_EMPLOYED,
        case when app.DAYS_EMPLOYED = 365243 then 1 else 0 end     as DAYS_EMPLOYED_ANOM,
        app.AMT_CREDIT / nullif(app.AMT_INCOME_TOTAL, 0)          as CREDIT_INCOME_RATIO,
        app.AMT_ANNUITY / nullif(app.AMT_INCOME_TOTAL, 0)         as ANNUITY_INCOME_RATIO,
        app.AMT_CREDIT / nullif(app.AMT_ANNUITY, 0)               as CREDIT_TERM,
        bur.BUREAU_TOTAL_LOANS,
        bur.BUREAU_ACTIVE_COUNT,
        bur.BUREAU_CLOSED_COUNT,
        bur.BUREAU_MEAN_DAYS_CREDIT,
        bur.BUREAU_OVERDUE_AMT,
        bur.BUREAU_TOTAL_DEBT,
        bur.BUREAU_MORTGAGE_FLAG
    from application app
    left join bureau_agg bur on app.SK_ID_CURR = bur.SK_ID_CURR
)
select * from joined
