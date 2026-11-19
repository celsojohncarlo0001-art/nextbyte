-- NEXTBYTE shared-room base schema and invite-code RPC.
-- Run this BEFORE NEXBYTE_ENHANCEMENTS.sql, and only after reviewing your
-- existing Supabase schema. All objects are created only when missing.
-- This file does not delete application rows or replace existing tables.

begin;

create table if not exists public.study_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 100),
  subject_tag text not null default 'Study Group',
  description text not null default '',
  emoji text not null default '📘',
  color text not null default '#2563EB',
  owner_id uuid not null references auth.users(id) on delete cascade,
  invite_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  max_capacity integer not null default 8 check (max_capacity between 2 and 100),
  created_at timestamptz not null default now()
);

create table if not exists public.study_room_members (
  room_id uuid not null references public.study_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.study_room_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.study_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

-- Fail early with a readable message if same-named legacy tables have a
-- different layout. CREATE TABLE IF NOT EXISTS never alters existing tables.
do $$
begin
  if exists (
    select 1
      from (values
        ('study_rooms', 'id'), ('study_rooms', 'name'), ('study_rooms', 'subject_tag'),
        ('study_rooms', 'description'), ('study_rooms', 'emoji'), ('study_rooms', 'color'),
        ('study_rooms', 'owner_id'), ('study_rooms', 'invite_code'),
        ('study_rooms', 'max_capacity'), ('study_rooms', 'created_at'),
        ('study_room_members', 'room_id'), ('study_room_members', 'user_id'),
        ('study_room_members', 'role'), ('study_room_members', 'joined_at'),
        ('study_room_messages', 'id'), ('study_room_messages', 'room_id'),
        ('study_room_messages', 'user_id'), ('study_room_messages', 'body'),
        ('study_room_messages', 'created_at')
      ) as required(table_name, column_name)
     where not exists (
       select 1
         from information_schema.columns as c
        where c.table_schema = 'public'
          and c.table_name = required.table_name
          and c.column_name = required.column_name
     )
  ) then
    raise exception 'An existing NEXTBYTE room table is missing required columns. Stop and compare the current schema before continuing.';
  end if;
end;
$$;

create index if not exists study_rooms_owner_created_idx
  on public.study_rooms (owner_id, created_at desc);
create index if not exists study_rooms_invite_code_idx
  on public.study_rooms (upper(invite_code));
create index if not exists study_room_members_user_joined_idx
  on public.study_room_members (user_id, joined_at desc);
create index if not exists study_room_messages_room_created_idx
  on public.study_room_messages (room_id, created_at);

-- Tables are deny-by-default under RLS until the policy migration below runs.
-- The grants only make SQL operations available to authenticated sessions;
-- RLS remains responsible for deciding which rows each user can access.
alter table public.study_rooms enable row level security;
alter table public.study_room_members enable row level security;
alter table public.study_room_messages enable row level security;

revoke all on table public.study_rooms from public, anon;
revoke all on table public.study_room_members from public, anon;
revoke all on table public.study_room_messages from public, anon;
grant select, insert, update, delete on table public.study_rooms to authenticated;
grant select, insert, update, delete on table public.study_room_members to authenticated;
grant select, insert, update, delete on table public.study_room_messages to authenticated;

-- Join by invite code. The room row is locked while checking capacity so two
-- simultaneous requests cannot both claim the final available seat.
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
    from public.study_rooms as r
   where pg_catalog.upper(r.invite_code) = pg_catalog.upper(pg_catalog.btrim(p_invite_code))
   for update;

  if not found then
    raise exception 'No study room was found for that invite code.';
  end if;

  if exists (
    select 1
      from public.study_room_members as m
     where m.room_id = v_room_id
       and m.user_id = v_user_id
  ) then
    return v_room_id;
  end if;

  select pg_catalog.count(*)::integer
    into v_member_count
    from public.study_room_members as m
   where m.room_id = v_room_id;

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

commit;

-- NEXT STEP: Run NEXBYTE_ENHANCEMENTS.sql to add the room/member/message RLS
-- policies, private room-file policies, whiteboard table, and Realtime entries.
-- If these tables already exist in your project with a different column layout,
-- stop and compare the existing columns before applying this migration.
