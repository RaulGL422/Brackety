-- No multigroup since 2026-11-07: one group goes to a mat at a time.
alter table event drop column max_groups_per_mat;
