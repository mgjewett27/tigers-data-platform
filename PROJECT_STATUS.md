# Tigers Data Platform — Status & Handoff

End-to-end ELT platform for Detroit Tigers (team 116) analytics. Goal: portfolio piece with a Metabase dashboard.

## Status (2026-07-02)
- [x] Ingestion — MLB Stats API -> raw (idempotent, incremental by game date) — `ingest_tigers.py`
- [x] dbt — staging + star schema + SCD2 player snapshot, all tests green (`Tigers_2026/`)
- [ ] Metabase dashboards  <-- NEXT
- [ ] Airflow daily orchestration
- [ ] CI (GitHub Actions)

## Run locally
    docker compose up -d
    source .venv/bin/activate
    set -a; source .env; set +a
    python ingest_tigers.py          # ingest new games
    cd Tigers_2026 && dbt build      # rebuild + test
Secrets: PG_PASSWORD in gitignored .env. Postgres on port 5433, db `tigers`.

## Data model (grain = one player per game)
- Facts: fact_batting, fact_pitching (keys: game_pk, date_key, team_id, player_id)
- Dims: dim_team, dim_date, dim_game, dim_player (SCD2 via player_snapshot)
- Join rule: facts -> dim_player on player_id AND is_current (avoid fan-out). Point-in-time team = fact.team_id -> dim_team.

## NEXT: Metabase
1. Add Metabase to docker-compose (own port).
2. Connect to Tigers Postgres -> `analytics` schema (the dbt marts).
3. Dashboards: record/standings, batting leaderboards (AVG/OPS/HR), pitching (ERA/WHIP/K), game log, run differential.
4. Rate stats (AVG/OPS/ERA/WHIP): build a "player season totals" dbt mart or compute in Metabase.

## Gotchas
- Port 5433 (not 5432) so it coexists with the weather project.
- Raw stat columns are camelCase (API); staging quotes + aliases to snake_case.
- SCD2 only versions changes going forward; fact.team_id holds per-game team truth.