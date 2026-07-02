import os
import time
import requests
import pandas as pd
from datetime import date
from sqlalchemy import create_engine, text

# --- config ---
PG_PASSWORD    = os.environ["PG_PASSWORD"]
WAREHOUSE_HOST = os.environ.get("WAREHOUSE_HOST", "localhost")
ENGINE = create_engine(
    f"postgresql+psycopg2://tigers_user:{PG_PASSWORD}@{WAREHOUSE_HOST}:5433/tigers"
)
TEAM_ID      = 116          # Detroit Tigers
SEASON       = 2026
SEASON_START = f"{SEASON}-03-01"

BATTING_FIELDS = ["atBats", "runs", "hits", "doubles", "triples", "homeRuns", "rbi",
                  "baseOnBalls", "intentionalWalks", "strikeOuts", "hitByPitch",
                  "stolenBases", "caughtStealing", "groundIntoDoublePlay",
                  "plateAppearances", "totalBases", "leftOnBase", "sacBunts", "sacFlies"]
PITCHING_FIELDS = ["inningsPitched", "hits", "runs", "earnedRuns", "homeRuns",
                   "baseOnBalls", "intentionalWalks", "strikeOuts", "hitByPitch",
                   "battersFaced", "numberOfPitches", "strikes", "balls",
                   "wins", "losses", "saves", "holds", "blownSaves"]


def get_json(url, params=None, tries=3):
    """GET with retries — the Stats API occasionally returns a transient error envelope."""
    for i in range(tries):
        try:
            r = requests.get(url, params=params, timeout=30)
            r.raise_for_status()
            data = r.json()
            if isinstance(data, dict) and set(data) <= {"messageNumber", "message", "timestamp", "traceId"}:
                raise RuntimeError(f"transient API error: {data.get('message')}")
            return data
        except Exception as e:
            if i == tries - 1:
                raise
            print(f"  retry {i+1} after: {e}")
            time.sleep(2 ** i)


def get_schedule_games(start_date, end_date):
    sched = get_json("https://statsapi.mlb.com/api/v1/schedule",
                     {"sportId": 1, "teamId": TEAM_ID,
                      "startDate": start_date, "endDate": end_date})
    return [g for d in sched.get("dates", []) for g in d["games"]]


def game_row(g):
    away, home = g["teams"]["away"], g["teams"]["home"]
    return {
        "game_pk": g["gamePk"],
        "official_date": g["officialDate"],
        "season": g["season"],
        "game_type": g["gameType"],
        "status": g["status"]["detailedState"],
        "away_team_id": away["team"]["id"],
        "away_team_name": away["team"]["name"],
        "away_score": away.get("score"),
        "home_team_id": home["team"]["id"],
        "home_team_name": home["team"]["name"],
        "home_score": home.get("score"),
        "loaded_at": pd.Timestamp.now("UTC"),
    }


def player_rows(game_pk, official_date, box):
    batting, pitching = [], []
    for side in ("home", "away"):
        team = box["teams"][side]
        team_id = team["team"]["id"]
        for p in team["players"].values():
            person = p.get("person", {})
            base = {
                "game_pk": game_pk,
                "official_date": official_date,
                "team_id": team_id,
                "player_id": person.get("id"),
                "player_name": person.get("fullName"),
                "position": (p.get("position") or {}).get("abbreviation"),
            }
            stats = p.get("stats", {})
            bat, pit = stats.get("batting") or {}, stats.get("pitching") or {}
            if bat:
                row = {**base, "batting_order": p.get("battingOrder")}
                row.update({f: bat.get(f) for f in BATTING_FIELDS})
                row["loaded_at"] = pd.Timestamp.now("UTC")
                batting.append(row)
            if pit:
                row = dict(base)
                row.update({f: pit.get(f) for f in PITCHING_FIELDS})
                row["loaded_at"] = pd.Timestamp.now("UTC")
                pitching.append(row)
    return batting, pitching


def get_watermark():
    with ENGINE.begin() as conn:
        if not conn.execute(text("SELECT to_regclass('raw.games')")).scalar():
            return None
        return conn.execute(text("SELECT max(official_date) FROM raw.games")).scalar()


def load_idempotent(df, table, key="game_pk"):
    """Delete the games in this batch, then re-insert — safe re-runs."""
    if df.empty:
        return
    with ENGINE.begin() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
        if conn.execute(text(f"SELECT to_regclass('raw.{table}')")).scalar():
            keys = [int(k) for k in df[key].unique()]
            conn.execute(text(f"DELETE FROM raw.{table} WHERE {key} = ANY(:keys)"),
                         {"keys": keys})
        df.to_sql(table, conn, schema="raw", if_exists="append", index=False)


if __name__ == "__main__":
    watermark = get_watermark()
    start_date = watermark or SEASON_START      # re-pull watermark day (idempotent lookback)
    end_date = date.today().isoformat()
    print(f"Fetching Tigers games {start_date} -> {end_date}")

    games = get_schedule_games(start_date, end_date)
    finals = [g for g in games
              if g["status"]["detailedState"] == "Final" and g["gameType"] == "R"]
    print(f"{len(finals)} final regular-season games to process")

    game_rows, batting_rows, pitching_rows = [], [], []
    for g in finals:
        game_rows.append(game_row(g))
        box = get_json(f"https://statsapi.mlb.com/api/v1/game/{g['gamePk']}/boxscore")
        b, p = player_rows(g["gamePk"], g["officialDate"], box)
        batting_rows += b
        pitching_rows += p

    load_idempotent(pd.DataFrame(game_rows), "games")
    load_idempotent(pd.DataFrame(batting_rows), "batting")
    load_idempotent(pd.DataFrame(pitching_rows), "pitching")
    print(f"Loaded {len(game_rows)} games, {len(batting_rows)} batting, "
          f"{len(pitching_rows)} pitching rows.")