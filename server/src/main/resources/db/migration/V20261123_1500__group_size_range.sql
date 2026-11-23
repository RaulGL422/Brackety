-- Groups of any size within a range per category, and an optional return leg (docs/decisiones.md, 2026-11-21).
alter table event_category rename column group_size to max_group_size;
alter table event_category
    add column min_group_size integer not null default 4,
    add column return_leg     boolean not null default false,
    add check (min_group_size between 2 and max_group_size);
alter table group_member drop constraint group_member_position_check,
    add constraint group_member_position_check check (position between 0 and 7);
