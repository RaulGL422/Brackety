create table account (
    id             uuid primary key,
    email          varchar(254) not null,
    password_hash  varchar(255),
    email_verified boolean      not null default false,
    birth_date     date         not null,
    locale         varchar(5)   not null,
    status         varchar(16)  not null check (status in ('ACTIVE', 'DELETED')),
    created_at     timestamptz  not null,
    updated_at     timestamptz  not null
);
create unique index account_email_uk on account (lower(email));

create table identity (
    id             uuid primary key,
    account_id     uuid         not null references account (id) on delete cascade,
    provider       varchar(16)  not null,
    subject        varchar(255) not null,
    provider_email varchar(254),
    created_at     timestamptz  not null,
    constraint identity_provider_subject_uk unique (provider, subject)
);
create index identity_account_idx on identity (account_id);

create table profile (
    id         uuid primary key,
    account_id uuid        not null references account (id) on delete cascade,
    type       varchar(16) not null check (type in ('CLUB', 'EXTERNAL_ENTITY', 'HELPER', 'EXTERNAL', 'STUDENT')),
    validated  boolean     not null default false,
    created_at timestamptz not null,
    constraint profile_account_type_uk unique (account_id, type)
);

create table consent (
    id          uuid primary key,
    account_id  uuid        not null references account (id) on delete cascade,
    document    varchar(16) not null check (document in ('TERMS', 'PRIVACY')),
    version     varchar(32) not null,
    accepted_at timestamptz not null
);
create index consent_account_idx on consent (account_id);

create table refresh_token (
    id         uuid primary key,
    token_hash varchar(64) not null unique,
    family_id  uuid        not null,
    account_id uuid        not null references account (id) on delete cascade,
    created_at timestamptz not null,
    expires_at timestamptz not null,
    used_at    timestamptz,
    revoked_at timestamptz
);
create index refresh_token_family_idx on refresh_token (family_id);
create index refresh_token_account_idx on refresh_token (account_id);

create table email_token (
    id         uuid primary key,
    token_hash varchar(64) not null unique,
    account_id uuid        not null references account (id) on delete cascade,
    purpose    varchar(16) not null check (purpose in ('VERIFY_EMAIL', 'RESET_PASSWORD', 'CHANGE_EMAIL')),
    created_at timestamptz not null,
    expires_at timestamptz not null,
    used_at    timestamptz
);
create index email_token_account_idx on email_token (account_id);

-- Keys are hashes of the email or IP, never the raw value.
create table login_attempt (
    attempt_key  varchar(80) primary key,
    failures     integer not null default 0,
    locked_until timestamptz
);
