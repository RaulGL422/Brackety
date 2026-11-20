-- Who won a match and how it ended, kept with its score (docs/producto/grappling.md, G2c): in grappling a
-- submission, the tiebreakers or the extra time decide it, not the points alone; FELODA's classification points
-- depend on how it ended.
alter table fight_match add column winner_side varchar(4) check (winner_side in ('RED', 'BLUE'));
alter table fight_match add column end_reason varchar(16);

-- Every match so far is tambo: a disqualification, else more points (equal points: a draw, no winner); it ended on
-- the points limit if one side reached it, else on time.
update fight_match m
set winner_side = case
        when m.disqualified_side = 'RED' then 'BLUE'
        when m.disqualified_side = 'BLUE' then 'RED'
        when m.red_score > m.blue_score then 'RED'
        when m.blue_score > m.red_score then 'BLUE'
    end,
    end_reason = case
        when m.disqualified_side is not null then 'DISQUALIFICATION'
        when r.points_limit > 0 and greatest(m.red_score, m.blue_score) >= r.points_limit then 'POINTS'
        else 'TIME'
    end
from modality d
         join modality_rules r on r.modality_id = d.id
where m.status = 'FINISHED'
  and d.event_id = m.event_id
  and r.format = case when m.red_team_id is null then 'INDIVIDUAL' else 'TEAM' end;
