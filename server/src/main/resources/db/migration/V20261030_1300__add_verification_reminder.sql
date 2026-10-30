-- Day-5 reminder is sent once; the column keeps it from going out again on the next daily run.
alter table account add column verification_reminder_sent_at timestamptz;
-- Last "you already have an account" email: at most one per minute, so repeated sign-ups cannot flood an inbox.
alter table account add column already_registered_sent_at timestamptz;
-- A link is deleted when used, so there is nothing left to mark.
alter table email_token drop column used_at;
create index account_unverified_idx on account (created_at) where not email_verified;
