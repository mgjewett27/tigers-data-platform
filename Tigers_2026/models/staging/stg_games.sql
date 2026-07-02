with source as (select * from {{ source('raw', 'games') }})
select
    game_pk,
    official_date::date  as game_date,
    season::int          as season,
    game_type,
    status,
    away_team_id,
    away_team_name,
    away_score::int      as away_score,
    home_team_id,
    home_team_name,
    home_score::int      as home_score,
    loaded_at
from source