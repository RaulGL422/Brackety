-- Sports as data (docs/producto/plantillas-deporte.md, step 1): each sport is a template with immutable versions;
-- an event points at the version it uses. The five sports the code had become the official templates, with the
-- same codes, so the API and the event packages keep working. An event's own changes stay in its modality.
create table sport_template (
    id         uuid primary key,
    code       varchar(40) not null unique,
    position   integer     not null,
    created_at timestamptz not null default now()
);

create table sport_template_version (
    id          uuid primary key,
    template_id uuid        not null references sport_template (id),
    version     integer     not null check (version > 0),
    rules       jsonb       not null,
    created_at  timestamptz not null default now(),
    unique (template_id, version)
);

insert into sport_template (id, code, position) values
    ('5e0a7000-0000-4000-8000-000000000001', 'TAMBO', 1),
    ('5e0a7000-0000-4000-8000-000000000002', 'GRAPPLING', 2),
    ('5e0a7000-0000-4000-8000-000000000003', 'GROUND', 3),
    ('5e0a7000-0000-4000-8000-000000000004', 'THROWS', 4),
    ('5e0a7000-0000-4000-8000-000000000005', 'TECHNICAL_EXPRESSION', 5);

-- Tambo: Liga Yoseikan, cap. 3.1 and 3.1 forbidden actions; Raul's rules of the F1 (2026-11-13).
insert into sport_template_version (id, template_id, version, rules) values
    ('5e0a7001-0000-4000-8000-000000000001', '5e0a7000-0000-4000-8000-000000000001', 1, '{
      "names": {"es": "Tambo", "en": "Tambo"},
      "scoreboard": true,
      "weight": "OPTIONAL",
      "height": "OPTIONAL",
      "warningReasons": ["Proyección o golpeo", "Tirarse rodando", "Ataque de pique", "Exceso de potencia",
        "Conducta antideportiva"],
      "individual": {"matchSeconds": 60, "pointsLimit": 15},
      "team": {"matchSeconds": 180, "pointsLimit": 0},
      "minRestSeconds": 30,
      "changeoverSeconds": 30,
      "scoring": {"actions": [{"value": 1, "label": "Punto"}], "warningPoints": [0, 1], "warningsToDisqualify": 0,
        "superiorityGap": 0, "pointsAfterTime": true, "disqualificationScores": true, "oneHandWarnings": true,
        "finishes": [], "tiebreaks": [], "classification": []}
    }'),
-- Grappling: FELODA national rules, Nov. 2025 (docs/reglamentos/grappling-feloda-2025.md, art. 31, 32, 38, 39, 41
-- and 44).
    ('5e0a7001-0000-4000-8000-000000000002', '5e0a7000-0000-4000-8000-000000000002', 1, '{
      "names": {"es": "Grappling", "en": "Grappling"},
      "scoreboard": true,
      "weight": "OPTIONAL",
      "height": "OFF",
      "warningReasons": ["Pasividad", "Salir o huir del tapiz", "Sentarse a guardia sin contacto",
        "Agarrar la ropa (sin gi)", "Heel hook", "Neck crank o presión en la columna", "Slam",
        "Pequeñas articulaciones o menos de 4 dedos", "Dedos en ojos, cara o tráquea", "Llave con proyección",
        "Estrangular con el cinturón (gi)", "Técnica prohibida en U13 y U15",
        "Ignorar al árbitro o conducta antideportiva"],
      "individual": {"matchSeconds": 300, "pointsLimit": 0},
      "team": {"matchSeconds": 300, "pointsLimit": 0},
      "minRestSeconds": 30,
      "changeoverSeconds": 30,
      "scoring": {"actions": [{"value": 1, "label": "Salida o ataque"},
          {"value": 2, "label": "Derribo, inversión o derribo rápido"},
          {"value": 3, "label": "Montada lateral o derribo de amplitud"},
          {"value": 4, "label": "Montada o espalda"}],
        "warningPoints": [1], "warningsToDisqualify": 4, "superiorityGap": 15, "pointsAfterTime": false,
        "disqualificationScores": false, "oneHandWarnings": false, "finishes": ["Sumisión"],
        "tiebreaks": ["BEST_ACTION", "FEWER_WARNINGS", "EXTRA_TIME"],
        "classification": [{"end": "SUBMISSION", "winner": 5, "loser": 0, "loserWhoScored": 0},
          {"end": "DISQUALIFICATION", "winner": 5, "loser": 0, "loserWhoScored": 0},
          {"end": "SUPERIORITY", "winner": 4, "loser": 0, "loserWhoScored": 1},
          {"end": "TIME", "winner": 3, "loser": 0, "loserWhoScored": 1},
          {"end": "WARNINGS", "winner": 3, "loser": 0, "loserWhoScored": 0},
          {"end": "EXTRA_TIME", "winner": 2, "loser": 0, "loserWhoScored": 0}]}
    }'),
-- The Liga Yoseikan phases still without a scoreboard: listed, not yet chosen.
    ('5e0a7001-0000-4000-8000-000000000003', '5e0a7000-0000-4000-8000-000000000003', 1,
     '{"names": {"es": "Suelo", "en": "Ground"}, "scoreboard": false, "weight": "OPTIONAL", "height": "OPTIONAL",
       "warningReasons": []}'),
    ('5e0a7001-0000-4000-8000-000000000004', '5e0a7000-0000-4000-8000-000000000004', 1,
     '{"names": {"es": "Derribos", "en": "Throws"}, "scoreboard": false, "weight": "OPTIONAL",
       "height": "OPTIONAL", "warningReasons": []}'),
    ('5e0a7001-0000-4000-8000-000000000005', '5e0a7000-0000-4000-8000-000000000005', 1,
     '{"names": {"es": "Expresión técnica", "en": "Technical expression"}, "scoreboard": false,
       "weight": "OPTIONAL", "height": "OPTIONAL", "warningReasons": []}');

alter table event add column sport_version_id uuid references sport_template_version (id);

update event e
set sport_version_id = v.id
from sport_template t
join sport_template_version v on v.template_id = t.id and v.version = 1
where t.code = e.discipline;

alter table event alter column sport_version_id set not null;
alter table event drop column discipline;
