-- M2c (docs/producto/modelo-datos-migracion.md): sex and weight. The person keeps their sex and their latest
-- height and weight; each entry keeps what was measured for that event (participant.height_cm already holds
-- the F1 heights). Sex stays empty for the people of F1 until the club fills it in (Raul, 2026-11-17).
alter table person
    add column sex       varchar(6) check (sex in ('FEMALE', 'MALE')),
    add column weight_kg numeric(4, 1) check (weight_kg between 10 and 250);
alter table participant
    add column weight_kg numeric(4, 1) check (weight_kg between 10 and 250);
