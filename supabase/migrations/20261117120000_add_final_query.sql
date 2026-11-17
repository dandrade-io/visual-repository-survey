-- The text query the participant typed to obtain the result with each model
-- (or the last query they tried, when they did not find the image).
-- Nullable so rows saved before this change remain valid; the app always sends it.
-- (Applied to the remote project with `supabase db push --remote`.)

alter table public.responses
  add column if not exists jina_query   text check (char_length(jina_query)   between 1 and 500),
  add column if not exists siglip_query text check (char_length(siglip_query) between 1 and 500);

-- The view expanded r.* when it was created, so recreate it to include the new columns
-- (they are appended at the end, which "create or replace view" allows).
create or replace view public.results with (security_invoker = true) as
select p.name, p.email, p.career, r.*
from public.responses r
join public.participants p on p.id = r.participant_id
order by r.participant_id, r.position;
