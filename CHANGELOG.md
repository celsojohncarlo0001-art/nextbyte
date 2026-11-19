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
