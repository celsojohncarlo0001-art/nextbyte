# NEXTBYTE Shared Notes Submission and Persistence Repair

Date: 2026-11-26

## Changes made

1. Reworked the active `nbPublishRoomNote` path so the file upload and message insert are awaited in sequence. The client requires a Storage response containing a saved object path and a PostgREST response containing the saved `study_room_messages` row before it reports success or closes the composer.
2. Added verification for an ambiguous insert response. The client queries the exact `(room_id, user_id, body)` payload, which contains a unique note identifier, before asking the user to retry. This avoids duplicate notes after a timeout where the server may already have committed the request.
3. On definite insert failure after upload, attempts to remove the unreferenced object. If the result is ambiguous, it keeps the object rather than deleting a file that may already be referenced by a committed message.
4. Added a short-lived committed-note cache around the room message loader. If a concurrent realtime refresh or a stale read returns before the newly inserted row is visible, the confirmed row is retained in the current room's list. Once a fresh database read contains the row, the cache clears. Successful note deletion clears its cache entry; note edits and attachment removal update the cached payload.
5. The post-save refresh keeps the committed row visible and redraws the Notes list. A refresh failure no longer converts an already-confirmed database save into a false “share failed” state.
6. The Create Note composer remains open with title, content, and selected file intact when upload, database insertion, or verification fails. Duplicate submissions are blocked while the request is running.
7. Room metadata loaded from Supabase now retains `room_type`, so private rooms correctly use the “My Notes” / “Save note to my room” state rather than being mislabeled as public Shared Notes.
8. Bumped the service-worker cache namespace to `nexbyte-pwa-v29-shared-note-commit-persistence-fix` so an installed PWA can fetch the updated app shell.

## Connected Supabase project inspection (read-only)

The configured NEXTBYTE Supabase project was inspected using read-only queries; no schema, data, bucket, or policy changes were made.

- `study_room_messages` has the expected `id`, `room_id`, `user_id`, `body`, and `created_at` columns, and RLS is enabled.
- Existing message INSERT policies are permissive and check that the authenticated user is the message author and a member of the room. The private-room activity validator explicitly permits the `shared-note` kind.
- The `study-room-files` Storage bucket exists, is **private**, and has a 20 MiB file-size limit.
- Existing room-file Storage policies allow authenticated room members to upload/read files under room-scoped paths. The application continues using paths shaped as `room_id/user_id/notes/...` and does not make the bucket public.
- Read-only inspection found no `shared-note` message payloads in the last 30 days and no objects in `study-room-files`. This matches the reported behavior that prior note/file submissions were not persisting through the Study Room Notes flow. Existing uploads in the personal `user-study-files` bucket are separate and are not proof of a Study Room attachment upload.
- No SQL migration is included or required by this frontend repair based on the current inspected schema and policies.

## Local verification

- HTML parser: PASS.
- Inline JavaScript syntax: PASS (10 blocks, `node --check`).
- Service worker syntax: PASS (`node --check`).
- Manifest JSON: PASS.
- Public room mocked submission: PASS (upload, committed message row, visible note, composer closes only after success).
- Private room mocked submission: PASS.
- Storage upload failure: PASS (form/draft remain; no message insert).
- Database insert failure: PASS (form/draft remain; cleanup of unused uploaded object attempted).
- Stale message refresh race: PASS (confirmed note is restored into the room list).
- Fresh database read: PASS (database row takes precedence and local cache clears).
- ZIP archive integrity: checked after packaging.

## Verification limits

The connected Supabase project was inspected read-only, but this environment did not perform a real authenticated file upload or insert a test note into a user's live room. The local submission harness uses a mocked Supabase client. Therefore, real Android file selection, live RLS enforcement for a specific member account, private signed-URL downloads, and Vercel deployment still need to be verified after deploying this ZIP. No claim is made that an end-to-end live account test was completed.
