-- F1-7: a phase is started, then finished (read-only for everyone) and the club can reopen it.
alter table event
    add column started_at           timestamptz,
    add column finished_at          timestamptz,
    -- The club was told once that the phase could not close by itself: matches left to play.
    add column auto_close_warned_at timestamptz;

create table event_phase_change (
    id               uuid primary key,
    event_id         uuid         not null references event (id) on delete cascade,
    action           varchar(20)  not null check (action in ('START', 'FINISH', 'AUTO_FINISH', 'REOPEN')),
    -- Null when it finished by itself, or its account is gone.
    account_id       uuid references account (id) on delete set null,
    reason           varchar(500),
    unplayed_matches integer      not null default 0,
    created_at       timestamptz  not null
);
create index event_phase_change_event_idx on event_phase_change (event_id, created_at);

-- Phases already used started with their first group; those whose day is over are finished, silently.
update event e
set started_at = (select min(g.created_at) from fight_group g where g.event_id = e.id)
where exists (select 1 from fight_group g where g.event_id = e.id);

update event
set finished_at = now()
where started_at is not null and event_date < current_date;
