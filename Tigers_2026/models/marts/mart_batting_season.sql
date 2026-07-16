-- mart_batting_season: one row per player, Tigers games only (team_id = 116)
with batting as (
    select
        player_id,
        count(distinct game_pk)  as g,
        sum(at_bats)             as ab,
        sum(hits)                as h,
        sum(walks)               as bb,
        sum(hit_by_pitch)        as hbp,
        sum(sac_flies)           as sf,
        sum(total_bases)         as tb,
        sum(home_runs)           as hr,
        sum(rbi)                 as rbi,
        sum(runs)                as r,
        sum(strikeouts)          as so,
        sum(stolen_bases)        as sb
    from {{ ref('fact_batting') }}
    where team_id = 116
    group by player_id
),
rates as (
    select
        *,
        h::numeric / nullif(ab, 0)                              as avg,
        (h + bb + hbp)::numeric / nullif(ab + bb + hbp + sf, 0) as obp,
        tb::numeric / nullif(ab, 0)                             as slg
    from batting
)
select
    r.player_id,
    p.player_name,
    r.g, r.ab, r.h, r.hr, r.rbi, r.r, r.bb, r.so, r.sb,
    round(r.avg, 3)         as avg,
    round(r.obp, 3)         as obp,
    round(r.slg, 3)         as slg,
    round(r.obp + r.slg, 3) as ops
from rates r
left join {{ ref('dim_player') }} p
    on p.player_id = r.player_id and p.is_current