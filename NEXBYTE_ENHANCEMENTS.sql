-- NEXTBYTE enhancements migration (idempotent)
-- Run AFTER the existing room schema is present. This adds room policies,
-- private room-file policies, and the normalized multi-whiteboard table.
-- It does not delete existing application rows or change user_workspaces.

begin;

do $$
begin
  if to_regclass('public.study_rooms') is null then
    raise exception 'Missing public.study_rooms. Run the existing NEXTBYTE room setup SQL first.';
  end if;
  if to_regclass('public.study_room_members') is null then
    raise exception 'Missing public.study_room_members. Run the existing NEXTBYTE room setup SQL first.';
  end if;
  if to_regclass('public.study_room_messages') is null then
    raise exception 'Missing public.study_room_messages. Run the existing NEXTBYTE room setup SQL first.';
  end if;
end $$;

-- Authenticated-only membership helpers. SECURITY DEFINER avoids recursive
-- RLS lookups on study_room_members; the explicit auth.uid() check is required.
create or replace function public.is_study_room_member(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.study_room_members m
    where m.room_id = p_room_id and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.is_study_room_owner(p_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.study_rooms r
    where r.id = p_room_id and r.owner_id = (select auth.uid())
  );
$$;

revoke all on function public.is_study_room_member(uuid) from public, anon;
revoke all on function public.is_study_room_owner(uuid) from public, anon;
grant execute on function public.is_study_room_member(uuid) to authenticated;
grant execute on function public.is_study_room_owner(uuid) to authenticated;

-- Room rows: members/owners may read, owners control room metadata and delete.
alter table public.study_rooms enable row level security;
revoke all on table public.study_rooms from anon, public;
grant select, insert, update, delete on public.study_rooms to authenticated;
drop policy if exists "NEXTBYTE room members can read rooms" on public.study_rooms;
create policy "NEXTBYTE room members can read rooms" on public.study_rooms
  for select to authenticated
  using (public.is_study_room_member(id) or owner_id = (select auth.uid()));
drop policy if exists "NEXTBYTE users create own rooms" on public.study_rooms;
create policy "NEXTBYTE users create own rooms" on public.study_rooms
  for insert to authenticated with check (owner_id = (select auth.uid()));
drop policy if exists "NEXTBYTE room owners update rooms" on public.study_rooms;
create policy "NEXTBYTE room owners update rooms" on public.study_rooms
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
drop policy if exists "NEXTBYTE room owners delete rooms" on public.study_rooms;
create policy "NEXTBYTE room owners delete rooms" on public.study_rooms
  for delete to authenticated using (owner_id = (select auth.uid()));

-- Membership roster: members can see the room roster. The existing invite-code
-- RPC remains responsible for allowing new members to join.
alter table public.study_room_members enable row level security;
revoke all on table public.study_room_members from anon, public;
grant select, insert, delete on public.study_room_members to authenticated;
drop policy if exists "NEXTBYTE members read room roster" on public.study_room_members;
create policy "NEXTBYTE members read room roster" on public.study_room_members
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_study_room_member(room_id) or public.is_study_room_owner(room_id));
drop policy if exists "NEXTBYTE room owners add own membership" on public.study_room_members;
create policy "NEXTBYTE room owners add own membership" on public.study_room_members
  for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_study_room_owner(room_id));
drop policy if exists "NEXTBYTE members leave or owners remove" on public.study_room_members;
create policy "NEXTBYTE members leave or owners remove" on public.study_room_members
  for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_study_room_owner(room_id));

-- Messages hold chat and structured room activities. Each row belongs to the
-- authenticated author. Per-member task and quiz submissions are separate rows.
alter table public.study_room_messages enable row level security;
revoke all on table public.study_room_messages from anon, public;
grant select, insert, update, delete on public.study_room_messages to authenticated;
drop policy if exists "NEXTBYTE room members read messages" on public.study_room_messages;
create policy "NEXTBYTE room members read messages" on public.study_room_messages
  for select to authenticated
  using (public.is_study_room_member(room_id) or public.is_study_room_owner(room_id));
drop policy if exists "NEXTBYTE room members insert messages" on public.study_room_messages;
create policy "NEXTBYTE room members insert messages" on public.study_room_messages
  for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_study_room_member(room_id));
