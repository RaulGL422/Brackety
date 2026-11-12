-- The referee can cancel a match started by mistake (back to pending, all at 0) and reopen a finished one to
-- correct it; both with a reason, kept in the timeline like any other action.
alter table match_event
    drop constraint match_event_type_check,
    add constraint match_event_type_check check (type in ('START', 'STOP', 'POINT', 'POINT_REMOVED', 'WARNING',
                                                          'ONE_HAND_WARNING', 'DISQUALIFICATION', 'CLOCK_ADJUST',
                                                          'UNDO', 'FINISH', 'CANCEL', 'REOPEN'));

alter table offline_rejected_op
    drop constraint offline_rejected_op_type_check,
    add constraint offline_rejected_op_type_check check (type in ('START', 'STOP', 'POINT', 'POINT_REMOVED',
                                                                  'WARNING', 'ONE_HAND_WARNING', 'DISQUALIFICATION',
                                                                  'CLOCK_ADJUST', 'UNDO', 'FINISH', 'CANCEL',
                                                                  'REOPEN'));
