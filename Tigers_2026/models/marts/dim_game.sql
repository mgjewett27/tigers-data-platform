{{ config(materialized='table') }}
select
    game_pk,
    game_date,
    cast(to_char(game_date, 'YYYYMMDD') as int) as date_key,
    season,
    game_type,
    status,
    away_team_id,
    away_team_name,
    away_score,
    home_team_id,
    home_team_name,
    home_score,
    case when home_score > away_score then home_team_id else away_team_id end as winning_team_id
from {{ ref('stg_games') }}