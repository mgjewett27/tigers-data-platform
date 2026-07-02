{{ config(materialized='table') }}
with bounds as (
    select min(game_date) as start_date, max(game_date) as end_date
    from {{ ref('stg_games') }}
),
days as (
    select generate_series(start_date, end_date, interval '1 day')::date as full_date
    from bounds
)
select
    cast(to_char(full_date, 'YYYYMMDD') as int) as date_key,
    full_date,
    extract(year  from full_date)::int as year,
    extract(month from full_date)::int as month,
    extract(day   from full_date)::int as day,
    trim(to_char(full_date, 'Day'))    as day_of_week,
    extract(isodow from full_date) in (6, 7) as is_weekend
from days