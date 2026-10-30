-- Day-5 reminder is sent once; the column keeps it from going out again on the next daily run.
alter table account add column verification_reminder_sent_at timestamptz;
create index account_unverified_idx on account (created_at) where not email_verified;
