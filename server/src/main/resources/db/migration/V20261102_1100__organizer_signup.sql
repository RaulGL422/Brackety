-- Organizers (CLUB, EXTERNAL_ENTITY) register without a birth date: they declare they are of legal age and
-- represent the organization, and give its name and CIF. The CIF may repeat: a club can have several managers.
alter table account alter column birth_date drop not null;

alter table profile add column organization_name varchar(200);
alter table profile add column tax_id varchar(9);
-- Only "no organization data on a person's profile": organizers created before this migration (the demo club
-- of an earlier deploy) have none, and the service requires it on every new organizer.
alter table profile add constraint profile_organization_ck check (
    type in ('CLUB', 'EXTERNAL_ENTITY') or (organization_name is null and tax_id is null));

alter table consent alter column document type varchar(32);
alter table consent drop constraint consent_document_check;
alter table consent add constraint consent_document_check
    check (document in ('TERMS', 'PRIVACY', 'ORGANIZER_DECLARATION'));
