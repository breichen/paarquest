-- Update 2: Beschreibungen. Einmal im SQL Editor ausführen.
-- (Der neue Status 'review' für "Erledigung angefragt" braucht keine Änderung.)
alter table tasks add column description text not null default '';