drop policy if exists "NEXTBYTE authors update own messages" on public.study_room_messages;
create policy "NEXTBYTE authors update own messages" on public.study_room_messages
  for update to authenticated
  using ((user_id = (select auth.uid()) or public.is_study_room_owner(room_id)) and public.is_study_room_member(room_id))
  with check ((user_id = (select auth.uid()) or public.is_study_room_owner(room_id)) and public.is_study_room_member(room_id));
drop policy if exists "NEXTBYTE authors or owners delete messages" on public.study_room_messages;
create policy "NEXTBYTE authors or owners delete messages" on public.study_room_messages
  for delete to authenticated
  using ((user_id = (select auth.uid()) or public.is_study_room_owner(room_id)) and public.is_study_room_member(room_id));
create index if not exists study_room_messages_room_created_idx
  on public.study_room_messages (room_id, created_at);

-- Dedicated multi-whiteboard storage. Each board gets an independent snapshot.
create table if not exists public.study_room_boards (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.study_rooms(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  image_data text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists study_room_boards_room_created_idx
  on public.study_room_boards (room_id, created_at);

-- Realtime clients receive complete new row values for board updates.
alter table public.study_room_boards replica identity full;
alter table public.study_room_boards replica identity full;
alter table public.study_room_boards enable row level security;
revoke all on table public.study_room_boards from anon, public;
grant select, insert, update, delete on table public.study_room_boards to authenticated;
drop policy if exists "NEXTBYTE room members read whiteboards" on public.study_room_boards;
create policy "NEXTBYTE room members read whiteboards" on public.study_room_boards
  for select to authenticated
  using (public.is_study_room_member(room_id) or public.is_study_room_owner(room_id));
drop policy if exists "NEXTBYTE room members create whiteboards" on public.study_room_boards;
create policy "NEXTBYTE room members create whiteboards" on public.study_room_boards
  for insert to authenticated
  with check (created_by = (select auth.uid()) and public.is_study_room_member(room_id));
drop policy if exists "NEXTBYTE room members update whiteboards" on public.study_room_boards;
create policy "NEXTBYTE room members update whiteboards" on public.study_room_boards
  for update to authenticated
  using (public.is_study_room_member(room_id))
  with check (updated_by = (select auth.uid()) and public.is_study_room_member(room_id));
drop policy if exists "NEXTBYTE creators or owners delete whiteboards" on public.study_room_boards;
create policy "NEXTBYTE creators or owners delete whiteboards" on public.study_room_boards
  for delete to authenticated
  using ((created_by = (select auth.uid()) or public.is_study_room_owner(room_id)) and public.is_study_room_member(room_id));

-- Existing room-file bucket stays private. The app stores objects as
-- room-uuid/user-uuid/filename. A room member may read; each user writes to
-- their own folder, and owners may remove files from their room.
insert into storage.buckets (id, name, public, file_size_limit)
values ('study-room-files', 'study-room-files', false, 20971520)
on conflict (id) do update set public = false, file_size_limit = 20971520;
drop policy if exists "NEXTBYTE room members read shared room files" on storage.objects;
create policy "NEXTBYTE room members read shared room files" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'study-room-files'
    and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
  );
drop policy if exists "NEXTBYTE room members upload own room files" on storage.objects;
create policy "NEXTBYTE room members upload own room files" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'study-room-files'
    and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
  );
drop policy if exists "NEXTBYTE users update own room files" on storage.objects;
create policy "NEXTBYTE users update own room files" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'study-room-files'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'study-room-files'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
  );
drop policy if exists "NEXTBYTE users or room owners delete room files" on storage.objects;
create policy "NEXTBYTE users or room owners delete room files" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'study-room-files'
    and (storage.foldername(name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and ((storage.foldername(name))[2] = (select auth.uid())::text or public.is_study_room_owner(((storage.foldername(name))[1])::uuid))
    and public.is_study_room_member(((storage.foldername(name))[1])::uuid)
  );

-- Realtime subscription support for the new board table and room activities.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'study_room_messages') then
      execute 'alter publication supabase_realtime add table public.study_room_messages';
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'study_room_boards') then
      execute 'alter publication supabase_realtime add table public.study_room_boards';
    end if;
  end if;
end $$;

commit;

-- IMPORTANT: quizzes are currently practice-only because answer keys are stored
-- in room-message payloads readable by room members. Secure examinations need
-- server-side grading and protected answer-key records.
