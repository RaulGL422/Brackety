-- A mat put out of use keeps when and which referee it had, to show it and to put it back in use (F1-1).
alter table mat add column disabled_at timestamptz;
alter table mat add column disabled_referee_account_id uuid references account (id) on delete set null;
