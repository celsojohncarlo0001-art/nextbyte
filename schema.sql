-- NEXBYTE per-user workspace persistence for Supabase Postgres.
-- Run this in Supabase SQL Editor before using the app.
create table if not exists public.user_workspaces (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint user_workspaces_state_object check (jsonb_typeof(state) = 'object')
);

alter table public.user_workspaces enable row level security;

revoke all on table public.user_workspaces from anon;
revoke all on table public.user_workspaces from public;
grant select, insert, update, delete on table public.user_workspaces to authenticated;

drop policy if exists "Users can read their own workspace" on public.user_workspaces;
create policy "Users can read their own workspace"
  on public.user_workspaces for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own workspace" on public.user_workspaces;
create policy "Users can create their own workspace"
  on public.user_workspaces for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own workspace" on public.user_workspaces;
create policy "Users can update their own workspace"
  on public.user_workspaces for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own workspace" on public.user_workspaces;
create policy "Users can delete their own workspace"
  on public.user_workspaces for delete to authenticated
  using ((select auth.uid()) = user_id);
