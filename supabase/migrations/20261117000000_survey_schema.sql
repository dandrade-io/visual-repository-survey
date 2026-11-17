-- Run this once in Supabase: Dashboard → SQL Editor → New query → paste → Run.

create table if not exists public.participants (
  id          uuid primary key,             -- generated in the browser
  name        text not null,
  email       text not null,
  career      text not null,
  user_agent  text,
  created_at  timestamptz not null default now()
);

create table if not exists public.responses (
  id                   bigint generated always as identity primary key,
  participant_id       uuid not null references public.participants(id) on delete cascade,
  position             smallint not null check (position between 1 and 50),
  image_id             text not null,     -- e.g. img-042 (web copy)
  image_original       text not null,     -- original filename in /images
  jina_queries         smallint not null check (jina_queries between 1 and 100),
  jina_found           boolean  not null,
  jina_satisfaction    smallint not null check (jina_satisfaction between 1 and 5),
  siglip_queries       smallint not null check (siglip_queries between 1 and 100),
  siglip_found         boolean  not null,
  siglip_satisfaction  smallint not null check (siglip_satisfaction between 1 and 5),
  created_at           timestamptz not null default now(),
  unique (participant_id, position)
);

-- Row Level Security: the public (anon) key can only INSERT, never read.
-- You read the results from the dashboard (Table Editor / SQL Editor),
-- which bypasses RLS.
alter table public.participants enable row level security;
alter table public.responses    enable row level security;

drop policy if exists "anon can insert participants" on public.participants;
create policy "anon can insert participants"
  on public.participants for insert to anon with check (true);

drop policy if exists "anon can insert responses" on public.responses;
create policy "anon can insert responses"
  on public.responses for insert to anon with check (true);

-- Handy flat view for analysis / CSV export (dashboard only).
create or replace view public.results with (security_invoker = true) as
select p.name, p.email, p.career, r.*
from public.responses r
join public.participants p on p.id = r.participant_id
order by r.participant_id, r.position;
