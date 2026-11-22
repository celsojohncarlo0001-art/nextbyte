-- NEXTBYTE Public Study Room chat ownership, real-time deletion, and durable poll votes.
-- Run AFTER NEXBYTE_ROOM_SCHEMA.sql, NEXBYTE_ENHANCEMENTS.sql, and
-- NEXTBYTE_STUDY_ROOM_VISIBILITY.sql in the Supabase SQL Editor.
-- This migration preserves existing rows and does not expose private Storage files.

begin;

do $$
begin
  if to_regclass('public.study_rooms') is null
     or to_regclass('public.study_room_members') is null
     or to_regclass('public.study_room_messages') is null then
    raise exception 'NEXTBYTE Study Room tables are missing. Run the existing room setup SQL first.';
  end if;
  if to_regprocedure('public.is_study_room_member(uuid)') is null
     or to_regprocedure('public.is_study_room_owner(uuid)') is null then
    raise exception 'NEXTBYTE room access helper functions are missing. Run NEXBYTE_ENHANCEMENTS.sql first.';
  end if;
end $$;

-- Remove permissive DELETE or ALL policies from this table so they cannot OR-bypass
-- the author-only rule below. This changes policies only; it does not delete data.
do $$
declare p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'study_room_messages'
      and cmd in ('DELETE', 'ALL')
  loop
    execute format('drop policy if exists %I on public.study_room_messages', p.policyname);
  end loop;
end $$;

create policy "NEXTBYTE authors delete own messages only"
on public.study_room_messages
for delete to authenticated
using (
  user_id = (select auth.uid())
  and public.is_study_room_member(room_id)
);

-- Keep the creator/owner's existing non-poll task-management behavior, but do not
-- allow the room owner to edit another participant's poll. Poll authors may close
-- their own polls. The JSON envelope is written by nbSharedPayload().
drop policy if exists "NEXTBYTE authors update own messages" on public.study_room_messages;
create policy "NEXTBYTE authors update own messages"
on public.study_room_messages
for update to authenticated
using (
  public.is_study_room_member(room_id)
  and (
    user_id = (select auth.uid())
    or (
      public.is_study_room_owner(room_id)
      and body not like 'NB_SHARED_V1:%"kind":"poll"%'
    )
  )
)
with check (
  public.is_study_room_member(room_id)
  and (
    user_id = (select auth.uid())
    or (
      public.is_study_room_owner(room_id)
      and body not like 'NB_SHARED_V1:%"kind":"poll"%'
    )
  )
);

-- Parse poll payloads safely and enforce option bounds in database policies.
create or replace function public.is_valid_study_room_poll_option(
  p_body text,
  p_option_index integer,
  p_require_open boolean default true
)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare payload jsonb;
begin
  if p_body is null or p_body not like 'NB_SHARED_V1:%' or p_option_index is null or p_option_index < 0 or p_option_index > 5 then
    return false;
  end if;
  begin
    payload := pg_catalog.substr(p_body, 14)::jsonb;
  exception when others then
    return false;
  end;
  if coalesce(payload ->> 'kind', '') <> 'poll' or pg_catalog.jsonb_typeof(payload -> 'options') <> 'array' then
    return false;
  end if;
  if pg_catalog.jsonb_array_length(payload -> 'options') <= p_option_index then
    return false;
  end if;
  if p_require_open and payload ->> 'status' = 'closed' then
    return false;
  end if;
  return true;
end;
$$;
revoke all on function public.is_valid_study_room_poll_option(text, integer, boolean) from public, anon;
grant execute on function public.is_valid_study_room_poll_option(text, integer, boolean) to authenticated;

-- A dedicated vote table prevents double-voting even when two devices submit at
-- the same time. Each participant has at most one row per poll and may change it
-- while the poll is open.
create table if not exists public.study_room_poll_votes (
  poll_message_id uuid not null references public.study_room_messages(id) on delete cascade,
  room_id uuid not null references public.study_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  option_index integer not null check (option_index between 0 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (poll_message_id, user_id)
);

create index if not exists study_room_poll_votes_room_idx
  on public.study_room_poll_votes (room_id, poll_message_id);

alter table public.study_room_poll_votes enable row level security;
revoke all on public.study_room_poll_votes from public, anon;
grant select, insert, update on public.study_room_poll_votes to authenticated;

drop policy if exists "NEXTBYTE room members read poll votes" on public.study_room_poll_votes;
create policy "NEXTBYTE room members read poll votes"
on public.study_room_poll_votes
for select to authenticated
using (
  public.is_study_room_member(room_id)
  and exists (
    select 1
    from public.study_room_messages m
    where m.id = poll_message_id
      and m.room_id = study_room_poll_votes.room_id
      and public.is_valid_study_room_poll_option(m.body, 0, false)
  )
);

drop policy if exists "NEXTBYTE members create own poll vote" on public.study_room_poll_votes;
create policy "NEXTBYTE members create own poll vote"
on public.study_room_poll_votes
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and public.is_study_room_member(room_id)
  and exists (
    select 1
    from public.study_room_messages m
    where m.id = poll_message_id
      and m.room_id = study_room_poll_votes.room_id
      and public.is_valid_study_room_poll_option(m.body, study_room_poll_votes.option_index, true)
  )
);

drop policy if exists "NEXTBYTE members update own poll vote" on public.study_room_poll_votes;
create policy "NEXTBYTE members update own poll vote"
on public.study_room_poll_votes
for update to authenticated
using (
  user_id = (select auth.uid())
  and public.is_study_room_member(room_id)
  and exists (
    select 1
    from public.study_room_messages m
    where m.id = poll_message_id
      and m.room_id = study_room_poll_votes.room_id
      and public.is_valid_study_room_poll_option(m.body, study_room_poll_votes.option_index, true)
  )
)
with check (
  user_id = (select auth.uid())
  and public.is_study_room_member(room_id)
  and option_index between 0 and 5
  and exists (
    select 1
    from public.study_room_messages m
    where m.id = poll_message_id
      and m.room_id = study_room_poll_votes.room_id
      and public.is_valid_study_room_poll_option(m.body, study_room_poll_votes.option_index, true)
  )
);

-- Message DELETE events need the old room_id so a room-filtered Realtime
-- subscription can identify which open room changed.
alter table public.study_room_messages replica identity full;
alter table public.study_room_poll_votes replica identity full;

-- A room owner must not remove another member's private room-file object either.
drop policy if exists "NEXTBYTE users or room owners delete room files" on storage.objects;
drop policy if exists "NEXTBYTE users delete own room files only" on storage.objects;
create policy "NEXTBYTE users delete own room files only"
on storage.objects
for delete to authenticated
using (
  bucket_id = 'study-room-files'
  and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
);

-- Add both tables to Supabase Realtime if the publication is present.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'study_room_messages'
    ) then
      execute 'alter publication supabase_realtime add table public.study_room_messages';
    end if;
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'study_room_poll_votes'
    ) then
      execute 'alter publication supabase_realtime add table public.study_room_poll_votes';
    end if;
  end if;
end $$;

commit;

-- Verify after running:
-- select policyname, cmd, qual from pg_policies
-- where schemaname='public' and tablename='study_room_messages';
-- select * from pg_publication_tables where pubname='supabase_realtime'
--   and tablename in ('study_room_messages','study_room_poll_votes');
