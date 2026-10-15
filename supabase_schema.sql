-- Im Supabase Dashboard unter "SQL Editor" einmal ausführen.

create table tasks (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text not null,
  category text not null,
  creator text not null,
  assignee text not null,
  coins int not null check (coins >= 0),
  hours int not null check (hours > 0),
  -- pending   = wartet auf Annahme durch assignee
  -- countered = assignee hat Gegenvorschlag gemacht, wartet auf creator
  -- accepted | done | declined | discarded
  status text not null default 'pending',
  deadline timestamptz,
  done_at timestamptz
);

create table purchases (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  buyer text not null,
  reward text not null,
  cost int not null check (cost >= 0),
  status text not null default 'open' -- open | fulfilled
);

alter table tasks enable row level security;
alter table purchases enable row level security;

-- Private App für zwei Personen, kein Login: der anon-Key darf alles.
create policy "anon all" on tasks for all to anon using (true) with check (true);
create policy "anon all" on purchases for all to anon using (true) with check (true);

-- Live-Updates
alter publication supabase_realtime add table tasks, purchases;
