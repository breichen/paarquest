-- Update für Web-Push: pro Person mehrere Geräte (Android-App + Browser).
-- Einmal im Supabase SQL Editor ausführen – ERST NACHDEM die neue notify-Funktion
-- deployt ist (supabase/functions/notify), sonst bekommt die alte Funktion
-- mehrere Zeilen pro Person.

alter table device_tokens drop constraint device_tokens_pkey;
alter table device_tokens add constraint device_tokens_pkey primary key (token);
alter table device_tokens add column if not exists platform text not null default 'android';
create index if not exists device_tokens_user_idx on device_tokens (user_name);
