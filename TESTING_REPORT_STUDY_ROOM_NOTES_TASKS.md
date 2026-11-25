# NEXTBYTE Study Room Shared Notes and Tasks — Repair Verification

Date: November 25, 2026

## Implemented in this package

- Replaced the final active Shared Notes and Tasks tab renderers with a unified full-height scroll layout. Both the record list and the composer remain inside the same scroll container, fixing the clipped/half-visible creation area.
- Shared note creation is available to every joined room member. Text-only, attachment-only, and combined notes are supported. Titles and note content are length-checked.
- File upload uses the existing private `study-room-files` bucket, stores objects under `<room-id>/<user-id>/notes/...`, validates the 20 MB size limit and supported extensions, displays status feedback, and removes an uploaded orphan if the message insert fails.
- Note cards show author, timestamp, content, original filename, type, and size. Preview and Download pass the original file metadata to the existing authenticated private-file preview pipeline. Existing author edit/delete controls remain.
- Task creation is available to every joined room member and includes category, optional due date, instructions, author, and timestamp.
- Task responses are individual `shared-task-response` message rows. Updates are constrained to the current row, room, and authenticated author, preventing one member's update from overwriting another member's response. Member progress is displayed separately.
- Existing Supabase schema and policies are reused. No new RLS policies or public Storage access were added.
- PWA cache namespace updated to `nexbyte-pwa-v26-study-room-notes-tasks`.

## Static verification completed

- All non-empty inline JavaScript blocks extracted from `index.html` passed `node --check`.
- The added repair layer passed `node --check`.
- `sw.js` passed `node --check`.
- `manifest.webmanifest` parsed as valid JSON.
- HTML parser completed without a fatal parse error.
- A renderer smoke test checked that the Notes and Tasks renderers produce the unified scroll container, the corresponding create forms, file attachment controls, task category/due date fields, and per-member response controls.
- Handler smoke tests verified membership checking, user-scoped file paths, member-authored note/task inserts, and an individual task-response insert using a mocked Supabase client.
- Chromium layout smoke tests used the project styles and the live renderer output at 390 × 844 (Notes and Tasks) and 1280 × 800 (Tasks). In each case the create form was reachable by scrolling the single room content panel, and no JavaScript page errors occurred. The Notes test also checked that a filename containing apostrophes and quotation marks reached the Preview action intact.
- ZIP integrity check passed after packaging.

## Not verified from this environment

- No authenticated connection to the user's live Supabase project was available, so live uploads, RLS, Realtime, and database persistence were not executed.
- No Vercel deployment was initiated.
- Cross-account synchronization and mobile browser interaction require testing against the deployed site using two separate authenticated accounts.

## Required post-deployment checks

1. Confirm all existing room SQL migrations are installed in the documented order. The `study-room-files` bucket must be private, with member-read and owner-folder upload policies already configured by the existing room enhancement SQL.
2. Account A creates a shared public room; account B joins it. Verify both are members.
3. Account A and account B each publish a note, then each uploads a PDF or image. Verify both notes list the author, date, filename, file type, and file size.
4. Preview and download each attachment as both room members. Remove one user from the room and verify that account can no longer fetch room files.
5. Account A and account B each publish their own task with category, due date, and instructions. Verify both tasks appear for both users.
6. Submit different response text and statuses from each account on the same task. Verify each user can see their own response and that one user's subsequent update does not overwrite the other's response.
7. Refresh the room and reopen it. Confirm notes, attachments, tasks, and individual response states persist.
8. Repeat on a phone/tablet and desktop width. Verify the entire Notes/Tasks page scrolls and the create form is reachable; no controls are clipped or overlapped.
9. Inspect browser console, network requests, Supabase Storage errors, and RLS errors if a test fails. Do not resolve permission errors by making the bucket public or weakening RLS.
