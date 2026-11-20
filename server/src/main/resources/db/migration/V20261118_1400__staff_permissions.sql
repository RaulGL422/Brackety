-- F1-7 C: what each helper or referee may do in the event, chosen by the club in "Personal".
-- No row = the defaults of their roles (docs/modulos/ayudantes-permisos.md); the club always has all.
create table event_staff_permissions (
    event_id    uuid         not null references event (id) on delete cascade,
    account_id  uuid         not null references account (id) on delete cascade,
    permissions varchar(300) not null,
    primary key (event_id, account_id)
);
