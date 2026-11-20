-- How each modality scores, as data (docs/producto/grappling.md, G2): the referee's buttons and the sport's rules.
-- Every existing event plays tambo, so they all get tambo's rules (ScoringRules.TAMBO).
alter table modality add column scoring jsonb;

update modality
set scoring = '{"actions": [{"value": 1, "label": "Punto"}], "warningsPerRivalPoint": 2, "warningsToDisqualify": 0,
  "superiorityGap": 0, "pointsAfterTime": true, "disqualificationScores": true, "oneHandWarnings": true,
  "submissions": false, "tiebreaks": false}';

alter table modality alter column scoring set not null;

-- A category's own match length (grappling: 4 min for U13, U15 and veterans, 5 min for the rest); null follows its
-- modality.
alter table event_category add column match_seconds integer check (match_seconds > 0);

-- Sports grow (grappling now, templates later): the Java enum validates them, a check here would ask for a
-- migration each time (docs/producto/plan-limpieza.md, L6).
alter table event drop constraint event_discipline_check;

