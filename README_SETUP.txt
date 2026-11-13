NEXTBYTE — ROOM FILE UPLOAD FIX

WHAT CHANGED
The room-file upload handler no longer requires the active room to already exist in the local S.rooms array. It verifies membership in study_room_members, loads the room by ID from study_rooms, uploads the object to the private study-room-files bucket, and inserts the message metadata in study_room_messages. Shared-note attachment upload uses the same room-resolution helper.

This directly addresses the screenshot error:
"Room file upload failed: Shared room not found. Reload the room and try again."

FILES
- index.html: corrected app file. Replace the current repository index.html.
- nexbyte-background.png: the existing NEXTBYTE global background; keep it beside index.html.
- manifest.webmanifest: installable PWA manifest, orientation any.
- sw.js: updated app-shell cache version; now also caches the background image and still bypasses Supabase API requests.
- icon-192.png / icon-512.png: PWA icons.
- supabase-config.js: exact public client config copied from the repository ZIP provided in this chat. Keep your latest valid config if you have changed it since that upload. Never put a service-role or secret key in this file.

DEPLOY
1. Back up the GitHub repository first.
2. On the main branch, replace index.html.
3. Keep nexbyte-background.png at the repository root next to index.html.
4. Replace sw.js and manifest.webmanifest; keep both icons at the root.
5. Keep your existing supabase-config.js if it is newer than this package.
6. Do not delete schema.sql, NEXBYTE_ENHANCEMENTS.sql, NEXBYTE_UPLOAD_STORAGE_FIX.sql, or other existing project files.
7. Commit the changes. Vercel should build the connected main branch.
8. After deployment, close old NEXTBYTE tabs completely, reopen the site online, and refresh once so the updated service worker activates.

SUPABASE
Read-only inspection of the connected NEXTBYTE project showed all three expected buckets exist as private buckets and authenticated upload policies exist. The current false room-not-found message occurs before Storage is contacted, so do not rerun or change SQL for this specific frontend bug. If a new message appears after this fix, use that exact message to diagnose the next step. Keep RLS enabled and never use a service-role key in the browser.

TEST AFTER DEPLOY
1. Sign in with the account that is already a member of the room.
2. Open the room, then open Files.
3. Choose a small PDF or PNG. Confirm the selected filename appears.
4. Tap Upload and share.
5. Confirm the file card appears and can be opened/downloaded.
6. Refresh and reopen the room; confirm the file remains.
7. Try an authorized second room member to verify shared access.
8. Test a small subject material and syllabus file separately.

VALIDATION
JavaScript syntax, HTML parsing, manifest JSON, service-worker syntax, and package integrity were checked. No live authenticated browser upload or second-account test was performed in this session.
