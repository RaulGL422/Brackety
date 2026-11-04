-- What the superadmin did and on what. No IP or email; the target is text (lock id or account id) and has no
-- foreign key, so the purge of deleted accounts never trips on it and the record outlives the account.
create table admin_audit (
    id     uuid primary key,
    at     timestamptz not null,
    action varchar(32) not null check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED')),
    target varchar(64)
);
create index admin_audit_at_idx on admin_audit (at);
