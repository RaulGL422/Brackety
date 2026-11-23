-- A QR access goes on to a phase created while it is open: one account, one row per phase.
alter table temporary_access drop constraint temporary_access_account_id_key;
alter table temporary_access add constraint temporary_access_event_account_key unique (event_id, account_id);
create index temporary_access_account_idx on temporary_access (account_id);
