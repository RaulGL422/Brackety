-- Team categories (docs/modulos/prototipo-f1-equipos.md): a group can be of teams instead of participants.
alter table event_category
    add column format     varchar(10) not null default 'INDIVIDUAL' check (format in ('INDIVIDUAL', 'TEAM')),
    add column team_size  integer check (team_size between 2 and 5),
    add column group_size integer not null default 4 check (group_size between 2 and 8),
    add check ((format = 'TEAM') = (team_size is not null));

create table team (
    id          uuid primary key,
    event_id    uuid        not null references event (id) on delete cascade,
    category_id uuid        not null references event_category (id),
    number      integer     not null check (number > 0),
    ghost       boolean     not null,
    created_by  uuid references account (id) on delete set null,
    created_at  timestamptz not null,
    constraint team_event_number_uk unique (event_id, number)
);
create index team_category_idx on team (category_id);

-- ghost repeats the team's flag so the index below can tell real memberships apart.
create table team_member (
    id             uuid primary key,
    team_id        uuid    not null references team (id) on delete cascade,
    participant_id uuid    not null references participant (id),
    position       integer not null check (position >= 0),
    ghost          boolean not null,
    constraint team_member_position_uk unique (team_id, position),
    constraint team_member_participant_uk unique (team_id, participant_id)
);
-- A participant is in one real team at most; ghost teams can reuse anyone.
create unique index team_member_real_uk on team_member (participant_id) where not ghost;

-- A group member is a participant or a team; a team is in one group at most.
alter table group_member
    alter column participant_id drop not null,
    add column team_id uuid references team (id),
    add constraint group_member_team_uk unique (group_id, team_id),
    add check ((participant_id is null) <> (team_id is null));
create unique index group_member_team_once_uk on group_member (team_id) where team_id is not null;

alter table fight_match
    alter column red_participant_id drop not null,
    alter column blue_participant_id drop not null,
    add column red_team_id  uuid references team (id),
    add column blue_team_id uuid references team (id),
    add check ((red_participant_id is not null and blue_participant_id is not null
                    and red_team_id is null and blue_team_id is null)
               or (red_participant_id is null and blue_participant_id is null
                    and red_team_id is not null and blue_team_id is not null));
