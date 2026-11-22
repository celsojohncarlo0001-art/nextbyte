-- NEXTBYTE Public / Private Study Room visibility and access-control upgrade.
-- Run AFTER NEXBYTE_ROOM_SCHEMA.sql and NEXBYTE_ENHANCEMENTS.sql.
-- Existing collaborative rooms remain invite-only and visible to their existing
-- members/owners. New public rooms are explicitly discoverable. New private rooms
-- are owner-only; older room metadata is not exposed unexpectedly.

begin;

do $$
begin
  if to_regclass('public.study_rooms') is null
     or to_regclass('public.study_room_members') is null
     or to_regclass('public.study_room_messages') is null then
    raise exception 'NEXTBYTE Study Room tables are missing. Run the existing room schema and enhancements SQL first.';
  end if;
end $$;

alter table public.study_rooms
  add column if not exists room_type text,
  add column if not exists is_discoverable boolean not null default false;

-- Existing rooms stay collaborative and invite-only. Keep memberships and invite
-- codes, but do not make their metadata publicly discoverable. New public rooms
-- explicitly set is_discoverable=true in the application.
update public.study_rooms
   set room_type = 'public'
 where room_type is null;
update public.study_rooms
   set is_discoverable = false
 where is_discoverable is null;

alter table public.study_rooms
  alter column room_type set default 'public',
  alter column room_type set not null,
  alter column invite_code drop not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.study_rooms'::regclass
       and conname = 'study_rooms_room_type_check'
  ) then
    alter table public.study_rooms
      add constraint study_rooms_room_type_check
      check (room_type in ('public', 'private'));
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.study_rooms'::regclass
       and conname = 'study_rooms_private_no_invite_check'
  ) then
    alter table public.study_rooms
      add constraint study_rooms_private_no_invite_check
      check (room_type <> 'private' or invite_code is null);
  end if;
  if not exists (
    select 1 from pg_constraint
     where conrelid = 'public.study_rooms'::regclass
       and conname = 'study_rooms_private_not_discoverable_check'
  ) then
    alter table public.study_rooms
      add constraint study_rooms_private_not_discoverable_check
      check (room_type <> 'private' or is_discoverable = false);
  end if;
  -- Private rooms have one owner. Public rooms retain the existing 2-100 range.
  if exists (
    select 1 from pg_constraint
     where conrelid = 'public.study_rooms'::regclass
       and conname = 'study_rooms_max_capacity_check'
  ) then
    alter table public.study_rooms drop constraint study_rooms_max_capacity_check;
  end if;
  alter table public.study_rooms
    add constraint study_rooms_max_capacity_check
    check ((room_type = 'private' and max_capacity = 1)
        or (room_type = 'public' and max_capacity between 2 and 100));
end $$;

create index if not exists study_rooms_type_created_idx
  on public.study_rooms (room_type, is_discoverable, created_at desc);

-- A member predicate must not grant access to a private room if a stale or
-- manually inserted membership row exists. The owner is still recognized.
create or replace function public.is_study_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1
      from public.study_room_members m
      join public.study_rooms r on r.id = m.room_id
     where m.room_id = p_room_id
       and m.user_id = (select auth.uid())
       and (r.room_type = 'public' or r.owner_id = (select auth.uid()))
  );
$$;

revoke all on function public.is_study_room_member(uuid) from public, anon;
grant execute on function public.is_study_room_member(uuid) to authenticated;

-- Only structured non-chat activity payloads may be stored in private-room
-- message rows (for example personal notes, tasks, files, and study activity).
create or replace function public.is_private_room_activity_payload(p_body text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_payload jsonb;
  v_kind text;
begin
  if p_body is null or pg_catalog.left(p_body, 13) <> 'NB_SHARED_V1:' then
    return false;
  end if;
  begin
    v_payload := pg_catalog.substr(p_body, 14)::jsonb;
  exception when others then
    return false;
  end;
  v_kind := coalesce(v_payload ->> 'kind', '');
  return v_kind = any (array[
    'shared-note', 'shared-task', 'shared-task-response', 'shared-file',
    'shared-board', 'shared-quiz', 'shared-quiz-answer',
    'shared-poll-vote', 'shared-focus-session'
  ]::text[]);
end;
$$;
revoke all on function public.is_private_room_activity_payload(text) from public, anon;
grant execute on function public.is_private_room_activity_payload(text) to authenticated;

-- Discoverable public rooms are visible in the public directory. Hidden legacy
-- invite-only rooms remain visible only to their owner/existing members. Private
-- rows are visible only to their owner, even when accessed by direct UUID.
alter table public.study_rooms enable row level security;
drop policy if exists "NEXTBYTE room members can read rooms" on public.study_rooms;
drop policy if exists "NEXTBYTE public directory and room owners can read rooms" on public.study_rooms;
create policy "NEXTBYTE public directory and room owners can read rooms"
  on public.study_rooms for select to authenticated
  using ((room_type = 'public' and is_discoverable = true)
      or owner_id = (select auth.uid())
      or public.is_study_room_member(id));

drop policy if exists "NEXTBYTE users create own rooms" on public.study_rooms;
create policy "NEXTBYTE users create own rooms"
  on public.study_rooms for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and room_type in ('public', 'private')
    and ((room_type = 'private' and invite_code is null and is_discoverable = false and max_capacity = 1)
      or (room_type = 'public' and is_discoverable = true and max_capacity between 2 and 100))
  );

drop policy if exists "NEXTBYTE room owners update rooms" on public.study_rooms;
create policy "NEXTBYTE room owners update rooms"
  on public.study_rooms for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (
    owner_id = (select auth.uid())
    and room_type in ('public', 'private')
    and ((room_type = 'private' and invite_code is null and is_discoverable = false and max_capacity = 1)
      or (room_type = 'public' and is_discoverable = true and max_capacity between 2 and 100))
  );

