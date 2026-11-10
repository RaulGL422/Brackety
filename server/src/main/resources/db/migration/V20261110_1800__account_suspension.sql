-- The superadmin can suspend an account (docs/modulos/superadmin-reportes.md): it keeps its data but nobody signs in.
alter table account add column suspended_at timestamptz;

alter table admin_audit drop constraint admin_audit_action_check;
alter table admin_audit
    add constraint admin_audit_action_check check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED',
                                                              'MATCH_RESET', 'GROUP_DISSOLVED', 'COMPETITION_CLEARED',
                                                              'USER_SUSPENDED', 'USER_UNSUSPENDED', 'USER_DELETED'));
