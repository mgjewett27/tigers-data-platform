-- mart_pitching_season: one row per player, Tigers games only (team_id = 116)
-- innings_pitched is baseball notation (.1=1/3, .2=2/3) -> convert to outs first.
with per_game as (
    select
        player_id,
        game_pk,
        (floor(innings_pitched) * 3
            + round((innings_pitched - floor(innings_pitched)) * 10))::int as outs,
        earned_runs, walks, hits, strikeouts, wins, losses, saves
    from {{ ref('fact_pitching') }}
    where team_id = 116
),
totals as (
    select
        player_id,
        count(distinct game_pk)   as g,
        sum(outs)                 as outs,
        sum(outs) / 3.0           as true_ip,
        sum(earned_runs)          as er,
        sum(walks)                as bb,
        sum(hits)                 as h,
        sum(strikeouts)           as so,
        sum(wins)                 as w,
        sum(losses)               as l,
        sum(saves)                as sv
    from per_game
    group by player_id
)
select
    t.player_id,
    p.player_name,
    t.g,
    (t.outs / 3) + (t.outs % 3) * 0.1              as ip_display,
    round(t.true_ip, 2)                            as true_ip,
    t.w, t.l, t.sv, t.so, t.bb, t.er,
    round(9 * t.er / nullif(t.true_ip, 0), 2)      as era,
    round((t.bb + t.h) / nullif(t.true_ip, 0), 2)  as whip,
    round(9 * t.so / nullif(t.true_ip, 0), 2)      as k9
from totals t
left join {{ ref('dim_player') }} p
    on p.player_id = t.player_id and p.is_current