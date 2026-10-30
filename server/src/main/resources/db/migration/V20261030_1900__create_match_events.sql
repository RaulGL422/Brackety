-- Snapshot of the match clock and outcome, kept in step with its events by the scoreboard.
alter table fight_match
    add column elapsed_ms        bigint not null default 0,
    add column running_since     timestamptz,
    add column disqualified_side varchar(4) check (disqualified_side in ('RED', 'BLUE'));

-- Everything the referee does, in order; an undo is one more event, nothing is deleted.
create table match_event (
    id               uuid primary key,
    match_id         uuid        not null references fight_match (id) on delete cascade,
    position         integer     not null,
    type             varchar(24) not null check (type in ('START', 'STOP', 'POINT', 'WARNING', 'ONE_HAND_WARNING',
                                                          'DISQUALIFICATION', 'UNDO', 'FINISH')),
    side             varchar(4) check (side in ('RED', 'BLUE')),
    reason           varchar(200),
    target_event_id  uuid references match_event (id),
    actor_account_id uuid references account (id) on delete set null,
    automatic        boolean     not null default false,
    at               timestamptz not null,
    clock_ms         bigint      not null,
    constraint match_event_position_uk unique (match_id, position)
);
