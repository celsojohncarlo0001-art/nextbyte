
## V33 — Shared Notes file selection and action controls

- Bind the selected file to the Study Room ID rendered on the file input, so native Android/PWA picker return and view redraw do not lose the file's room association.
- Keep the selected-file identity consistent between the current uploader and legacy preview cache.
- Improve attachment action controls with labelled icons, accessible names, responsive two-column layout, and larger mobile tap targets.
- Preserve creator-only Replace, Remove, Edit, and Delete controls.
- Bump service-worker app-shell cache to V33.

## 2026-11-27 — Shared Notes V32 attachment synchronization repair
- Added a committed-note overlay so a saved note remains visible if an overlapping or stale room-message refresh temporarily replaces the in-memory list.
- Render the verified note immediately after the Storage upload and database insert complete; the follow-up room refresh now reconciles in the background.
- Generate the note ID before upload and reuse it in both the private Storage path and the note payload to strengthen attachment-to-note association.
- Verify the returned note kind, note ID, room/user IDs, filename, and file path before reporting success.
- Synchronize the V32 file cache with legacy preview/remove helpers; explicit removal, closing the composer, or opening a new composer clears both file caches to prevent a previous attachment from leaking into a later note.
- Bumped the PWA cache to V32.
- No Supabase SQL, bucket visibility, or RLS policies were changed.

## 2026-11-26 — Shared Notes V31 authoritative file upload handler
- Consolidated the final Shared Notes button entry point after the historical patches to ensure one authoritative file-aware submit handler runs.
- Captures the selected File directly from the input and retains it by room across DOM redraws.
- Prevents a selected attachment from silently becoming a text-only note.
- Keeps the composer and draft open after Storage or database failures; closes only after the saved message row is confirmed.
- Retains the private `study-room-files` bucket and existing authorization policies.
- Bumped PWA cache version to V31.

# NEXTBYTE Study Room File Picker and Attachment Management Fix — November 26, 2026

## Repairs applied

- Fixed the root cause of Shared Notes disappearing after choosing a file: browser focus/visibility restoration no longer redraws the room while the Create Note dialog or the creator's Replace Attachment editor is open. This preserves the in-progress form and the selected local `File` object when the native device file chooser returns.
- Kept normal room restoration active outside the note editors, so resuming a room still performs the existing room verification flow.
- Repaired owner recovery during room restoration. If a verified room owner has a legacy missing membership row, the app now restores that owner's own roster row before loading the room; non-owners without membership remain denied.
- Added creator-only Replace and Remove File actions to each note attachment. The edit flow can update the note title/content and optionally replace its attachment; leaving the replacement input empty preserves the current file.
- Replacement uploads use a new private Storage object path, update the note row filtered by the authenticated author, and remove the previous object after the metadata update succeeds. Failed note updates clean up the newly uploaded object.
- Removing an attachment detaches its metadata from the note and deletes the private Storage object while preserving the note itself. Empty notes are protected from being left without either text or an attachment.
- Kept Preview and Download connected to the existing member-authorized private Storage signed-URL and in-app preview pipeline.
- Bumped the PWA shell cache to `nexbyte-pwa-v28-file-picker-focus-restore-fix` so installed clients request the updated app shell.

## Verification

- All 12 inline JavaScript blocks passed Node.js syntax checks; `sw.js` passed Node.js syntax checks; `manifest.webmanifest` parsed as valid JSON; HTML parsing completed successfully.
- Chromium browser regression harness passed for a public room at 390×844 and a private personal room at 1280×800.
- The simulated native file-picker focus/visibility return preserved the Create Note dialog, the Replace Attachment editor, and each selected file. No room restore was started while either editor was open.
- Verified file selection preview, remove/reselect, note publishing with file metadata, Preview and Download action wiring, creator-only replacement, old-object cleanup, attachment removal while retaining the note, and rejection of editing another member's note.
- No browser JavaScript errors were recorded in the regression harness.
- Supabase Storage/database calls were mocked for the browser test. Live uploads, signed URLs, deployed RLS behavior, and device-specific Android/PWA file-picker behavior still require verification against the deployed Supabase project.

