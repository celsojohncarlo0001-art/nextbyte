# NEXTBYTE Shared Note File Upload Repair

Date: 2026-11-26

## Problem investigated

Note creation without an attachment followed the database message-insert path, but the attachment path depended on reading `sharedNoteFile.files[0]` again when the user pressed the Share button. In Android/PWA flows, a room redraw or native file-picker return can replace the file input node. A selected-file preview can remain visible while the new input's `FileList` is empty. In that state the uploader did not receive the original `File` object.

## Changes made

1. Added an in-memory selected `File` cache populated immediately when the dynamically rendered `sharedNoteFile` input changes.
2. Scoped the cached `File` to the current Study Room ID so an attachment selected in one room cannot be submitted into another room.
3. Added a delegated `document` change listener for the dynamically rendered file input instead of relying only on an inline event handler.
4. The submit handler now uses the live input's file when present, otherwise the room-scoped cached `File` object. This preserves the attachment across replacement of the native file-input DOM node.
5. Added a guard that stops submission when the preview/status still indicates a selected attachment but the underlying `File` object is unavailable. The app now asks the user to reselect the file instead of silently submitting a text-only note.
6. Added an explicit upload-stage status message and verifies that Supabase Storage returns the exact expected object path before inserting the note row.
7. Failed uploads or note inserts retain the composer and draft. Cleanup of the unique attachment path is attempted when the note cannot be committed; a committed note is not removed during a stale refresh.
8. Updated the service-worker cache namespace to `nexbyte-pwa-v30-shared-note-file-object-retention-fix`.

## Supabase inspection (read-only)

The connected NEXTBYTE Supabase project was inspected without changing tables, buckets, data, or RLS policies.

- The `study-room-files` bucket exists, is private, and has a 20 MiB size limit.
- Existing room-file INSERT and SELECT policies require the first storage path segment to be the room UUID and validate room membership. The app path format is `<room-id>/<user-id>/notes/<unique-file-name>`, matching the configured folder structure.
- The `study_room_messages` table has RLS enabled. Existing INSERT policies require the authenticated user to be the message author and room member; the private-room payload validator accepts the `shared-note` kind.
- In the inspected log window, no Storage object requests targeted `study-room-files`, while personal-bucket object requests were present. This indicates the failing client flow was not reaching the room-file Storage endpoint in that window; it does not, by itself, prove the exact state of the device's file input.
- No SQL migration or policy change was made. The bucket was not made public and existing access restrictions were preserved.

## Local regression verification

Executed Node VM tests against the exact extracted production functions with a mocked Supabase client:

- Public room: select a PDF, replace the file-input DOM node with an empty input, submit, and verify the cached File is uploaded and linked to the saved note — PASS.
- Private room: select and upload an attachment, verify it is linked to the saved personal note — PASS.
- Storage failure: verify no note is inserted, the composer remains open, title/content and selected File remain available, and an upload error is displayed — PASS.
- HTML parsing — PASS.
- Inline JavaScript syntax checks — PASS (12 script elements).
- Service worker syntax — PASS.
- Manifest JSON validation — PASS.
- ZIP integrity — checked after packaging.

## Verification limits

The code-level regression tests use a mocked Supabase client. I did not perform a live upload using the user's authenticated Android device or insert test notes into a real room, and I did not deploy to Vercel. Therefore, a final real-device upload test is still required after the updated files are pushed and deployed. If the new version still fails, the updated UI will keep the composer open and display the Storage error rather than silently discarding the attachment.
