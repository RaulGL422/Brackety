-- The club or the superadmin lets a match start without the least rest; who and when stay recorded.
alter table fight_match add column rest_waived_by uuid references account (id) on delete set null;
alter table fight_match add column rest_waived_at timestamptz;
-- A team match sent to a mat by hand stays there instead of going back to the pool.
alter table fight_match add column pinned boolean not null default false;

-- The superadmin's control panel changes are audited too.
alter table admin_audit drop constraint admin_audit_action_check;
alter table admin_audit
    add constraint admin_audit_action_check check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED',
                                                              'MATCH_RESET', 'GROUP_DISSOLVED', 'COMPETITION_CLEARED',
                                                              'USER_SUSPENDED', 'USER_UNSUSPENDED', 'USER_DELETED',
                                                              'CONTROL_CHANGE'));
