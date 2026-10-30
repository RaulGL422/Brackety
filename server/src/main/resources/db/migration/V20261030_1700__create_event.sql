create table event (
    id                 uuid primary key,
    owner_account_id   uuid         not null references account (id),
    name               varchar(120) not null,
    event_date         date         not null,
    max_groups_per_mat integer      not null check (max_groups_per_mat between 1 and 4),
    match_seconds      integer      not null check (match_seconds > 0),
    points_limit       integer      not null check (points_limit > 0),
    changeover_seconds integer      not null check (changeover_seconds >= 0),
    attendance_points  integer      not null check (attendance_points >= 0),
    created_at         timestamptz  not null
);

create table event_category (
    id       uuid primary key,
    event_id uuid        not null references event (id) on delete cascade,
    name     varchar(40) not null,
    min_age  integer     not null,
    max_age  integer     not null,
    check (min_age <= max_age)
);
create index event_category_event_idx on event_category (event_id);

create table event_staff (
    id         uuid primary key,
    event_id   uuid        not null references event (id) on delete cascade,
    account_id uuid        not null references account (id) on delete cascade,
    role       varchar(16) not null check (role in ('CLUB', 'GROUPER', 'REFEREE')),
    constraint event_staff_uk unique (event_id, account_id, role)
);
create index event_staff_account_idx on event_staff (account_id);

create table mat (
    id                 uuid primary key,
    event_id           uuid    not null references event (id) on delete cascade,
    number             integer not null check (number > 0),
    referee_account_id uuid references account (id) on delete set null,
    constraint mat_event_number_uk unique (event_id, number),
    -- Deferred so two mats can swap referees in one transaction.
    constraint mat_event_referee_uk unique (event_id, referee_account_id) deferrable initially deferred
);

-- Minimal data for a competitor without an account (06-legal-rgpd.md): no email, no photo.
create table participant (
    id               uuid primary key,
    event_id         uuid        not null references event (id) on delete cascade,
    first_name       varchar(60) not null,
    last_name        varchar(80) not null,
    birth_date       date        not null,
    height_cm        integer check (height_cm between 50 and 250),
    guardian_consent boolean     not null default false,
    created_at       timestamptz not null
);
create index participant_event_idx on participant (event_id);
