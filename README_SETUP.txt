NEXTBYTE — REPAIR PACKAGE SETUP

BEFORE YOU START
1. Back up the current GitHub repository and Supabase database.
2. Keep the existing supabase-config.js project URL and public anon/publishable key. Do not replace it with a service-role key.
3. Do not delete existing Supabase tables, buckets, user rows, or policies without reviewing them.

SUPABASE SQL ORDER
1. schema.sql — run only if public.user_workspaces is missing.
2. NEXBYTE_ROOM_SCHEMA.sql — run only if the shared-room base tables are missing. This creates missing study_rooms, study_room_members, study_room_messages, and join_study_room_by_code. It uses CREATE TABLE IF NOT EXISTS and does not drop or truncate existing data. If a same-named table already exists with different columns, stop and compare the schema first.
3. NEXBYTE_ENHANCEMENTS.sql — run after the room base tables exist. It applies access policies, whiteboard storage, private room-file policies, and Realtime publication entries.
4. NEXBYTE_UPLOAD_STORAGE_FIX.sql — review and run only if personal study/music buckets or policies need repair. Existing permissive policies can still allow broader access because Supabase permissive policies are OR-combined.

DEPLOY
1. Deploy every file in this package together from the repository root to Vercel over HTTPS.
2. Keep index.html, supabase-config.js, sw.js, manifest.webmanifest, icon-192.png, icon-512.png, nexbyte-background.png, and nextbyte-background.png in their current relative locations.
3. Commit to the Vercel-connected branch and wait for Ready.
4. Open NEXTBYTE online once, sign in, then refresh once after the service worker updates.
5. To check offline startup, first sign in and let the workspace save on the device. Then test offline on that same device. Offline snapshots do not authenticate new devices and do not include online-only cloud operations.

REPAIRS IN THIS BUILD
- Restores the last cached account workspace at offline startup when the Supabase JS CDN cannot load, using a local per-account snapshot on that device.
- Clears the remembered local account marker on sign-out.
- Reloads the app when connectivity returns after an offline startup, so Supabase can initialize and cloud sync can resume.
- Reserves the file-open browser tab before waiting for signed-URL generation to reduce popup blocking.
- Deletes a room Storage object before removing its shared message reference, to avoid losing the reference if Storage rejects deletion.
- Adds NEXBYTE_ROOM_SCHEMA.sql for missing base room tables and join_study_room_by_code.
- Updates service worker cache version to fetch the repaired shell.

KNOWN LIMITATIONS
- A live Supabase authenticated test and Vercel deployment were not possible in this repair environment. Complete the post-deployment checks in TESTING_REPORT.md.
- Workspace is a single JSONB document; concurrent edits from multiple devices can overwrite newer data (last-write-wins).
- Room quizzes are practice-only; answer keys are visible to room members.
- Whiteboards synchronize whole-canvas snapshots, not individual strokes. Concurrent drawing can overwrite the latest snapshot.
- Room Lock-In publishes member focus status, not a shared authoritative timer. Music remains local to each device.
- Notification preferences save, but push/email notification delivery is not wired by this package.
- Cloud files require network access; local offline file downloads are device-specific.
- Review existing RLS policies before applying migrations; permissive policies OR together.
