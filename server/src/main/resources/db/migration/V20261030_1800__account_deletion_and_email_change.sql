-- Logical deletion: the account is purged for good 30 days after deleted_at.
alter table account add column deleted_at timestamptz;
alter table account add constraint account_deleted_at_ck check ((status = 'DELETED') = (deleted_at is not null));
create index account_deleted_idx on account (deleted_at) where deleted_at is not null;
-- Only for CHANGE_EMAIL tokens: the address the link confirms.
alter table email_token add column new_email varchar(254);
