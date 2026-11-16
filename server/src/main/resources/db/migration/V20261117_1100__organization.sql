-- M2b (docs/producto/modelo-datos-migracion.md): a club lives once per owner account, in organization;
-- event_organization only links it to an event. Its name columns stay, unused, until the next release (rollback).
create table organization (
    id               uuid primary key,
    owner_account_id uuid         not null references account (id),
    name             varchar(120) not null,
    short_name       varchar(20),
    created_at       timestamptz  not null
);
create unique index organization_owner_name_uk on organization (owner_account_id, lower(name));

-- One organization per owner and name (case aside), with the short name of its latest event.
insert into organization (id, owner_account_id, name, short_name, created_at)
select gen_random_uuid(), owner_account_id, name, short_name, now()
from (select distinct on (e.owner_account_id, lower(o.name)) e.owner_account_id, o.name, o.short_name
      from event_organization o
      join event e on e.id = o.event_id
      order by e.owner_account_id, lower(o.name), e.event_date desc) latest;

alter table event_organization add column organization_id uuid references organization (id);
update event_organization eo
set organization_id = o.id
from event e, organization o
where e.id = eo.event_id and o.owner_account_id = e.owner_account_id and lower(o.name) = lower(eo.name);
alter table event_organization
    alter column organization_id set not null,
    alter column name drop not null,
    add constraint event_organization_organization_uk unique (event_id, organization_id);
create index event_organization_organization_idx on event_organization (organization_id);
