-- Mats and participants are not cascaded: one with groups or matches cannot be removed.
create table fight_group (
    id          uuid primary key,
    event_id    uuid        not null references event (id) on delete cascade,
    category_id uuid        not null references event_category (id),
    mat_id      uuid        not null references mat (id),
    number      integer     not null check (number > 0),
    created_by  uuid references account (id) on delete set null,
    created_at  timestamptz not null,
    constraint fight_group_event_number_uk unique (event_id, number)
);
create index fight_group_mat_idx on fight_group (mat_id);

create table group_member (
    id             uuid primary key,
    group_id       uuid    not null references fight_group (id) on delete cascade,
    participant_id uuid    not null references participant (id),
    position       integer not null check (position between 0 and 3),
    ghost          boolean not null,
    constraint group_member_position_uk unique (group_id, position),
    constraint group_member_participant_uk unique (group_id, participant_id)
);
-- A participant competes for real in one group only; as a ghost they can fill in for others.
create unique index group_member_real_uk on group_member (participant_id) where not ghost;

create table fight_match (
    id                  uuid primary key,
    event_id            uuid        not null references event (id) on delete cascade,
    group_id            uuid        not null references fight_group (id) on delete cascade,
    mat_id              uuid        not null references mat (id),
    order_index         integer     not null,
    red_participant_id  uuid        not null references participant (id),
    blue_participant_id uuid        not null references participant (id),
    status              varchar(16) not null check (status in ('PENDING', 'IN_PROGRESS', 'FINISHED')),
    red_score           integer     not null default 0,
    blue_score          integer     not null default 0,
    started_at          timestamptz,
    finished_at         timestamptz,
    constraint fight_match_group_order_uk unique (group_id, order_index)
);
create index fight_match_event_idx on fight_match (event_id);
create index fight_match_mat_idx on fight_match (mat_id);
