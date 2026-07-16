create schema if not exists raw;

create table raw.games (
    game_pk bigint, official_date text, season text, game_type text, status text,
    away_team_id bigint, away_team_name text, away_score int,
    home_team_id bigint, home_team_name text, home_score int, loaded_at timestamptz
);
insert into raw.games values
(1001,'2026-06-01','2026','R','Final',147,'New York Yankees',3,116,'Detroit Tigers',5,now());

create table raw.batting (
    game_pk bigint, official_date text, team_id bigint, player_id bigint,
    player_name text, position text, batting_order text,
    "atBats" int, runs int, hits int, doubles int, triples int, "homeRuns" int, rbi int,
    "baseOnBalls" int, "intentionalWalks" int, "strikeOuts" int, "hitByPitch" int,
    "stolenBases" int, "caughtStealing" int, "groundIntoDoublePlay" int,
    "plateAppearances" int, "totalBases" int, "leftOnBase" int, "sacBunts" int, "sacFlies" int,
    loaded_at timestamptz
);
insert into raw.batting
 (game_pk,official_date,team_id,player_id,player_name,position,batting_order,
  "atBats",runs,hits,doubles,triples,"homeRuns",rbi,"baseOnBalls","intentionalWalks",
  "strikeOuts","hitByPitch","stolenBases","caughtStealing","groundIntoDoublePlay",
  "plateAppearances","totalBases","leftOnBase","sacBunts","sacFlies",loaded_at)
values
(1001,'2026-06-01',116,656716,'Zach McKinstry','SS','100',4,1,2,1,0,0,1,0,0,1,0,0,0,0,4,3,1,0,0,now()),
(1001,'2026-06-01',116,600001,'Riley Greene','CF','200',4,2,3,0,0,1,2,1,0,0,0,1,0,0,5,6,0,0,0,now()),
(1001,'2026-06-01',147,500001,'Aaron Judge','RF','300',4,1,1,0,0,1,1,0,0,2,0,0,0,0,4,4,2,0,0,now());

create table raw.pitching (
    game_pk bigint, official_date text, team_id bigint, player_id bigint,
    player_name text, position text,
    "inningsPitched" text, hits int, runs int, "earnedRuns" int, "homeRuns" int,
    "baseOnBalls" int, "intentionalWalks" int, "strikeOuts" int, "hitByPitch" int,
    "battersFaced" int, "numberOfPitches" int, strikes int, balls int,
    wins int, losses int, saves int, holds int, "blownSaves" int, loaded_at timestamptz
);
insert into raw.pitching
 (game_pk,official_date,team_id,player_id,player_name,position,
  "inningsPitched",hits,runs,"earnedRuns","homeRuns","baseOnBalls","intentionalWalks",
  "strikeOuts","hitByPitch","battersFaced","numberOfPitches",strikes,balls,
  wins,losses,saves,holds,"blownSaves",loaded_at)
values
(1001,'2026-06-01',116,700001,'Tarik Skubal','P','7.0',4,3,3,1,1,0,9,0,26,95,65,30,1,0,0,0,0,now()),
(1001,'2026-06-01',147,700002,'Gerrit Cole','P','6.0',8,5,5,1,2,0,6,0,27,98,66,32,0,1,0,0,0,now());