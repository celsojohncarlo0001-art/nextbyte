NEXTBYTE — FILE UPLOAD, ROOM DEDUPLICATION, WHITEBOARD ORIENTATION & UI REPAIR
===============================================================================

PACKAGE CONTENTS
- index.html: existing NEXTBYTE app with repair layer 4.2 appended. The original app/theme and current Supabase client integration are retained.
- supabase-config.js: copied byte-for-byte from the uploaded repository. Keep this file as-is unless you intentionally change the Supabase project or publishable key.
- schema.sql: original schema file copied from the uploaded repository.
- NEXBYTE_ENHANCEMENTS.sql: room/member/message policies and multi-whiteboard table migration from the prior package.
- NEXBYTE_UPLOAD_STORAGE_FIX.sql: additional private Storage buckets/policies for personal study materials, syllabus attachments, and music.
- manifest.webmanifest, sw.js, icon-192.png, icon-512.png: installable PWA files. Manifest orientation is set to "any" so the installed app is not declared portrait-only.
- CHANGELOG.md: changes and known limitations.

WHAT THE NEW REPAIR LAYER DOES
1. Subject materials and syllabus attachments start uploading after a valid file is selected. It shows validation/status messages, writes to the existing private user-study-files bucket, then saves metadata to the user's workspace. If workspace metadata saving fails, it rolls back the in-memory record and attempts to remove the uploaded object.
2. Shared room file selection starts upload automatically. The app verifies room membership, stores the file under room-id/user-id/, and inserts a shared-file message. Failed message insertion triggers best-effort removal of the uploaded object.
3. Shared notes support note text, an attachment, or file-only notes. Selecting a valid attachment starts publishing; any text already entered is included. The room message is stored after Storage succeeds, with best-effort cleanup on failure.
4. Shared room list refreshes are coalesced while in flight. The UI deduplicates room cards by stable room ID and rebuilds the shared-room portion of state instead of repeatedly appending copies.
5. Whiteboard fullscreen includes a visible Exit Fullscreen button, native fullscreen with a full-viewport CSS fallback, Escape support, and portrait/landscape responsive controls. Canvas resize snapshots the current image and fits it into the resized canvas rather than clearing it.
6. Button and file-input styling is normalized with responsive wrapping, consistent minimum heights, padding, alignment, and disabled states.
7. Service-worker cache version is incremented so the updated shell can replace the old cached copy.

UPLOAD FORMATS / LIMITS IN THIS REPAIR LAYER
- Study materials, syllabus attachments, shared room files/notes: PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, TXT, MD, CSV, PNG, JPG/JPEG, WEBP; maximum 20 MB each.
- Music upload uses the existing audio-specific flow and allows the existing audio formats; maximum 50 MB per track.
- The application checks file extensions and the Supabase Storage bucket enforces its own size limits. Confirm your bucket settings match these limits.

SUPABASE SQL ORDER
1. Back up your Supabase project/schema first.
2. Your existing base schema/room schema should already be installed.
3. If not already run, run NEXBYTE_ENHANCEMENTS.sql first. It expects public.study_rooms, public.study_room_members, and public.study_room_messages to exist. It creates the study_room_boards table and room-file policies.
4. Run NEXBYTE_UPLOAD_STORAGE_FIX.sql in Supabase SQL Editor. This creates/updates private user-study-files (20 MB) and user-music (50 MB) buckets and adds authenticated owner-folder policies on storage.objects. It does not delete existing files or user rows.
5. Do NOT paste index.html, sw.js, or supabase-config.js into SQL Editor. Only files ending in .sql belong there.

RLS NOTE
PostgreSQL permissive RLS policies are OR-combined. If an older policy grants broader access to storage.objects, adding these owner-folder policies does not cancel the older grant. Review existing policies on storage.objects and remove/replace only old policies that you have positively identified as obsolete or too broad. Do not disable RLS to make uploads work.

GITHUB / VERCEL DEPLOYMENT
1. Extract the package.
2. In the existing GitHub repository, use the main branch.
3. Replace index.html with this package's index.html.
4. Add/replace manifest.webmanifest, sw.js, icon-192.png, and icon-512.png in the repository root (same folder as index.html).
5. Keep your configured supabase-config.js. The included copy matches the uploaded repository at the time it was inspected; if you have changed the file since then, keep the newer configured version instead.
6. Keep schema.sql and other existing project files. Add the two new SQL files to the repository for reference, but GitHub/Vercel will NOT execute SQL files automatically.
7. Commit changes to main. Wait for Vercel to report Ready, then test the deployed site while online.
8. If the browser still serves old files, perform a hard refresh/clear the installed PWA's site cache and reopen it online so the v3 service worker can install.

IMPORTANT TESTING BOUNDARY
This package has static validation only. It has NOT been deployed to your Vercel project, and no live Supabase Storage request or SQL execution was performed during this repair. Real upload success depends on your current project's bucket configuration, RLS policies, Supabase key/URL, account session, and deployment.

The source changes are designed to address the reported issues, but the following must still be verified in the live app:
- Upload a small PDF in Study Hub and check Materials.
- Upload a syllabus file.
- Upload a room file while signed into a room member account.
- Add a shared note with an attachment.
- Verify the files remain after refresh and on a second authorized device.
- Create one room, leave it, navigate away/back, and confirm only one card appears.
- Draw in portrait, enter fullscreen, rotate to landscape, draw, exit fullscreen, and confirm the drawing remains.

KNOWN LIMITATIONS
- Supabase Storage uploads through the existing client expose request state but do not show byte-by-byte network percentages in this simple HTML client.
- Multi-device whiteboard collaboration still uses whole-canvas snapshots. Two people drawing at exactly the same time can overwrite the latest snapshot; this is not stroke-level CRDT collaboration.
- Room membership, room-file access, and board access depend on the room SQL migration and the full current RLS policy set.
- Existing workspace JSONB saves can still be last-write-wins when multiple devices edit the same user's workspace simultaneously.
- Offline copies remain per-device; a cloud-stored file needs internet on a new device until downloaded for offline use there.

SECURITY
- The frontend must use only the Supabase publishable/anon key.
- Never put sb_secret or service_role keys in supabase-config.js, HTML, JavaScript, GitHub, or Vercel static assets.
- Do not publish screenshots containing keys or account access tokens.