## Preserved

- Existing room schema, message payload model, private Storage bucket, and room-membership security policies.
- Existing public/private room behavior and the existing secure preview/download implementation.
- No database tables or policies were changed, and no existing user data or files were migrated or deleted.


## 2026-11-22 — PDF reader pinch zoom and fit-page repair

- Repaired the shared PDF.js viewer sizing so Fit Page uses both the available reading width and height.
- Added two-finger pinch-to-zoom, enlarged-page panning, Fit Page, Fit Width, and Reset controls.
- Improved portrait/landscape flex sizing, orientation/viewport resize handling, render cancellation, canvas memory budgeting, and cleanup.
- Bumped the PWA app-shell cache version to `nexbyte-pwa-v25-pdf-pinch-fitpage`.
- Android physical-device and live Supabase PDF verification remain required.

# NEXTBYTE Landscape File Preview Accessibility Enhancement — November 22, 2026

## Improvements applied

- Added a **Landscape view** control to the shared preview modal used by Study Hub materials, syllabus files, and task attachments.
- Added a wide, full-screen reading layout with mobile safe-area handling and an independently scrollable file-preview area.
- Added best-effort automatic landscape orientation locking through the Screen Orientation API; browsers that do not permit it retain the wide layout and can be rotated manually.
- Added automatic wide layout when the device is already in landscape orientation with a short viewport.
- Improved touch target sizes for PDF navigation and zoom controls, and increased the bounded maximum PDF zoom level.
- Added cleanup for orientation locks and fullscreen state when the user exits landscape mode or closes the preview.
- Updated the service-worker app-shell cache namespace to `nexbyte-pwa-v24-landscape-file-preview`.
- Added `TESTING_REPORT_LANDSCAPE_PREVIEW_ACCESSIBILITY.md`.

## Verification

- All 9 inline JavaScript blocks passed Node.js syntax checks.
- `sw.js` and `api/link-preview.js` passed Node.js syntax checks.
- All inline stylesheet blocks parsed without CSS syntax errors.
- Static checks confirmed the landscape control, orientation API fallback, fullscreen cleanup, responsive landscape layout, and expanded PDF zoom range.
- Actual device rotation, PDF readability, and live Supabase file rendering still require testing on a deployed Android device/PWA.

---

# NEXTBYTE Study Hub File Preview Repair — November 22, 2026

## Repairs applied

- Fixed the shared preview-panel initialization error: `deviceButton` and `deviceInput` are now retrieved from the created preview panel before event handlers are registered. Previously, the undefined references threw a `ReferenceError` after the modal appeared, preventing the file loader from starting and leaving the preview at `Loading preview...`.
- Added bounded waits for authentication, signed-URL creation, remote file retrieval, PDF.js asset retrieval, PDF document parsing, and page rendering so failures surface as actionable errors instead of an indefinite loading state.
- Added a Retry preview action that reuses the current preview panel and secure file-loading path.
- Bumped the service-worker app-shell cache namespace to `nexbyte-pwa-v23-study-file-preview-fix` to publish the repaired shell to installed PWA clients.
- Added `TESTING_REPORT_STUDY_HUB_PREVIEW_FIX.md` with the root cause, changes, local checks, and live-test limitations.

## Preserved

- Existing NEXTBYTE theme, layout, branding, authentication, and PWA configuration.
- Existing Supabase Storage bucket (`user-study-files`), signed-URL access flow, ownership checks, and private-file protections.
- Existing shared preview handlers for Syllabus Materials, Syllabus attachments, and Tasks attachments.
- Existing PDF.js renderer, supported file-type preview logic, download/offline logic, and current data model.
- No Supabase SQL changes, storage-policy changes, file migrations, or deletion of user files were made.

## Verification

- All 9 inline JavaScript blocks passed Node.js syntax checks.
- `sw.js` and `api/link-preview.js` passed Node.js syntax checks.
- `manifest.webmanifest` parsed as valid JSON.
- Static checks confirmed corrected preview control bindings and shared preview wiring for Syllabus Materials, Syllabus attachments, and Tasks.
- Live Supabase retrieval and Android/PWA visual testing remain deployment-dependent; see the testing report.

