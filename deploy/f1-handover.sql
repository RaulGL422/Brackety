-- Hands the phase 1 data over to the entity's own production account (docs/09-despliegue.md, "Datos de la F1").
-- Run by f1-handover.sh, which passes :'club', :'email' and :'hash' and commits only after you confirm.
-- The club account keeps its id, so its events, leagues, clubs and students stay its own.
select set_config('handover.club', :'club', true),
       set_config('handover.email', :'email', true),
       set_config('handover.hash', :'hash', true);

do $$
declare
    club_id   uuid;
    new_email text := lower(trim(current_setting('handover.email')));
    hash      text := current_setting('handover.hash');
begin
    select a.id into club_id
    from account a
    join profile p on p.account_id = a.id and p.type = 'CLUB'
    where lower(a.email) = lower(current_setting('handover.club')) and a.status = 'ACTIVE';
    if club_id is null then
        raise exception 'No active club account named %', current_setting('handover.club');
    end if;
    if new_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
        raise exception 'Not an email: %', new_email;
    end if;
    if exists (select 1 from account where lower(email) = new_email and id <> club_id) then
        raise exception 'Another account already uses %', new_email;
    end if;
    if hash !~ '^\$argon2id\$' then
        raise exception 'The password hash must come from --superadmin-hash';
    end if;

    update account
    set email = new_email, password_hash = hash, email_verified = true, sessions_revoked_at = now(), updated_at = now()
    where id = club_id;

    -- The generic accounts (no @: the helpers, referees and hall package staff) stay for the history of who
    -- refereed what, but nobody signs in with them again.
    create temporary table retired on commit drop as
    select id from account where position('@' in email) = 0 and status = 'ACTIVE' and suspended_at is null;

    update account
    set password_hash = null, suspended_at = now(), sessions_revoked_at = now(), updated_at = now()
    where id in (select id from retired);

    update refresh_token set revoked_at = now()
    where revoked_at is null and (account_id = club_id or account_id in (select id from retired));

    insert into admin_audit (id, at, action, target, reason)
    select gen_random_uuid(), now(), 'USER_SUSPENDED', id::text, 'F1 handover: generic account'
    from retired;
end $$;

-- What it leaves, shown before you confirm.
select a.email,
       p.type                                                  as profile,
       case when a.suspended_at is not null then 'retired' else 'active' end as state,
       (select count(*) from event e where e.owner_account_id = a.id) as events
from account a
left join profile p on p.account_id = a.id
where a.email = lower(trim(current_setting('handover.email'))) or position('@' in a.email) = 0
order by state, a.email;
