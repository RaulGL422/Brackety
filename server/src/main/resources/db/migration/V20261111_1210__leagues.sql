-- Leagues by phases (docs/modulos/liga-fases.md): each phase is an event of the league; points add up across
-- phases per person. Podiums (how many firsts, seconds and thirds) are decided on the final league standings.
create table league (
    id               uuid primary key,
    owner_account_id uuid         not null references account (id),
    name             varchar(120) not null,
    podium_firsts    integer      not null default 2 check (podium_firsts between 0 and 10),
    podium_seconds   integer      not null default 2 check (podium_seconds between 0 and 10),
    podium_thirds    integer      not null default 3 check (podium_thirds between 0 and 10),
    created_at       timestamptz  not null
);

-- A category's own podium, by category name (categories are copied phase to phase).
create table league_category_podium (
    id            uuid primary key,
    league_id     uuid        not null references league (id) on delete cascade,
    category_name varchar(40) not null,
    firsts        integer     not null check (firsts between 0 and 10),
    seconds       integer     not null check (seconds between 0 and 10),
    thirds        integer     not null check (thirds between 0 and 10),
    constraint league_category_podium_uk unique (league_id, category_name)
);

alter table event
    add column league_id    uuid references league (id),
    add column phase_number integer,
    add column discipline   varchar(24) not null default 'TAMBO'
        check (discipline in ('TAMBO', 'GROUND', 'THROWS', 'TECHNICAL_EXPRESSION'));

-- Every existing event becomes phase 1 of its own league (same id, so it is easy to follow).
insert into league (id, owner_account_id, name, created_at)
select id,
       owner_account_id,
       coalesce(nullif(regexp_replace(name, '\s*·\s*Fase.*$', ''), ''), name),
       created_at
from event;
update event set league_id = id, phase_number = 1;

alter table event
    alter column league_id set not null,
    alter column phase_number set not null,
    add constraint event_phase_number_check check (phase_number > 0),
    add constraint event_league_phase_uk unique (league_id, phase_number);

-- The same person in every phase of a league: their entries share person_id, so their points add up.
alter table participant add column person_id uuid;
update participant set person_id = id;
alter table participant
    alter column person_id set not null,
    add constraint participant_event_person_uk unique (event_id, person_id);