---

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

## November 20, 2026 — Study Hub subject Add Task button repair

- Replaced the subject Tasks tab's inline Add task handlers with explicit `type="button"` controls carrying the current subject ID in a data attribute.
- Added a delegated click handler for subject-task creation so the action calls the currently installed global `window.openTaskSheet` implementation directly, avoiding stale or mismatched inline function bindings after the layered task-editor enhancements.
- Added a guard that verifies the selected subject exists and that the task editor actually opened. Failures now produce an actionable toast and console diagnostic instead of silently doing nothing.
- Explicitly synchronized the legacy global `openTaskSheet` identifier with the enhanced task editor function for other existing callers.
- Bumped the PWA cache namespace to `nexbyte-pwa-v10-study-task-button-fix` so installed NEXTBYTE clients fetch the repaired task button logic.
- No Supabase schema, Storage bucket, or user data changes were required.


## November 20, 2026 — Study Hub Add Task runtime error correction

- Fixed the actual runtime error reported by the user: `nbProfileName is not defined` when the Study Hub Add Task action opened the enhanced task editor.
- Root cause: the profile-name helper was declared inside an earlier script's private IIFE, while the later task-editor repair layer called it from a different IIFE. The earlier helper was therefore not in scope.
- Added a local `nbxProfileName()` helper inside the task-editor repair layer. It safely reads the current authenticated profile name and falls back to `Member` when the profile has no display name.
- Replaced all five out-of-scope references in the enhanced task editor and Tasks renderer. The original helper references inside their original script closure remain unchanged.
- Preserved Add Task subject preselection, task attachments, task saving, and the existing profile/authentication model.
- Bumped the PWA cache namespace to `nexbyte-pwa-v11-task-profile-scope-fix` so installed clients request the corrected JavaScript.
- No database migration, Storage bucket change, or user-data modification is required.


## November 20, 2026 — Task attachment Preview label and action clarity

- Changed the Study Hub subject task attachment action label from **Open** to **Preview** and added an eye icon, title text, and accessible label.
- Kept the Preview action connected to the existing in-app `nbPreviewTaskAttachment` handler, which loads the attachment into the NEXTBYTE preview sheet using a private signed URL.
- Kept Download as a separate action connected to `nbDownloadTaskAttachment`, which requests a download-disposition signed URL and downloads the original file.
- No file paths, stored objects, task records, Supabase buckets, or database schemas were changed.
- Bumped the PWA cache namespace to `nexbyte-pwa-v12-task-attachment-preview-label` so installed clients fetch the changed task card label.
- No SQL migration is required.


## November 20, 2026 — reliable in-app preview and offline download

- Preview no longer points the viewer directly at a Supabase signed URL. It fetches the private file bytes and previews a Blob URL, so `Content-Disposition: attachment` cannot force the preview action into a download.
- PDFs are typed as `application/pdf` even when older metadata or storage responses report generic `application/octet-stream`, improving embedded PDF display in Android/PWA browsers.
- Download now fetches the original file, stores a device-local IndexedDB copy under the existing `offline_material_<storage-path>` key, and downloads the original filename from a Blob URL. The cache write is best-effort: a quota failure does not block the normal download and is reported to the user.
- Preview reuses the IndexedDB copy first and shows an **Available offline on this device** indicator when a local copy is present. The existing device-local offline cache and private Supabase bucket are reused; no database or Storage migration is required.
- PWA cache version bumped so installed clients refresh the updated preview and download code.


## November 20, 2026 — Study Hub PDF canvas preview and device-level offline access

