-- The superadmin's event operations (docs/modulos/superadmin-reportes.md), each with the reason given.
alter table admin_audit drop constraint admin_audit_action_check;
alter table admin_audit
    add constraint admin_audit_action_check check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED',
                                                              'MATCH_RESET', 'GROUP_DISSOLVED', 'COMPETITION_CLEARED')),
    add column reason varchar(300);