drop policy if exists "NEXTBYTE room owners delete rooms" on public.study_rooms;
create policy "NEXTBYTE room owners delete rooms"
  on public.study_rooms for delete to authenticated
  using (owner_id = (select auth.uid()));

-- Keep the existing roster rules. The public join RPC below is the only way a
-- non-owner may add themselves to a public room.
alter table public.study_room_members enable row level security;
drop policy if exists "NEXTBYTE room owners add own membership" on public.study_room_members;
create policy "NEXTBYTE room owners add own membership"
  on public.study_room_members for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and public.is_study_room_owner(room_id)
  );

-- Public-room invite codes remain supported, but private rooms can never be
-- joined with an invite code.
create or replace function public.join_study_room_by_code(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_room_id uuid;
  v_capacity integer;
  v_member_count integer;
begin
  if v_user_id is null then
    raise exception 'You must be signed in to join a study room.';
  end if;
  if p_invite_code is null or pg_catalog.btrim(p_invite_code) = '' then
    raise exception 'Enter a valid invite code.';
  end if;
  select r.id, r.max_capacity
    into v_room_id, v_capacity
    from public.study_rooms r
   where r.room_type = 'public'
     and pg_catalog.upper(r.invite_code) = pg_catalog.upper(pg_catalog.btrim(p_invite_code))
   for update;
  if not found then
    raise exception 'No public study room was found for that invite code.';
  end if;
  if exists (select 1 from public.study_room_members m where m.room_id = v_room_id and m.user_id = v_user_id) then
    return v_room_id;
  end if;
  select pg_catalog.count(*)::integer into v_member_count
    from public.study_room_members m where m.room_id = v_room_id;
  if v_member_count >= v_capacity then
    raise exception 'This study room is full.';
  end if;
  insert into public.study_room_members (room_id, user_id, role)
  values (v_room_id, v_user_id, 'member')
  on conflict (room_id, user_id) do nothing;
  return v_room_id;
end;
$$;
revoke all on function public.join_study_room_by_code(text) from public, anon;
grant execute on function public.join_study_room_by_code(text) to authenticated;

-- Public discovery join: validate room visibility and capacity while holding a
-- row lock, then insert the caller's membership. Does not accept private IDs.
create or replace function public.join_public_study_room(p_room_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_capacity integer;
  v_member_count integer;
  v_room_type text;
  v_discoverable boolean;
begin
  if v_user_id is null then
    raise exception 'You must be signed in to join a public study room.';
  end if;
  select r.max_capacity, r.room_type, r.is_discoverable
    into v_capacity, v_room_type, v_discoverable
    from public.study_rooms r
   where r.id = p_room_id
   for update;
  if not found or v_room_type <> 'public' or v_discoverable is not true then
    raise exception 'This public study room does not exist or is not available.';
  end if;
  if exists (select 1 from public.study_room_members m where m.room_id = p_room_id and m.user_id = v_user_id) then
    return p_room_id;
  end if;
  select pg_catalog.count(*)::integer into v_member_count
    from public.study_room_members m where m.room_id = p_room_id;
  if v_member_count >= v_capacity then
    raise exception 'This study room is full.';
  end if;
  insert into public.study_room_members (room_id, user_id, role)
  values (p_room_id, v_user_id, 'member')
  on conflict (room_id, user_id) do nothing;
  return p_room_id;
end;
$$;
revoke all on function public.join_public_study_room(uuid) from public, anon;
grant execute on function public.join_public_study_room(uuid) to authenticated;

-- Private rooms may store structured personal study content, but cannot store
-- ordinary chat text, links, stickers, or chat polls.
drop policy if exists "NEXTBYTE room members insert messages" on public.study_room_messages;
create policy "NEXTBYTE room members insert messages"
  on public.study_room_messages for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and public.is_study_room_member(room_id)
    and (
      exists (select 1 from public.study_rooms r where r.id = room_id and r.room_type = 'public')
      or (
        exists (select 1 from public.study_rooms r where r.id = room_id and r.room_type = 'private' and r.owner_id = (select auth.uid()))
        and public.is_private_room_activity_payload(body)
      )
    )
  );

drop policy if exists "NEXTBYTE authors update own messages" on public.study_room_messages;
create policy "NEXTBYTE authors update own messages"
  on public.study_room_messages for update to authenticated
  using ((user_id = (select auth.uid()) or public.is_study_room_owner(room_id)) and public.is_study_room_member(room_id))
  with check (
    (user_id = (select auth.uid()) or public.is_study_room_owner(room_id))
    and public.is_study_room_member(room_id)
    and (
      exists (select 1 from public.study_rooms r where r.id = room_id and r.room_type = 'public')
      or (
        exists (select 1 from public.study_rooms r where r.id = room_id and r.room_type = 'private' and r.owner_id = (select auth.uid()))
        and public.is_private_room_activity_payload(body)
      )
    )
  );

commit;

-- Verification suggestions after applying:
-- 1. Signed-in account A creates a private room: it should have room_type='private',
--    invite_code IS NULL, and max_capacity=1.
-- 2. Account B must not see that row in SELECT or open its UUID.
-- 3. Account B must receive an error from join_public_study_room(private_uuid).
-- 4. Account A creates a public room: another signed-in account can list and join it.
-- 5. Existing collaborative rooms stay invite-only/hidden in the public directory;
--    existing members and invite-code joining continue to work.
-- 6. Private room insert/update of a plain chat message should be rejected by RLS.
