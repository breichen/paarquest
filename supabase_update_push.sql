-- Update für Push-Nachrichten und Abbrechen. Einmal im SQL Editor ausführen.
-- (Wer neu startet, führt zuerst supabase_schema.sql und danach diese Datei aus.)

alter table tasks add column cancelled_by text;

create table device_tokens (
  user_name text primary key,   -- 'Benjamin' oder 'Theresa'
  token text not null,
  updated_at timestamptz not null default now()
);

alter table device_tokens enable row level security;
create policy "anon all" on device_tokens for all to anon using (true) with check (true);
