-- M2a (docs/producto/modelo-datos-migracion.md): a student's data lives once, in person; each entry
-- (participant) points at it. The participant columns stay, unused, until the next release (rollback).
create table person (
    id         uuid primary key,
    first_name varchar(60) not null,
    last_name  varchar(80) not null,
    birth_date date        not null,
    height_cm  integer check (height_cm between 50 and 250),
    created_at timestamptz not null
);

-- One person per person_id, with the data of their latest phase.
insert into person (id, first_name, last_name, birth_date, height_cm, created_at)
select distinct on (p.person_id) p.person_id, p.first_name, p.last_name, p.birth_date, p.height_cm,
       min(p.created_at) over (partition by p.person_id)
from participant p
join event e on e.id = p.event_id
order by p.person_id, coalesce(e.phase_number, 0) desc, e.event_date desc, p.created_at desc;

alter table participant
    add constraint participant_person_fk foreign key (person_id) references person (id),
    alter column first_name drop not null,
    alter column last_name drop not null,
    alter column birth_date drop not null;
