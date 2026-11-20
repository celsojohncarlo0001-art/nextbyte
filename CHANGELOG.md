# NEXTBYTE Repair Build — November 19, 2026

## Repairs applied

- Added a local last-authenticated-account marker so an already-authenticated account's saved workspace snapshot can be restored on the same device when the app starts offline and the Supabase JavaScript CDN has not loaded.
- Clear the local account marker when the user signs out.
- Added reconnect handling for an offline startup: once connectivity returns, reload the app so the external Supabase SDK can initialize and normal session/cloud recovery can resume.
- Changed signed-file opening for personal, room, and cloud-manager files to reserve a browser tab synchronously before requesting the Supabase signed URL, reducing popup-blocker failures.
- Reordered cloud deletion so the actual Storage object is deleted before attempting to clean up a shared-room message reference. If the Storage deletion fails, the app retains the metadata reference. If later room-message cleanup fails, the UI reports that partial cleanup rather than claiming everything was removed.
- Added `NEXBYTE_ROOM_SCHEMA.sql`, which creates the missing shared-room base tables and `join_study_room_by_code` RPC only when absent. The SQL does not drop or truncate existing tables or rows.
- Bumped the service-worker cache namespace to `nexbyte-pwa-v5-offline-auth-repair` so deployed clients fetch the repaired shell.
- Removed a duplicate `REPLICA IDENTITY FULL` statement from the room enhancement migration.
- Updated setup and deployment documentation with the required SQL order, RLS cautions, known functional limitations, and post-deployment verification steps.

## Preserved

- Existing project Supabase URL and public publishable/anon key in `supabase-config.js`.
- Existing app structure, design, CSS, PWA manifest, icon assets, and background assets.
- Protected visual sections: Home, Study Hub, Study Rooms, Notes, Tasks, Profile, and Bottom Navigation Bar. The changes to `index.html` are limited to authentication/offline recovery and cloud file handling logic; the original CSS and visible section templates were not redesigned.
- Existing application features and data schema; no application rows or existing tables were deleted by the source changes.

## Validation completed in this environment

- All five inline JavaScript blocks pass `node --check`.
- The concatenated inline JavaScript passes `node --check`.
- `sw.js` and `supabase-config.js` pass `node --check`.
- `manifest.webmanifest` parses as valid JSON.
- HTML parses successfully with all expected document sections.
- All local `src`/`href` asset references in the HTML resolve to files in the project.
- PWA icons have the required 192×192 and 512×512 dimensions.
- The patch landmarks for offline restore, reconnect reload, pre-opened file tabs, deletion ordering, and service-worker version were verified in source.
- The original uploaded ZIP and the final ZIP pass archive integrity checks.

## Not verified here

- SQL was not executed against the live Supabase project. Review the existing tables and policies, then apply migrations in the order documented in `README_SETUP.txt`.
- No authenticated browser session was available to test sign-in, Storage upload/download/delete, realtime room updates, multi-account permissions, or cross-device synchronization.
- Browser automation was blocked in this environment; mobile/desktop UI interactions and console/network behavior must be checked after Vercel deployment.
- No Vercel deployment was performed.


## Study Hub attachment repair — November 20, 2026

- Added automatic per-subject reconciliation with the private `user-study-files` Storage folder whenever a user enters a Study Hub subject. Legacy files that exist in Storage but are absent from the subject workspace list are attached to the matching subject automatically; Manage Cloud Files is no longer required for normal recovery.
- Preserved exact subject-ID and authenticated-user folder matching (`<user-id>/<subject-id>/...`) and made recovery idempotent by checking the complete Storage path before inserting a workspace attachment reference.
- Added an upload-independent recheck when a subject is entered, so previously uploaded materials and syllabus attachments can appear on a second device after signing into the same account.
- Kept the existing workspace JSON schema and private Storage bucket. No new database table, bucket, or SQL migration was introduced.
- Surfaced subject Storage-listing and permission failures through an on-screen message when the user is still viewing that subject, instead of leaving the failure only in the browser console.
- Scoped the Study Hub attachment row layout so very long filenames truncate with an ellipsis inside the available text area, while the full filename remains available through the `title` attribute. File action buttons retain fixed widths on narrow screens.
- Added dedicated responsive styles for Materials and Syllabus attachment cards without changing the protected navigation or unrelated sections.

## Verification for this repair

- All five inline JavaScript blocks passed Node.js syntax checking.
- Service worker and Supabase configuration JavaScript passed syntax checking.
- HTML parsed successfully; no duplicate static IDs were found.
- A mocked Supabase Storage test confirmed recovery from `materials/`, `syllabus/`, and legacy root paths, and confirmed that a second scan does not create duplicate references.
- Source checks confirmed per-subject scanning, subject path construction, accessible full-name titles, filename ellipsis styling, and fixed-width file action buttons.

Live Supabase uploads, RLS, real cross-device behavior, and deployed mobile layout still require validation against the user's hosted Supabase and Vercel environment.


## Follow-up Study Hub attachment correction — November 20, 2026

