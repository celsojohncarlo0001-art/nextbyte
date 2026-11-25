# NEXTBYTE — Academic Collaboration Environment

NEXTBYTE is a single-page academic workspace built with HTML, CSS, JavaScript, and Supabase. This repair package keeps the existing application architecture and protected navigation areas while addressing offline startup recovery, cloud file handling, shared-room database setup, and deployment documentation.

## Deployment and Supabase setup

1. Back up the current repository and Supabase database before deployment.
2. Deploy the repository root to Vercel over HTTPS. Keep `index.html`, `supabase-config.js`, `manifest.webmanifest`, `sw.js`, both icon files, and the background image assets in the same root folder.
3. Keep the existing `supabase-config.js` project URL and public publishable/anon key. It contains frontend configuration only; never add a service-role key or other secret to browser code.
4. In Supabase SQL Editor, inspect the existing tables first. If `user_workspaces` is missing, run `schema.sql`.
5. If the shared-room base tables are missing, review and run `NEXBYTE_ROOM_SCHEMA.sql`. It creates missing `study_rooms`, `study_room_members`, and `study_room_messages` tables plus the invite-code join RPC. It does not drop or truncate existing rows. If same-named tables already exist with a different schema, compare their columns before running it.
6. Run `NEXBYTE_ENHANCEMENTS.sql` after the base room tables exist. It applies room/member/message access policies, the whiteboard table and policies, room-file storage policies, and Realtime publication entries.
7. Run `NEXTBYTE_STUDY_ROOM_VISIBILITY.sql` after the room schema and enhancements. It applies the public/private room visibility model.
8. Run `NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql` after the previous room migrations. It adds the poll-vote table and message deletion/Realtime repair required by the current shared-room UI.
9. Review `NEXBYTE_UPLOAD_STORAGE_FIX.sql` separately. Run it only if the relevant personal storage buckets or policies are missing or need repair. Supabase permissive policies are OR-combined, so inspect and remove obsolete broad policies deliberately rather than adding policies blindly.
10. Commit the source changes to the branch connected to Vercel and wait for the deployment to show **Ready**. Open the deployed site online once so the new service worker can install and cache the app shell.

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

No additional database migration is required for this repair. The existing `user-study-files` bucket must remain private, and the signed-in user's Storage `SELECT` policy must permit listing their own prefix. Review `NEXBYTE_UPLOAD_STORAGE_FIX.sql` if the project has not already been configured with the private bucket and owner-folder policies.

Long Materials names remain contained in their rows, with the full name available through the title attribute. Syllabus titles and original filenames wrap safely inside their card using a constrained grid layout, so they cannot cover the Syllabus badge or extend beyond the card. File action controls remain visible on narrow layouts. The missing external/open icon in the Materials row is now included. The PWA cache was also versioned again so installed devices can receive the immediate-upload correction.

For live verification, upload a disposable PDF from a subject, confirm that it appears immediately, refresh, then sign into the same account on a second device and open that subject. Also verify previously uploaded Storage files appear without opening Manage Cloud Files.


## Study Hub Materials folders and video support

The Materials tab now opens to a folder overview only. It does not render individual uploaded file cards beneath the folder grid. Users open **All Files** or a category to see the file list. The supported logical folders are All Files, PDF Documents, Images, Word Documents, Video Files, Text Files, and Other Files.

Video Files categorizes MP4, WebM, MOV, and M4V. Supported video files use a responsive HTML5 video player in the existing preview sheet. Existing audio files are preserved and classified under Other Files; no Storage objects are moved, renamed, or deleted. Existing presentation and spreadsheet materials are also retained in Other Files. CSV remains in Text Files for Study Hub materials. Folder metadata is derived from extension and MIME data and saved in the existing workspace state; no extra Storage bucket or SQL migration is required.

The Materials overview has a single upload entry point. After uploading from the overview, the user is taken to All Files so the new material is visible. Uploads from an individual folder are checked against that folder's category. Private storage paths and the original cloud objects are unchanged.

## Task supporting-file attachments

The Create/Edit Detailed Task form now includes **Attach supporting files (optional)** directly beneath Step-by-Step Instructions. Users may select multiple files and review file names, types, and sizes before saving. Allowed file types include PDF, DOC/DOCX, images, TXT/Markdown, and supported video formats. Spreadsheet, presentation, CSV, and audio file types are rejected by extension and MIME checks. Each file is limited to 20 MB, consistent with the existing private bucket limit.

