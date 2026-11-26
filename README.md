# NEXTBYTE — Academic Collaboration Environment

NEXTBYTE is a single-page academic workspace built with HTML, CSS, JavaScript, and Supabase. This repair package keeps the existing application architecture and protected navigation areas while addressing offline startup recovery, cloud file handling, shared-room database setup, and deployment documentation.

## Deployment and Supabase setup

1. Back up the current repository and Supabase database before deployment.
2. Deploy the repository root to Vercel over HTTPS. Keep `index.html`, `supabase-config.js`, `manifest.webmanifest`, `sw.js`, both icon files, and the background image assets in the same root folder.
3. Keep the existing `supabase-config.js` project URL and public publishable/anon key. It contains frontend configuration only; never add a service-role key or other secret to browser code.
4. In Supabase SQL Editor, inspect the existing tables first. If `user_workspaces` is missing, run `schema.sql`.
5. If the shared-room base tables are missing, review and run `NEXTBYTE_ROOM_SCHEMA.sql`. It creates missing `study_rooms`, `study_room_members`, and `study_room_messages` tables plus the invite-code join RPC. It does not drop or truncate existing rows. If same-named tables already exist with a different schema, compare their columns before running it.
6. Run `NEXTBYTE_ENHANCEMENTS.sql` after the base room tables exist. It applies room/member/message access policies, the whiteboard table and policies, room-file storage policies, and Realtime publication entries.
7. Review `NEXTBYTE_UPLOAD_STORAGE_FIX.sql` separately. Run it only if the relevant personal storage buckets or policies are missing or need repair. Supabase permissive policies are OR-combined, so inspect and remove obsolete broad policies deliberately rather than adding policies blindly.
8. Commit the source changes to the branch connected to Vercel and wait for the deployment to show **Ready**. Open the deployed site online once so the new service worker can install and cache the app shell.

See `README_SETUP.txt` and `TESTING_REPORT.md` for known limitations, verification status, and post-deployment checks.

## Existing application modules retained

- Home dashboard and bottom navigation.
- Study Hub, subject materials, syllabus attachments, notes, and tasks.
- Study Rooms, chat, shared tasks, shared notes, shared files, and member status.
- Lock-In Workspace.
- Music library and player.
- Quiz Builder and practice participation.
- Whiteboards.
- Profile, settings, notifications, and cloud file manager.
- Supabase authentication, workspace persistence, local snapshots, and PWA installation.

## Repairs made in this package

- Restore the last account-scoped local workspace when NEXTBYTE starts offline and the Supabase JavaScript CDN is unavailable, provided that account previously authenticated and saved a snapshot on that device.
- Clear the local last-account marker when signing out.
- Reload after connectivity returns from an offline startup so the Supabase client can initialize and normal cloud session/workspace recovery can resume.
- Open cloud and room files in a browser tab reserved synchronously before the asynchronous signed-URL request, reducing popup-blocker failures.
- Delete a shared-room Storage object before cleaning its message reference, avoiding an unlisted orphan when Storage deletion fails.
- Add the missing shared-room base schema and secure invite-code RPC as a separate SQL migration.
- Bump the PWA cache version so deployed devices fetch the repaired app shell.

## Important limitations

- The code has not been deployed to your Vercel project or executed against your live Supabase database from this environment. Apply the SQL in the documented order and verify the real project after deployment.
- The personal workspace is stored as one JSONB document. Simultaneous edits from different devices can still be last-write-wins.
- Room quizzes are practice-only because answer keys are included in room-visible message data. Do not use them for secure examinations.
- Whiteboards save whole-canvas snapshots. Concurrent drawing can cause a newer snapshot to replace another user's latest drawing; stroke-level merging is not implemented.
- Room Lock-In shares each member's focus status, not a server-authoritative synchronized countdown timer. Music playback remains device-specific.
- Notification preferences are stored, but external push/email delivery is not configured by this source package.
- Account deletion from the authentication provider is not implemented as a client-side operation.
- Offline account recovery uses a local snapshot on that device. Cloud data and private cloud files still require a network connection, and downloaded offline file copies do not automatically transfer to another device.
- Existing permissive Supabase policies can weaken intended restrictions because permissive policies combine with OR semantics. Review the full policy list before public use.

