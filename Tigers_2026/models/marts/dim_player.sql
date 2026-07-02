{{ config(materialized='table') }}
select
    row_number() over (order by player_id, dbt_valid_from) as player_key,
    player_id,
    player_name,
    current_team_id         as team_id,
    position,
    dbt_valid_from          as valid_from,
    dbt_valid_to            as valid_to,
    (dbt_valid_to is null)  as is_current
from {{ ref('player_snapshot') }}