-- One row per Tigers game, from the Tigers' perspective.
{{ config(materialized='table') }}
select
    game_pk,
    game_date,
    date_key,
    case when home_team_id = 116 then away_team_name else home_team_name end as opponent,
    case when home_team_id = 116 then 'home' else 'away' end                as home_away,
    case when home_team_id = 116 then home_score else away_score end         as tigers_runs,
    case when home_team_id = 116 then away_score else home_score end         as opponent_runs,
    case when (home_team_id = 116 and home_score > away_score)
           or (away_team_id = 116 and away_score > home_score)
         then 1 else 0 end                                                   as is_win,
    (case when home_team_id = 116 then home_score else away_score end)
      - (case when home_team_id = 116 then away_score else home_score end)   as run_diff
from {{ ref('dim_game') }}
where (home_team_id = 116 or away_team_id = 116)
  and status = 'Final'