Task attachments are uploaded to the existing private `user-study-files` bucket under `<user-id>/tasks/<task-id>/...`. The task's `attachments` metadata is saved inside the existing `user_workspaces` JSON state, associated with task and owner IDs. No new table, bucket, or SQL migration is required. The existing Storage policy in `NEXBYTE_UPLOAD_STORAGE_FIX.sql` expects the first path segment to equal `auth.uid()`; task attachment paths follow that rule. Task cards provide separate Preview and Download actions. Removing a saved attachment removes its workspace reference only after save, then attempts to remove the private Storage object. Deleting a task also attempts cleanup after the task deletion syncs.

## Verification status for this update

For the current preview correction, all eight inline JavaScript blocks passed Node.js syntax checking, `sw.js` passed Node.js syntax checking, and HTML plus manifest parsing passed. The handler routing and preview controls were also checked in source. Live Supabase access, real document rendering, cross-device sync, actual media playback, and Vercel deployment remain unverified; complete the real-device tests listed in `TESTING_REPORT.md` after deployment.

### Deployment note

Deploy the files in this project folder as the root of the existing Vercel project. Keep the existing `supabase-config.js`, project URL, and public anon/publishable key. The current service-worker cache namespace in this repair package is `nexbyte-pwa-v26-icons-music-lockin-room`; open NEXTBYTE online after deployment so the updated worker can install and activate.

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


## Current repair package — Music, Lock-In, room concurrency, and PWA UI (November 25, 2026)

- Added missing base SVG icon definitions for cloud, heart, repeat, shuffle, and volume controls; SVGs generated by the shared icon helper are marked decorative for assistive technology.
- Music and Lock-In controls receive narrowly scoped responsive layout rules. Music track rows reflow to a two-row layout on narrow phones so the track title and all four icon actions remain available. Music tab buttons and upload controls can wrap rather than clipping their labels.
- Added accessible names/titles to previously unlabeled mini-player and Lock-In icon controls.
- Lock-In now stores an absolute end timestamp and derives remaining time from the clock, rather than decrementing an interval counter. This reduces drift after browser throttling, backgrounding, or refresh. Abandon/reset/pause paths clear the deadline and timer. This remains a device-local timer; it is not a server-authoritative synchronized room countdown.
- Whiteboard saves use an `updated_at` compare-and-set check. A stale client is prevented from silently overwriting a newer snapshot. This is conflict detection, not stroke-level merging or a CRDT; reopen the board to load the latest snapshot after a conflict.
- Updated the service-worker cache namespace to `nexbyte-pwa-v26-icons-music-lockin-room` and resized `icon-512.png` to its declared 512 × 512 dimensions. The manifest no longer claims maskable purpose without a verified safe-area design.
- The Study Hub feature logic and database workflows were not intentionally changed. The shared final CSS changes are scoped to Music and Lock-In to avoid restyling Study Hub buttons.

### Study Rooms setup reminder

The shared-room experience depends on the Supabase schema and policies being installed in the same project used by `supabase-config.js`. Apply and verify, in order: `NEXBYTE_ROOM_SCHEMA.sql`, `NEXBYTE_ENHANCEMENTS.sql`, `NEXTBYTE_STUDY_ROOM_VISIBILITY.sql`, and `NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql`. Run `schema.sql` only if the personal `user_workspaces` table is missing. Review `NEXBYTE_UPLOAD_STORAGE_FIX.sql` separately for the personal file bucket; do not run it blindly. Back up the database and inspect existing policies first. If chat works but shared notes, tasks, files, polls, or whiteboards do not, check the relevant migration, room membership, Storage bucket, Realtime publication, and RLS policy before assuming the front-end button is broken.

### Remaining limitations and live checks

- This package cannot connect to or alter the user's live Supabase or Vercel project. SQL migrations must be reviewed and applied by the project owner in Supabase, then tested with two authenticated accounts.
- Room Lock-In sends focus-status records but the visible room status is not a server-authoritative shared timer. Each member's active countdown remains local to their browser.
- Whiteboards still store canvas snapshots. The new version check prevents last-write-wins overwrites but does not merge simultaneous strokes; a full collaborative drawing model needs an operation/stroke protocol or CRDT.
- Room quizzes retain the existing practice-oriented data model; do not treat them as secure examinations unless answer keys and grading are moved server-side.
- Notification preferences do not by themselves provide push/email delivery. Push delivery requires a configured backend and user permission.
- Account deletion still requires a secure server-side Supabase Auth deletion endpoint/function; never place a service-role key in the browser.
- Actual audio playback, live RLS/Storage permissions, two-account Realtime behavior, device-specific CSS, CDN preview dependencies, and Vercel deployment require post-deployment verification.
