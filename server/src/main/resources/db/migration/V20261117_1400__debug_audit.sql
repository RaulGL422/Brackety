-- The debug environment audits loading a scenario and moving the clock (docs/modulos/entornos.md).
alter table admin_audit drop constraint admin_audit_action_check;
alter table admin_audit
    add constraint admin_audit_action_check check (action in ('ADMIN_LOGIN', 'LOCK_REVOKED', 'ORGANIZER_VALIDATED',
                                                              'MATCH_RESET', 'GROUP_DISSOLVED', 'COMPETITION_CLEARED',
                                                              'USER_SUSPENDED', 'USER_UNSUSPENDED', 'USER_DELETED',
                                                              'CONTROL_CHANGE', 'DEBUG_CHANGE'));
