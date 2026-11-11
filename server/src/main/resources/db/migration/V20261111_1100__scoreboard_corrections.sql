-- Scoreboard corrections (docs/modulos/prototipo-f1.md, Marcador Tambo): take a point back and adjust the
-- stopped clock. delta_ms: for CLOCK_ADJUST, the time added to the clock (negative takes it away).
alter table match_event
    drop constraint match_event_type_check,
    add constraint match_event_type_check check (type in ('START', 'STOP', 'POINT', 'POINT_REMOVED', 'WARNING',
                                                          'ONE_HAND_WARNING', 'DISQUALIFICATION', 'CLOCK_ADJUST',
                                                          'UNDO', 'FINISH')),
    add column delta_ms bigint;

alter table offline_rejected_op
    drop constraint offline_rejected_op_type_check,
    add constraint offline_rejected_op_type_check check (type in ('START', 'STOP', 'POINT', 'POINT_REMOVED',
                                                                  'WARNING', 'ONE_HAND_WARNING', 'DISQUALIFICATION',
                                                                  'CLOCK_ADJUST', 'UNDO', 'FINISH')),
    add column delta_ms bigint;

-- Liga Yoseikan Fase 1: 3-minute matches (Raul, 2026-11-11). Only events with no match started yet.
update event e
set match_seconds = 180
where match_seconds = 120
  and not exists (select 1 from fight_match m where m.event_id = e.id and m.status <> 'PENDING');
