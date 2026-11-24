-- Every foreign key column leads an index (plan-limpieza.md, L1; ForeignKeyIndexesTest keeps it so):
-- reading a row's children and deleting its parent (an account, an event) no longer scan the whole table.
create index event_owner_account_id_idx on event (owner_account_id);
create index event_sport_version_id_idx on event (sport_version_id);
create index event_phase_change_account_id_idx on event_phase_change (account_id);
create index event_staff_name_account_id_idx on event_staff_name (account_id);
create index event_staff_permissions_account_id_idx on event_staff_permissions (account_id);
create index fight_group_category_id_idx on fight_group (category_id);
create index fight_group_created_by_idx on fight_group (created_by);
create index fight_match_blue_participant_id_idx on fight_match (blue_participant_id);
create index fight_match_blue_team_id_idx on fight_match (blue_team_id);
create index fight_match_red_participant_id_idx on fight_match (red_participant_id);
create index fight_match_red_team_id_idx on fight_match (red_team_id);
create index fight_match_rest_waived_by_idx on fight_match (rest_waived_by);
create index league_owner_account_id_idx on league (owner_account_id);
create index login_attempt_account_id_idx on login_attempt (account_id);
create index mat_disabled_referee_account_id_idx on mat (disabled_referee_account_id);
create index mat_referee_account_id_idx on mat (referee_account_id);
create index match_event_actor_account_id_idx on match_event (actor_account_id);
create index match_event_target_event_id_idx on match_event (target_event_id);
create index offline_rejected_op_actor_account_id_idx on offline_rejected_op (actor_account_id);
create index offline_rejected_op_resolved_by_idx on offline_rejected_op (resolved_by);
create index participant_category_id_idx on participant (category_id);
create index participant_person_id_idx on participant (person_id);
create index participant_import_account_id_idx on participant_import (account_id);
create index staff_invitation_accepted_by_idx on staff_invitation (accepted_by);
create index team_created_by_idx on team (created_by);
create index temporary_access_created_by_idx on temporary_access (created_by);
