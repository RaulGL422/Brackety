-- Offline scoreboard (docs/modulos/offline.md): each device action has an id, so a retry is applied once.
alter table match_event
    add column op_id uuid;

create unique index match_event_op_id_uk on match_event (op_id);

-- Set when a device action clashed: the match takes no more actions until the club reviews it.
alter table fight_match
    add column review_reason varchar(16) check (review_reason in ('KNOWN_EVENTS', 'RULES', 'AGE', 'MAT_BUSY',
                                                                  'FIGHTER_BUSY'));

-- Device actions the server did not apply, in arrival order; never deleted: they are the import log.
create table offline_rejected_op (
    id               uuid primary key,
    match_id         uuid        not null references fight_match (id) on delete cascade,
    position         integer     not null,
    op_id            uuid        not null,
    type             varchar(24) not null check (type in ('START', 'STOP', 'POINT', 'WARNING', 'ONE_HAND_WARNING',
                                                          'DISQUALIFICATION', 'UNDO', 'FINISH')),
    side             varchar(4) check (side in ('RED', 'BLUE')),
    reason           varchar(200),
    at               timestamptz not null,
    actor_account_id uuid references account (id) on delete set null,
    cause            varchar(16) not null check (cause in ('KNOWN_EVENTS', 'RULES', 'AGE', 'MAT_BUSY',
                                                           'FIGHTER_BUSY', 'IN_REVIEW')),
    resolution       varchar(10) check (resolution in ('APPLIED', 'SKIPPED', 'DISCARDED')),
    resolved_by      uuid references account (id) on delete set null,
    resolved_at      timestamptz,
    created_at       timestamptz not null,
    constraint offline_rejected_op_op_id_uk unique (op_id),
    constraint offline_rejected_op_position_uk unique (match_id, position)
);
