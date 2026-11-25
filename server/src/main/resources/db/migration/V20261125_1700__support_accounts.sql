-- Accounts the superadmin enables for support see the Connection screen; customers never do (Raul, 2026-11-25).
alter table account add column support boolean not null default false;

-- Enabling or disabling it is audited, with its reason.
alter table admin_audit drop constraint admin_audit_action_check;
alter table admin_audit
    add constraint admin_audit_action_check check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED',
                                                              'MATCH_RESET', 'GROUP_DISSOLVED', 'COMPETITION_CLEARED',
                                                              'USER_SUSPENDED', 'USER_UNSUSPENDED', 'USER_DELETED',
                                                              'CONTROL_CHANGE', 'DEBUG_CHANGE', 'SUPPORT_CHANGED'));
