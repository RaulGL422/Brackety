-- Each custom export with personal or minors' columns (docs/producto/exportaciones.md): who, when, which sheet and
-- which of those columns; the file is not kept. The account has no foreign key, as in admin_audit, so the purge of
-- deleted accounts never trips on it; its name at that moment stays to say who it was.
create table export_audit (
    id         uuid primary key,
    event_id   uuid         not null references event (id) on delete cascade,
    account_id uuid         not null,
    account_name varchar(254) not null,
    at         timestamptz  not null,
    sheet      varchar(80)  not null,
    columns    varchar(2000) not null
);
create index export_audit_event_idx on export_audit (event_id, at desc);
