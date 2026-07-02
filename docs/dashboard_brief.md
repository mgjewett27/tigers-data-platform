# Dashboard Design Brief — Tigers 2026

Spec for the Metabase layer. Dashboards filter to the Tigers (`team_id = 116`) unless noted.

## Prereq: season-totals marts (build in dbt so the logic is version-controlled)

Rate stats come from aggregating the per-game facts. Two new marts:

### mart_batting_season  (one row per player; Tigers games only)
From `fact_batting` where `team_id = 116`, group by `player_id`:
- g = count(distinct game_pk); ab=sum(at_bats); h=sum(hits); bb=sum(walks);
  hbp=sum(hit_by_pitch); sf=sum(sac_flies); tb=sum(total_bases);
  hr=sum(home_runs); rbi=sum(rbi); r=sum(runs); so=sum(strikeouts); sb=sum(stolen_bases)
- AVG = h / nullif(ab,0)
- OBP = (h + bb + hbp) / nullif(ab + bb + hbp + sf, 0)
- SLG = tb / nullif(ab,0)
- OPS = OBP + SLG
- (join dim_player on player_id AND is_current for the name)

### mart_pitching_season  (one row per player; Tigers games only)
From `fact_pitching` where `team_id = 116`, group by `player_id`:
- FIRST convert innings_pitched from baseball notation to outs:
    outs = floor(ip)*3 + round((ip - floor(ip)) * 10)
    true_ip = sum(outs) / 3.0
- er=sum(earned_runs); bb=sum(walks); h=sum(hits); so=sum(strikeouts);
  w=sum(wins); l=sum(losses); sv=sum(saves)
- ERA  = 9 * er / nullif(true_ip, 0)
- WHIP = (bb + h) / nullif(true_ip, 0)
- K9   = 9 * so / nullif(true_ip, 0)

> GOTCHA: innings_pitched uses baseball notation where .1 = 1/3 inning, .2 = 2/3.
> Never do rate math on the raw decimal — convert to outs first (above).

## Dashboards / charts

1. Team record & standings — from dim_game (team 116): W, L, win%, and
   run differential. Tigers runs = home_score when home_team_id=116 else away_score;
   runs allowed = the other. Big-number cards + cumulative run-diff line over the season.
2. Batting leaderboard — table from mart_batting_season sorted by OPS:
   name, G, AB, H, HR, RBI, AVG, OBP, SLG, OPS.
3. Pitching leaderboard — table from mart_pitching_season: name, IP, W-L, SV, ERA, WHIP, K/9.
4. Home run leaders — bar chart, top N by HR.
5. Game log — table from dim_game (team 116): date, opponent, result (W/L), score.
6. Trend — team runs per game over the season (fact_batting + dim_date), or a hitter's rolling OPS.

## Metabase setup notes
- Add Metabase to docker-compose (map port 3000:3000).
- If Metabase is in the SAME compose as Postgres, connect it to
  host `postgres`, port `5432` (the internal service name/port on Docker's network),
  NOT localhost:5433. DB `tigers`, schema `analytics`, user `tigers_user`.
- Build "questions" on the season marts + dim_game, then assemble dashboards.