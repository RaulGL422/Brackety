-- docs/modulos/importacion-alumnos.md
-- Category chosen for a participant; null = the one their age gives on the event day.
alter table participant
    add column category_id uuid references event_category (id) on delete set null;

-- Who imported how many participants and under which consent text; no names, no files.
create table participant_import (
    id              uuid primary key,
    event_id        uuid        not null references event (id) on delete cascade,
    account_id      uuid references account (id) on delete set null,
    participants    integer     not null check (participants > 0),
    consent_version varchar(16) not null,
    created_at      timestamptz not null
);
create index participant_import_event_idx on participant_import (event_id);
