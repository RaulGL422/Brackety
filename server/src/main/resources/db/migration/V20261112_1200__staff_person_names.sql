-- Who is behind each staff account in an event: the hall's accounts are generic (arbitro1, ayudante2…),
-- so the club writes the person's name for each one.
create table event_staff_name (
    event_id   uuid        not null references event (id) on delete cascade,
    account_id uuid        not null references account (id) on delete cascade,
    name       varchar(80) not null,
    primary key (event_id, account_id)
);
