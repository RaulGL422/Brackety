-- F1-4: the warning reasons the referee picks with one tap. Null follows the sport's list (Discipline, in code).
alter table event add column warning_reasons varchar(60)[];
