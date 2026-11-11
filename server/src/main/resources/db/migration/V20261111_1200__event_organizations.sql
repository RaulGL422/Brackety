-- Organizations (clubs) taking part in an event; each participant may belong to one.
create table event_organization (
    id         uuid primary key,
    event_id   uuid         not null references event (id) on delete cascade,
    name       varchar(120) not null,
    short_name varchar(20),
    constraint event_organization_name_uk unique (event_id, name)
);

-- Not cascaded: an organization with participants is not removed (the service answers 409).
alter table participant
    add column organization_id uuid references event_organization (id);
create index participant_organization_idx on participant (organization_id);