- Integrated the newer preview implementation into the actual deployable project rather than leaving it only inside the nested repair ZIP.
- Redirected every legacy `openMaterial()` call to the same in-app preview handler and removed the older direct browser-tab/download override.
- Replaced the PDF iframe/native-handler path with PDF.js canvas rendering and page navigation, zoom, and fit-to-width controls.
- Added Open from Device, a visible loading indicator, duplicate-preview protection, and media/document compatibility messages.
- Added DOCX and spreadsheet previews. PPT/PPTX remain preserved but are not rendered in-app.
- Added account ownership metadata and checks for IndexedDB file copies so a cached cloud file is not reused by a different signed-in account.
- Offline-ready status now requires the page to be controlled by the service worker as well as having the matching PDF.js runtime and prepared document record.
- The PDF.js main/worker files are loaded from a pinned CDN and cached per device; they are not included as compiled assets in `vendor/pdfjs`. `vendor/pdfjs/README.md` documents that distinction.
- Updated the service-worker cache namespace to `nexbyte-pwa-v17-file-preview-device-picker`. No Supabase schema, bucket, or policy migration was added.
- Static JavaScript/HTML checks passed. Live Supabase, Vercel, CDN, and Android-device tests remain pending; see `TESTING_REPORT.md`.


## November 20, 2026 — Unified preview routing and stale-PWA correction (r3)

- Fixed the remaining Syllabus card action that called the legacy signed-URL/new-tab handler. Syllabus Preview now calls `nbPreviewSyllabusFile(subjectId, index)` and Syllabus Download uses the separate `nbDownloadSyllabusFile()` action.
- Kept Task attachment Preview connected to `nbPreviewTaskAttachment()` and Materials Open/Preview connected to `nbPreviewStudyMaterial()`.
- Redirected legacy `nbOpenSignedFilePublic()` calls for the private `user-study-files` bucket through the shared in-app renderer; download requests remain separate.
- Hardened visible filename selection so UUID-shaped storage IDs are not shown as the filename when a real filename or path basename is available.
- Updated PDF.js module initialization to prefer the pinned package URL (preserving module-relative resource resolution) and fall back to the saved module Blob when the CDN import is unavailable. The main module and worker remain pinned to the same `pdfjs-dist` release.
- Bumped the service-worker cache namespace to `nexbyte-pwa-v18-unified-file-preview-r2`, forced a service-worker update check with `updateViaCache: none`, and added a one-time reload after a new worker takes control so an installed PWA does not continue displaying the old preview screen.
- Preserved `supabase-config.js`, private bucket configuration, existing Storage paths, and the IndexedDB database.
- The ZIP's `vendor/pdfjs/` directory contains a README only, not bundled PDF.js code. The loader now deliberately obtains both PDF.js main and worker modules from the same pinned CDN release so a stale or mismatched vendor file cannot break rendering.
- Static HTML/JavaScript/manifest/ZIP checks passed for this build. Live Supabase, Vercel, CDN, and Android runtime tests still require the user's deployed environment.

## Study Room Public / Private Access Upgrade
- Added public room discovery and join workflow.
- Added owner-only personal private rooms without invite codes or chat.
- Added room visibility and owner metadata in the Study Room directory.
- Added Supabase RLS migration and public-room join RPC.
- Bumped the service-worker cache namespace to v19 for the updated app shell.


## November 22, 2026 — Public Study Room chat repair

- Restricted shared message deletion to the authenticated message author, including when the author is the room host.
- Added an explicit confirmation and in-room local removal after Supabase confirms deletion.
- Added room-filtered Realtime refresh for message and poll-vote changes; the SQL migration sets `REPLICA IDENTITY FULL` so filtered DELETE events contain the previous `room_id`.
- Replaced browser prompt dialogs for link/file-link sharing and poll creation with validated NEXTBYTE sheets.
- Replaced prompt-based link/file-link forms with validated, safer share sheets and clear supported-content descriptions.
- Reworked the Public Room Files tab with file type/size details and in-app previews that fetch room files through short-lived signed URLs after Storage authorization. Download remains available.
- Added a dedicated poll-vote table with a unique `(poll_message_id, user_id)` key, database voting rules, result counts, and creator-only poll closing.
- Incremented the service-worker app-shell cache to v21 for the final chat/file preview update.
- The supplied project source did not contain a hard-coded visible `nexbyte-mu.vercel.app` label; the new share sheets do not render a domain banner.

## Validation limits

