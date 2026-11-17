-- Match rules leave the event (docs/producto/modelo-datos.md, step M1): each event has its modalities (one for
-- now; the 2026-12-20 competition will have three), and each modality its length and points limit per format.
create table modality (
    id                 uuid primary key,
    event_id           uuid    not null references event (id) on delete cascade,
    position           integer not null check (position > 0),
    -- Null while the event has a single modality.
    name               varchar(60),
    min_rest_seconds   integer not null check (min_rest_seconds >= 0),
    changeover_seconds integer not null check (changeover_seconds >= 0),
    constraint modality_event_position_uk unique (event_id, position)
);

create table modality_rules (
    modality_id   uuid        not null references modality (id) on delete cascade,
    format        varchar(10) not null check (format in ('INDIVIDUAL', 'TEAM')),
    match_seconds integer     not null check (match_seconds > 0),
    -- 0 = no limit.
    points_limit  integer     not null check (points_limit >= 0),
    primary key (modality_id, format)
);

insert into modality (id, event_id, position, min_rest_seconds, changeover_seconds)
select gen_random_uuid(), id, 1, min_rest_seconds, changeover_seconds
from event;

insert into modality_rules (modality_id, format, match_seconds, points_limit)
select m.id, 'INDIVIDUAL', e.match_seconds, e.points_limit
from modality m
         join event e on e.id = m.event_id;

insert into modality_rules (modality_id, format, match_seconds, points_limit)
select m.id, 'TEAM', e.team_match_seconds, e.team_points_limit
from modality m
         join event e on e.id = m.event_id;

-- Expand, migrate, contract: the old columns go in a later release; nothing writes them any more.
alter table event
    alter column match_seconds drop not null,
    alter column points_limit drop not null,
    alter column changeover_seconds drop not null;
