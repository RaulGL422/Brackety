-- Access by QR (docs/modulos/ayudantes-permisos.md): a referee or helper without an account of their own gets a
-- temporary one, tied to one event and only while its phase lasts.
alter table account add column temporary boolean not null default false;

create table temporary_access (
    id           uuid primary key,
    event_id     uuid         not null references event (id) on delete cascade,
    account_id   uuid         not null unique references account (id) on delete cascade,
    name         varchar(120) not null,
    role         varchar(20)  not null,
    -- Only the hash of the code in the QR; null once it has been used.
    token_hash   varchar(64) unique,
    created_by   uuid         not null references account (id),
    created_at   timestamptz  not null,
    renewed_at   timestamptz  not null,
    signed_in_at timestamptz,
    ended_at     timestamptz
);

create index temporary_access_event_idx on temporary_access (event_id);
