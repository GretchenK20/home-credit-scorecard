with bureau as (
    select * from {{ ref('stg_bureau') }}
),
aggregated as (
    select
        SK_ID_CURR,
        count(SK_ID_BUREAU)                                        as BUREAU_TOTAL_LOANS,
        sum(case when CREDIT_ACTIVE = 'Active' then 1 else 0 end) as BUREAU_ACTIVE_COUNT,
        sum(case when CREDIT_ACTIVE = 'Closed' then 1 else 0 end) as BUREAU_CLOSED_COUNT,
        avg(DAYS_CREDIT)                                           as BUREAU_MEAN_DAYS_CREDIT,
        sum(AMT_CREDIT_SUM_OVERDUE)                                as BUREAU_OVERDUE_AMT,
        sum(AMT_CREDIT_SUM_DEBT)                                   as BUREAU_TOTAL_DEBT,
        max(case when CREDIT_TYPE = 'Mortgage' then 1 else 0 end)  as BUREAU_MORTGAGE_FLAG
    from bureau
    group by SK_ID_CURR
)
select * from aggregated
