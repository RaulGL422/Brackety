-- F2-4: whether the league also shows every category together. Off: only one table per category (Liga Yoseikan).
alter table league add column global_standings boolean not null default false;
