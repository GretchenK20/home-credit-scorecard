with source as (
    select * from read_csv_auto('/Users/gretchenkolthoff/Downloads/home-credit-scorecard/data/raw/bureau.csv')
),
renamed as (
    select
        SK_ID_CURR,
        SK_ID_BUREAU,
        CREDIT_ACTIVE,
        DAYS_CREDIT,
        AMT_CREDIT_SUM,
        AMT_CREDIT_SUM_DEBT,
        AMT_CREDIT_SUM_OVERDUE,
        CREDIT_TYPE
    from source
)
select * from renamed
