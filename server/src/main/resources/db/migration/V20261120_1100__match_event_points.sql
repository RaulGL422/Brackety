-- How many points a POINT or POINT_REMOVED is worth (grappling 1 to 4; tambo always 1), for the scored actions and
-- for those a device sent that wait for the club's review (docs/producto/grappling.md, G2b).
alter table match_event add column points integer not null default 1 check (points > 0);
alter table offline_rejected_op add column points integer not null default 1 check (points > 0);

-- Action types grow (SUBMISSION, EXTRA_TIME): MatchEventType validates them; these checks were rebuilt twice already
-- (docs/producto/plan-limpieza.md, L6).
alter table match_event drop constraint match_event_type_check;
alter table offline_rejected_op drop constraint offline_rejected_op_type_check;
