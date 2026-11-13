-- Team matches: their own length and points limit (0 = no limit).
alter table event add column team_match_seconds integer not null default 180;
alter table event add column team_points_limit integer not null default 0;
-- Least rest a fighter gets between two matches, on any mat.
alter table event add column min_rest_seconds integer not null default 30;

-- Team groups have no mat: their matches go to whichever mat is free of individual matches,
-- and a match takes the mat that starts it.
alter table fight_group alter column mat_id drop not null;
alter table fight_match alter column mat_id drop not null;
