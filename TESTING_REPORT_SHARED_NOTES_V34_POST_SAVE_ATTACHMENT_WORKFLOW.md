# NEXTBYTE Shared Notes V34 – Post-save attachment workflow

Date: 27 November 2026

## Changes

- Removed the attachment file picker from the Create Note / Create Personal Note composer. Note creation now saves only the title and note content.
- Added an attachment-management dialog that opens from the saved note card using **Add attachment** or **Replace file**.
- The attachment dialog shows the saved note title and content so the user can confirm which note will receive the file.
- Added selected-file validation and preview for supported image/PDF files before upload, with remove/reselect controls.
- Uploads use the existing private `study-room-files` bucket and room/user/note-specific object paths.
- Attachment metadata is written to the existing note record only after the Storage upload is confirmed. The update is verified before the dialog closes.
- On replacement, the prior object is removed only after the new attachment metadata is confirmed saved.
- The note card actions are arranged in a consistent two-column mobile-friendly grid with icons, readable labels, larger touch targets, and accessible names.
- Edit Note now edits title/content only and preserves attachment metadata; attachment management is separate.
- Updated the service-worker cache version to `nexbyte-pwa-v34-post-save-note-attachment-workflow`.

## Verification performed

A local Chromium regression harness with a simulated Supabase client passed for both public-room and private-room flows:

1. Attach a PDF to an already-saved note and verify upload path and note metadata update.
2. Replace that file with a different supported document and verify metadata replacement and old-object cleanup ordering.
3. Create a second text-only note and verify it has no file metadata and does not inherit the first note's attachment.
4. Attach a separate image to the second note and verify each file remains associated with its intended note.
5. Check that the attachment dialog fits a 390px mobile viewport.

The browser harness does not connect to the production Supabase account. A real Android/device upload and authenticated multi-member verification remains a post-deployment check. No live database schema, storage bucket visibility, or RLS policy was changed as part of this V34 source update.