- Fixed the blank middle action icon in Study Hub → Materials by adding the missing `external` SVG glyph used by the Open File control.
- Reworked automatic recovery to scan the authenticated user's `user-study-files` tree recursively and associate each Storage object with a subject by its actual subject-ID directory segment. It now supports legacy root-level uploads and nested `materials`, `syllabus`, `attachments`, and other historical folder names.
- Made automatic recovery use the same account-wide reconciliation routine as the manual recovery action, preventing different behavior between opening a subject and using Manage Cloud Files.
- Added a short, bounded retry sequence after subject navigation to tolerate mobile startup/authentication timing; repeated renders are debounced and concurrent scans are coalesced.
- Rebuilt Syllabus attachment headings with a constrained two-column grid. Long labels and original filenames now wrap inside the card instead of extending beyond its frame; action buttons remain below and available.
- Bumped the PWA cache namespace to `nexbyte-pwa-v6-subject-attachment-sync` so installed devices can fetch the latest HTML and styles.
- No SQL migration or database schema change was required.

## Verification for this follow-up

- Five inline JavaScript blocks and their concatenation pass Node.js syntax checks.
- `sw.js` and the existing `supabase-config.js` pass Node.js syntax checks; the existing Supabase URL/key configuration was preserved.
- HTML parsing and inline CSS parsing pass.
- Source checks confirm the Materials `external` icon is now defined, recursive user-prefix recovery is enabled, automatic scans retry after entry, and Syllabus headings use a minmax grid with wrap-safe filenames.
- Live Supabase Storage listing, upload, cross-device sync, and deployed Android visual checks still require the actual hosted project and account. These are not represented as passed.


## Materials upload visibility correction — November 20, 2026

- Fixed the Materials upload race by re-resolving the subject from the live workspace by stable subject ID after the asynchronous Storage upload completes. The upload handler no longer writes to a stale subject object captured before the upload started.
- The uploaded file's metadata is now inserted into the current subject's `materials` list, deduplicated by its full Storage path, and written to the local workspace snapshot immediately.
- The subject is re-rendered immediately after attachment insertion, before the cloud workspace save finishes, so the new file appears in the open Materials tab without visiting Manage Cloud Files.
- A successful Storage upload is no longer deleted just because the workspace metadata save temporarily fails. The file remains visible locally, the snapshot is retained, and the UI reports that cloud workspace synchronization is pending instead of falsely reporting a full save.
- If the workspace changes during upload, the code attempts the existing automatic Storage reconciliation rather than silently losing the cloud object.
- Bumped the service-worker cache namespace to `nexbyte-pwa-v7-materials-upload-live-state` so installed PWA clients fetch the updated upload logic. No database schema or SQL migration was added.

## Verification for this correction

- All seven inline JavaScript blocks passed Node.js syntax checking.
- `sw.js` and `supabase-config.js` passed Node.js syntax checking; the existing Supabase configuration was preserved.
- The actual extracted Materials upload handler passed a Node.js mock test that replaces the workspace object while the cloud upload is in progress. The uploaded material was added to the new live subject object, rendered before the delayed workspace save completed, persisted with the actual Storage path, and deduplicated on a second attach attempt.
- HTML and PWA manifest parsing and ZIP integrity checks passed.

Live Supabase Storage, real account policies, cross-device synchronization, and deployed Android behavior still require testing against the user's hosted environment.


## Study Hub syllabus, preview, and materials folders (November 20, 2026)

- Reworked syllabus uploads to re-resolve the current subject after cloud upload, attach the record immediately, and retain the uploaded object if workspace synchronization is temporarily unavailable.
- Added in-app previews for PDF, common image formats, TXT/Markdown, CSV, and supported audio formats using authenticated signed URLs.
- Separated preview and download actions so Open does not request a download disposition.
- Added per-subject logical folders for All Files, PDF Documents, Images, Word Documents, Presentations, Spreadsheets, Text Files, Audio Files, and Other Files.
- Added category metadata to new materials and inferred categories for older records without changing their Storage paths or requiring new buckets.
- Added distinct original-file download action and retained the existing device-offline save action.
- Added MP3, WAV, M4A, OGG, and GIF support to the Materials upload workflow.
- Bumped the PWA shell cache to `nexbyte-pwa-v8-study-hub-preview-folders`.


## November 20, 2026 — Materials folders, Video Files, and Task attachments

- Changed the Study Hub Materials default view to a folder-only overview. Individual files appear only after opening All Files or a category.
- Categories are now All Files, PDF Documents, Images, Word Documents, Video Files, Text Files, and Other Files.
- Removed the Audio Files folder without deleting any uploaded audio. Legacy audio, presentation, and spreadsheet objects remain accessible in All Files and are grouped under Other Files. CSV materials remain in Text Files.
- Added validated MP4, WebM, MOV, and M4V categorization and responsive in-app video preview.
- Added optional multi-file task attachments beneath Step-by-Step Instructions. Files are uploaded to the existing private `user-study-files` bucket and linked in the existing workspace task object.
- Task attachments reject spreadsheet, presentation, CSV, and audio file extensions/MIME types; accepted types include PDF, Word, images, TXT/Markdown, and supported video.
- Task cards now show attachment Open and Download actions. Edit flow supports removing saved attachments, and task deletion attempts cloud object cleanup only after workspace deletion has synchronized.
- Updated the PWA cache namespace to `nexbyte-pwa-v9-video-folders-task-attachments`.
- No new Supabase table, bucket, or SQL migration was added.