Static syntax and package integrity checks were run locally. The Supabase migration was not run against the live project, and true two-account Realtime behavior, Vercel deployment, Storage signed URLs, and Android browser UI still require live testing.


## November 26, 2026 — Study Room My Notes and Shared Notes composer repair

- Reworked the active Study Room Notes view so the Shared Notes/My Notes list is the primary page content, with a separate **Create note** dialog instead of an always-visible form merged beneath the list.
- Added a selected-file card that appears immediately after choosing an attachment and displays the original filename, extension/type, size, upload readiness, and an appropriate document icon. Image selections display a local thumbnail; PDF/image files have a Preview action.
- Added Remove and reselect support, immediate validation feedback, and cleanup of temporary thumbnail object URLs. Existing 20 MB limit, accepted file types, private Storage bucket, per-room/per-user path, and signed in-app preview/download flow are preserved.
- After a successful save, the composer closes, its fields reset, and the new note appears at the top of the list without a manual refresh. Private rooms use My Notes / Save note to my room wording; public rooms use Shared Notes / Share note with room.
- Added owner-only recovery for legacy room rows missing the room owner's roster entry. The repair first verifies `study_rooms.owner_id` against the authenticated user and never enrolls a non-owner or changes room access policies.
- Bumped the service-worker cache namespace to `nexbyte-pwa-v27-shared-notes-composer-preview`. No SQL migration, new bucket, public Storage access, or schema change was added.

## November 26, 2026 — Shared Notes commit verification and stale-refresh persistence repair

- Reworked the active note submit flow to wait for successful room-file upload and a server-confirmed `study_room_messages` row before closing the Create Note dialog or reporting success.
- Added exact-payload verification after an ambiguous insert response to avoid duplicate submissions when the server may already have committed the note.
- Kept the note composer and draft intact on upload, insert, and verification failures; added safe cleanup for definitely unreferenced uploaded files.
- Added a short-lived cache for confirmed note commits so concurrent/stale room message refreshes cannot immediately hide a new note. Fresh database reads remain authoritative; successful deletes clear the cached record and note edits refresh the cached payload.
- Preserved `room_type` when loading shared rooms so private rooms render the My Notes state correctly.
- Bumped service-worker cache to `nexbyte-pwa-v29-shared-note-commit-persistence-fix`.
- Inspected the connected Supabase project read-only: RLS is enabled, private-room payload validation allows `shared-note`, and `study-room-files` is a private 20 MiB bucket with room-member-scoped policies. No database schema or policy changes were made.
- Local submit-flow and stale-refresh harness tests passed; real authenticated uploads and Android/Vercel end-to-end testing remain pending.

## 2026-11-26 – Shared Notes attachment selection and upload reliability

- Capture the selected browser `File` object at file-picker change time and retain it by Study Room ID so native Android/PWA input replacement does not lose the attachment before submission.
- Use delegated change handling for the dynamically rendered Shared Notes file input.
- Block silent text-only submission when the composer still indicates that an attachment is selected but the file object is missing.
- Display the active Storage upload stage and verify the saved object path before creating the shared-note message.
- Preserve the note draft and attachment selection when upload or database saving fails.
- Bumped the PWA service-worker cache to `nexbyte-pwa-v30-shared-note-file-object-retention-fix`.

## November 27, 2026 — V34 Shared Notes post-save attachment workflow

- Removed file selection from the Create Note / Create Personal Note form. Notes are saved first; attachments are added or replaced afterward from the saved note card.
- Added a per-note attachment manager with note context, selected-file validation/preview, remove/reselect controls, and upload status.
- Preserved private room storage and existing room membership/creator checks.
- Improved attachment and note action buttons with consistent icons, labels, accessible names, and mobile touch targets.
- Kept Edit Note focused on title/content while preserving attachment metadata.
- Updated the service-worker cache to `nexbyte-pwa-v34-post-save-note-attachment-workflow`.
- Local Chromium/Supabase-mock regressions passed for public/private workflows, attachment addition/replacement, text-only note isolation, independent attachment associations, and mobile dialog width. Live device testing remains required.
