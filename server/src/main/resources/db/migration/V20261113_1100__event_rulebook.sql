-- The phase's full rulebook (a PDF the club uploads), for the referees on the mats.
create table event_rulebook (
    event_id    uuid primary key references event (id) on delete cascade,
    file_name   varchar(200) not null,
    content     bytea        not null,
    uploaded_at timestamptz  not null
);
