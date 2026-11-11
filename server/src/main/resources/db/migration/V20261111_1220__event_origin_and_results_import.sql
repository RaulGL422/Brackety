-- Results import (docs/modulos/servidor-local.md): the hall laptop exports the event with its results and the
-- club's server imports them. origin_event_id: on the laptop, the id the event has on the server it came from.
-- results_import_hash: what was last imported, so importing the same file again changes nothing.
alter table event
    add column origin_event_id     uuid,
    add column results_import_hash varchar(64);
