/* EUROPEAN SOCCER DATABASE ANALYSIS */

/* Data from
leagues.csv
match.csv
player.csv 
match.csv
merged into match */



/* 1. Days from the oldest Match to the most recent one (dataset time interval)*/
SELECT TIMESTAMP_DIFF(MAX(date), MIN(date), DAY)
 FROM `match` 
/* 2868 days */



/* 2. Producing a table which, for each Season and League Name, shows the following statistics about the home goals scored: 
min
average 
mid-range 
max 
sum
Which combination of Season-League has the highest number of goals? */
SELECT name, season, 
  MIN(home_team_goal) AS min_hg_scored, 
  ROUND(AVG(home_team_goal), 2) AS avg_hg_scored, 
  (MAX(home_team_goal)+MIN(home_team_goal))/2 AS mid_range_hg_score,
  MAX(home_team_goal) AS max_hg_scored,
  SUM(home_team_goal) AS sum_hg_scored
 FROM `leagues` AS l
 LEFT JOIN
 `match` AS m
 on l.id = m.league_id
 GROUP BY name, season
 ORDER BY sum_hg_scored DESC
/* England Premier League 2009/2010 */



/* 3. Finding out how many unique seasons there are in the Match table. 
Then writing a query that shows, for each Season, the number of matches played by each League. */
SELECT DISTINCT season, league_id, COUNT(match_api_id) AS matches_nr
FROM `match`
GROUP BY season, league_id
ORDER BY league_id, season
/* There are 8 unique seasons.
There is an anomaly in season 2013/2014 for the league whose ID is 1. 
While all the other leagues tend to have (more or less) the same number of matches across seasons,
in season 2013/2014 League 1 only had 12 matches. League 1’s matches generally are in the 210-306 range. */



/* 4. Using Players as the starting point, created a new table (PlayerBMI) and added: 
a new variable that represents the players’ weight in kg (divide the mass value by 2.205) and called it kg_weight; 
a variable that represents the height in metres (dividing the cm value by 100) and called it m_height; 
a variable that shows the body mass index (BMI) of the player;
Filter the table to show only the players with an optimal BMI (from 18.5 to 24.9) and found out how many
rows this table has. */
WITH tab AS (
SELECT player_name, 
weight/2.205 AS kg_weight,
height/100 AS m_height,
(weight/2.205)/((height/100)*(height/100)) AS BMI
FROM `player`
ORDER BY BMI )

SELECT *
FROM tab
WHERE BMI > 18.5 AND BMI <= 24.9
/* 10197. */



/* 5. Finding out how many players do not have an optimal BMI. */
/* 11060 lines in this query: */
SELECT player_name, 
weight/2.205 AS kg_weight,
height/100 AS m_height,
(weight/2.205)/((height/100)*(height/100)) AS BMI
FROM `player`
ORDER BY BMI
/* Minus 10197 lines in the query from point 4. */
/* Total: 863. */



/* 6. Finding which Team has scored the highest total number of goals (home + away)
during the most recent available season, and how many goals it has scored. */
WITH home_goals AS (
SELECT DISTINCT team_long_name, team_api_id, SUM(home_team_goal) AS home_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.home_team_api_id
WHERE season = '2015/2016'
GROUP BY team_long_name, team_api_id),
away_goals AS (
SELECT DISTINCT team_api_id, SUM(away_team_goal) AS away_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.away_team_api_id
WHERE season = '2015/2016'
GROUP BY team_long_name, team_api_id )

SELECT h.team_long_name, h.team_api_id, home_team_goals+away_team_goals AS total_goals
FROM home_goals as h
LEFT JOIN
away_goals a
on h.team_api_id = a.team_api_id
ORDER BY total_goals DESC
/* FC Barcelona with 112 goals in the 2015/2016 season */



/* 7. Creating a query that, for each season, shows the name of the team that ranks first in terms of total goals scored
(the output table should has as many rows as the number of seasons). 
And finding out Which team was the one that ranked first in most of the seasons? */
WITH total AS (
WITH home_goals AS (
SELECT DISTINCT season, team_long_name, team_api_id, SUM(home_team_goal) AS home_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.home_team_api_id
GROUP BY season, team_long_name, team_api_id),
away_goals AS (
SELECT DISTINCT season, team_long_name, team_api_id, SUM(away_team_goal) AS away_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.away_team_api_id
GROUP BY season, team_long_name, team_api_id )

SELECT h.season AS home_season, a.season, h.team_long_name, h.team_api_id, home_team_goals+away_team_goals AS total_goals
FROM home_goals as h
LEFT JOIN
away_goals a
on h.team_api_id = a.team_api_id
WHERE h.season = a.season
ORDER BY total_goals DESC )

SELECT season, team_long_name, team_api_id, total_goals
FROM total AS tt
INNER JOIN
  (SELECT home_season, MAX(total_goals) AS first_team
  FROM total
  GROUP BY home_season) AS groupedtt
ON tt.season = groupedtt.home_season
AND tt.total_goals = groupedtt.first_team
ORDER BY season
/* Real Madrid CF had the most total goals in 4 seasons out of 8. */



/* 8. From the query above created a new table (TopScorer) containing the top 10 teams in terms of total goals scored.
Then wrote a query that shows all the possible “pair combinations” between those 10 teams. 
How many “pair combinations” did it generate? */
CREATE TABLE Final_Exercise.TopScorer AS 

WITH home_goals AS (
SELECT DISTINCT team_long_name, team_api_id, SUM(home_team_goal) AS home_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.home_team_api_id
GROUP BY team_long_name, team_api_id),
away_goals AS (
SELECT DISTINCT team_api_id, SUM(away_team_goal) AS away_team_goals
FROM `team` AS t
LEFT JOIN
`match` AS m
ON t.team_api_id = m.away_team_api_id
GROUP BY team_long_name, team_api_id )

SELECT h.team_long_name, h.team_api_id, home_team_goals+away_team_goals AS total_goals
FROM home_goals as h
LEFT JOIN
away_goals a
on h.team_api_id = a.team_api_id
ORDER BY total_goals DESC
LIMIT 10

SELECT t1.team_long_name, t2.team_long_name
FROM `TopScorer` AS t1
CROSS JOIN `TopScorer` AS t2
WHERE t1.team_long_name <> t2.team_long_name
/* 90 unique pairs if the order (within the pair) matters. 
They would have been 45 if the order didn’t matter. */