Do not describe any external integration as verified until the authenticated live test is complete.


## Study Hub subject attachments

When a user enters or re-renders a subject, NEXTBYTE now recursively scans the authenticated account's private `user-study-files/<user-id>/` tree and reconnects objects to the matching subject by an exact subject-ID directory segment. This supports legacy root-level files and nested `materials/`, `syllabus/`, `attachments/`, and other folder layouts. References are deduplicated by full Storage path. The scan is delayed briefly and retried a limited number of times to tolerate mobile authentication startup timing. New uploads now re-resolve the open subject by ID after the Storage request, attach to the current live workspace object, update the local snapshot, and re-render the Materials list immediately before waiting for the cloud workspace save. A temporary workspace-sync failure no longer deletes an uploaded Storage object; the app keeps the local attachment and clearly reports that cloud sync is pending.

No additional database migration is required for this repair. The existing `user-study-files` bucket must remain private, and the signed-in user's Storage `SELECT` policy must permit listing their own prefix. Review `NEXTBYTE_UPLOAD_STORAGE_FIX.sql` if the project has not already been configured with the private bucket and owner-folder policies.

Long Materials names remain contained in their rows, with the full name available through the title attribute. Syllabus titles and original filenames wrap safely inside their card using a constrained grid layout, so they cannot cover the Syllabus badge or extend beyond the card. File action controls remain visible on narrow layouts. The missing external/open icon in the Materials row is now included. The PWA cache was also versioned again so installed devices can receive the immediate-upload correction.

For live verification, upload a disposable PDF from a subject, confirm that it appears immediately, refresh, then sign into the same account on a second device and open that subject. Also verify previously uploaded Storage files appear without opening Manage Cloud Files.


## Study Hub Materials folders and video support

The Materials tab now opens to a folder overview only. It does not render individual uploaded file cards beneath the folder grid. Users open **All Files** or a category to see the file list. The supported logical folders are All Files, PDF Documents, Images, Word Documents, Video Files, Text Files, and Other Files.

Video Files categorizes MP4, WebM, MOV, and M4V. Supported video files use a responsive HTML5 video player in the existing preview sheet. Existing audio files are preserved and classified under Other Files; no Storage objects are moved, renamed, or deleted. Existing presentation and spreadsheet materials are also retained in Other Files. CSV remains in Text Files for Study Hub materials. Folder metadata is derived from extension and MIME data and saved in the existing workspace state; no extra Storage bucket or SQL migration is required.

The Materials overview has a single upload entry point. After uploading from the overview, the user is taken to All Files so the new material is visible. Uploads from an individual folder are checked against that folder's category. Private storage paths and the original cloud objects are unchanged.

## Task supporting-file attachments

The Create/Edit Detailed Task form now includes **Attach supporting files (optional)** directly beneath Step-by-Step Instructions. Users may select multiple files and review file names, types, and sizes before saving. Allowed file types include PDF, DOC/DOCX, images, TXT/Markdown, and supported video formats. Spreadsheet, presentation, CSV, and audio file types are rejected by extension and MIME checks. Each file is limited to 20 MB, consistent with the existing private bucket limit.

Task attachments are uploaded to the existing private `user-study-files` bucket under `<user-id>/tasks/<task-id>/...`. The task's `attachments` metadata is saved inside the existing `user_workspaces` JSON state, associated with task and owner IDs. No new table, bucket, or SQL migration is required. The existing Storage policy in `NEXTBYTE_UPLOAD_STORAGE_FIX.sql` expects the first path segment to equal `auth.uid()`; task attachment paths follow that rule. Task cards provide separate Preview and Download actions. Removing a saved attachment removes its workspace reference only after save, then attempts to remove the private Storage object. Deleting a task also attempts cleanup after the task deletion syncs.

## Verification status for this update

For the current preview correction, all eight inline JavaScript blocks passed Node.js syntax checking, `sw.js` passed Node.js syntax checking, and HTML plus manifest parsing passed. The handler routing and preview controls were also checked in source. Live Supabase access, real document rendering, cross-device sync, actual media playback, and Vercel deployment remain unverified; complete the real-device tests listed in `TESTING_REPORT.md` after deployment.

