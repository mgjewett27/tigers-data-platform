{{ config(materialized='table') }}
select
    game_pk,
    cast(to_char(game_date, 'YYYYMMDD') as int) as date_key,
    team_id,
    player_id,
    innings_pitched, hits, runs, earned_runs, home_runs,
    walks, intentional_walks, strikeouts, hit_by_pitch,
    batters_faced, pitches, strikes, balls,
    wins, losses, saves, holds, blown_saves
from {{ ref('stg_pitching') }}