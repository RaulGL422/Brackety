-- F2-1 (docs/producto/feedback-f1.md): whether an event asks for weight and height. Null follows its sport.
alter table event
    add column weight_requirement varchar(8) check (weight_requirement in ('OFF', 'OPTIONAL', 'REQUIRED')),
    add column height_requirement varchar(8) check (height_requirement in ('OFF', 'OPTIONAL', 'REQUIRED'));