### Deployment note

Deploy the files in this project folder as the root of the existing Vercel project. Keep the existing `supabase-config.js`, project URL, and public anon/publishable key. The current service-worker cache namespace is `nextbyte-pwa-v35-branding-background-fix`; open NEXTBYTE online after deployment so the updated worker can install and activate.

## Latest follow-up — Study Hub Add Task button

The subject Tasks tab now uses a delegated click handler for its Add task controls and calls the enhanced global task editor directly. The buttons are explicit `type="button"` elements, so they cannot accidentally submit an enclosing form. If the editor is unavailable or fails to open, NEXTBYTE reports the issue rather than silently ignoring the click. See `TESTING_REPORT.md` for validation status.


### Add Task runtime-error fix

This build also includes a fix for the `nbProfileName is not defined` error in Study Hub → Subject → Tasks. The enhanced task editor now uses a profile-name helper defined in its own JavaScript scope. No SQL or Supabase configuration change is required.


## File preview and offline copies (November 20, 2026)

- Study Hub Materials, syllabus files, and task attachments share one private-file preview pipeline. Legacy `openMaterial()` calls route to the in-app viewer; preview does not use the old direct signed-URL/download handler.
- PDFs render with PDF.js into an HTML canvas, with page navigation, zoom, and fit-to-width controls. Images, text/Markdown, CSV, audio, video, DOCX, and XLS/XLSX use format-specific previews. PPT/PPTX are preserved and show a compatibility message in this build.
- **Open from Device** uses the browser file picker to read a file locally without uploading it. **Download & save offline** downloads the original filename and saves a separate account-tagged copy in this device's existing IndexedDB cache.
- The pinned PDF.js main/worker assets and the DOCX/XLSX preview libraries load online on first use and are cached on that device. PDF offline-ready status is not shown until the PWA service worker controls the page and the PDF preparation pass completes. The compiled PDF.js distribution is not physically bundled under `vendor/pdfjs`; see that folder's README.
- Offline copies are device-specific and account-scoped. Each device must download the file and prepare its preview engine independently. Browser storage quota and media codec support can affect offline preview or playback.


## Study Room Shared Notes and Tasks repair (November 25, 2026)

The Study Room Notes and Tasks tabs now use one full-height, vertically scrollable content area that contains both the record list and its creation form. The list can no longer consume the available height while leaving the composer clipped below the room panel.

- Every joined room member can publish their own shared note or task. The server-side membership check is performed before creating the record; the existing Supabase Row Level Security policies remain the actual authorization boundary.
- Notes support text-only, attachment-only, and text-plus-attachment submissions. Supported files are PDF, Word, PowerPoint, Excel, TXT, Markdown, CSV, PNG, JPG, and WEBP up to 20 MB. Uploads use the existing private `study-room-files` bucket and the existing room/user folder layout.
- Shared note cards display the author, date, file name, type, and size, with separate in-app Preview and Download actions. Failed message inserts attempt to remove a just-uploaded orphan file.
- Tasks include a category, optional due date, detailed instructions, author/date metadata, and separate per-member response/status records. Response updates are filtered by room, message row, and the authenticated user ID so another member's response is not overwritten.
- Existing note edit/delete actions and task-author delete actions remain available. Existing room SQL schema and policies are reused; no new table or policy broadening is introduced.
- The service-worker cache namespace is now `nextbyte-pwa-v35-branding-background-fix` so installed clients fetch the updated room interface.

No new SQL migration is included for this repair. The deployment must already have the existing room schema, `NEXTBYTE_ENHANCEMENTS.sql`, the room visibility migration, and the public-room chat repair installed as applicable. In particular, the private `study-room-files` bucket must exist with the existing member-read and user-folder upload policies. Do not add permissive policies or expose the bucket publicly to work around access errors.

Static JavaScript, HTML, and manifest checks are recorded in `TESTING_REPORT_STUDY_ROOM_NOTES_TASKS.md`. Live two-account Supabase behavior and Vercel deployment have not been tested from this environment; use the two-account verification steps in that report after deploying.
