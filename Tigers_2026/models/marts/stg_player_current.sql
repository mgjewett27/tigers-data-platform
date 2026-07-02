with appearances as (
    select player_id, player_name, team_id, position, game_date from {{ ref('stg_batting') }}
    union all
    select player_id, player_name, team_id, position, game_date from {{ ref('stg_pitching') }}
),
ranked as (
    select *, row_number() over (partition by player_id order by game_date desc) as rn
    from appearances
)
select player_id, player_name, team_id as current_team_id, position
from ranked
where rn = 1