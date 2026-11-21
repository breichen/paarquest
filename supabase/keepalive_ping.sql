-- Wachhalte-Ping mit Schreibzugriff: Supabase wertet reines Lesen offenbar nicht
-- zuverlässig als Aktivität. Einmal im SQL-Editor dieses Projekts ausführen.
-- Die Tabelle hat genau eine Zeile; die Funktion schreibt die aktuelle Zeit hinein.
-- anon darf nur die Funktion aufrufen, nicht direkt auf die Tabelle zugreifen.
create table if not exists public.keepalive_log (
  id int primary key default 1 check (id = 1),
  pinged_at timestamptz not null default now()
);
alter table public.keepalive_log enable row level security;

create or replace function public.keepalive_ping()
returns timestamptz
language sql
security definer
set search_path = ''
as $$
  insert into public.keepalive_log (id, pinged_at) values (1, now())
  on conflict (id) do update set pinged_at = excluded.pinged_at
  returning pinged_at
$$;

revoke all on function public.keepalive_ping() from public;
grant execute on function public.keepalive_ping() to anon;
