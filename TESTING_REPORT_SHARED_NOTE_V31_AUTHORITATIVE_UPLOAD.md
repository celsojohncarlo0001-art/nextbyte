# Shared Notes V31 authoritative attachment submission repair

## Changes
- Added a final, authoritative `nbPublishRoomNote` implementation after all historical room patches so all current note-composer buttons invoke the same upload/commit flow.
- Added direct `change`/`input` capture on the file input and a room-scoped `File` cache that survives DOM replacement while the page remains open.
- The submission now refuses to silently fall through to a text-only note if the selected-file UI is present but the actual `File` is unavailable.
- The submit flow checks room membership, uploads to the existing private `study-room-files` bucket at `room_id/user_id/notes/...`, verifies Storage's returned path, inserts and verifies the database message row, and only then closes the composer.
- Failed uploads/database saves keep the composer and draft open. Uploaded objects are removed when a definite database failure leaves them unlinked; when commit status is ambiguous the object is retained to avoid breaking a possibly committed note.
- After a confirmed insert, the saved row is restored to the in-memory room list even if the follow-up room refresh is stale or fails.
- Bumped the service-worker app-shell cache version to V31.

## Live Supabase inspection
- The connected project has a private `study-room-files` bucket with a 20 MiB limit. Existing room-scoped Storage policies require the first path segment to be the room UUID, the second segment to be the authenticated user ID for insert/update, and room membership for access.
- The connected `study_room_messages` table has RLS enabled. Existing message INSERT policies require the authenticated author and room membership. The private-room payload validator accepts `shared-note`.
- During a timestamp-aligned live log window, no request was recorded against `study-room-files`; the observed room-message insert in that same interval was a plain-text row, not a `shared-note` payload. That row may have been unrelated chat activity, so this is reported as a diagnostic observation rather than proof of a failed note click.
- No SQL, storage bucket visibility, or RLS policies were changed.

## Local verification
The package must be checked with JavaScript syntax parsing, HTML parsing, file-picker state regression tests, upload and insert failure tests, public/private room mocked submissions, and ZIP integrity checks before release.

## Deployment note
The live Android/PWA flow must still be tested after the updated `index.html` and `sw.js` are deployed and the installed app has fetched the new service-worker version. This environment did not perform a real authenticated Android file upload.
