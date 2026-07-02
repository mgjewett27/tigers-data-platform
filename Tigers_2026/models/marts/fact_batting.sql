{{ config(materialized='table') }}
select
    game_pk,
    cast(to_char(game_date, 'YYYYMMDD') as int) as date_key,
    team_id,
    player_id,
    at_bats, runs, hits, doubles, triples, home_runs, rbi,
    walks, intentional_walks, strikeouts, hit_by_pitch,
    stolen_bases, caught_stealing, gidp, plate_appearances,
    total_bases, left_on_base, sac_bunts, sac_flies
from {{ ref('stg_batting') }}