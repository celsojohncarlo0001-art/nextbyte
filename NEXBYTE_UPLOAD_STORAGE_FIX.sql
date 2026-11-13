-- NEXTBYTE Storage policy repair (idempotent)
-- Run this in Supabase SQL Editor AFTER the existing NEXTBYTE setup SQL.
-- It does not delete files, user rows, or existing workspace data.
-- Personal object paths are: <auth.uid()>/<subject-id>/... and <auth.uid()>/<track-id>_...

begin;

-- Keep the personal buckets private and align their server-side upload limits
-- with the limits shown in the NEXTBYTE interface.
insert into storage.buckets (id, name, public, file_size_limit)
values
  ('user-study-files', 'user-study-files', false, 20971520),
  ('user-music', 'user-music', false, 52428800)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit;

-- Private subject materials and syllabus attachments.
-- The first path segment must be the currently authenticated user's UUID.
drop policy if exists "NEXBYTE v42 read own study files" on storage.objects;
create policy "NEXBYTE v42 read own study files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'user-study-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 upload own study files" on storage.objects;
create policy "NEXBYTE v42 upload own study files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'user-study-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 update own study files" on storage.objects;
create policy "NEXBYTE v42 update own study files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'user-study-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'user-study-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 delete own study files" on storage.objects;
create policy "NEXBYTE v42 delete own study files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'user-study-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Private music objects. NEXTBYTE stores them under <user-uuid>/<track-id>_file.
drop policy if exists "NEXBYTE v42 read own music" on storage.objects;
create policy "NEXBYTE v42 read own music"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'user-music'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 upload own music" on storage.objects;
create policy "NEXBYTE v42 upload own music"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'user-music'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 update own music" on storage.objects;
create policy "NEXBYTE v42 update own music"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'user-music'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'user-music'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "NEXBYTE v42 delete own music" on storage.objects;
create policy "NEXBYTE v42 delete own music"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'user-music'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Room files are governed separately by the room-membership policies in
-- NEXBYTE_ENHANCEMENTS.sql. Do not broaden those policies here.

commit;
