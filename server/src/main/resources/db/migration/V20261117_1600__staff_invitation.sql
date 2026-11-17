-- F1-5: the club invites a helper or a referee by email; the link adds them to the event's staff
-- (docs/modulos/ayudantes-permisos.md). Only the hash of the link is kept.
create table staff_invitation (
    id          uuid primary key,
    event_id    uuid         not null references event (id) on delete cascade,
    email       varchar(254) not null,
    role        varchar(16)  not null check (role in ('GROUPER', 'REFEREE')),
    token_hash  varchar(64)  not null unique,
    sent_at     timestamptz  not null,
    expires_at  timestamptz  not null,
    accepted_at timestamptz,
    accepted_by uuid references account (id) on delete set null
);
-- One pending invitation per address and role: inviting again sends a new link.
create unique index staff_invitation_pending_uk on staff_invitation (event_id, email, role) where accepted_at is null;
create index staff_invitation_event_idx on staff_invitation (event_id);
