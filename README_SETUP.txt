NEXTBYTE — FINAL REPAIR PACKAGE
================================

PACKAGE CONTENTS
- index.html: existing NEXTBYTE app plus the repair layer; preserves the existing theme and original Supabase client setup.
- supabase-config.js: copied unchanged from your uploaded repository. It contains your public Supabase project URL and publishable client key. Never replace it with a placeholder and never put a service-role/secret key here.
- schema.sql: your original personal workspace table/RLS setup, copied unchanged.
- NEXBYTE_ENHANCEMENTS.sql: additional room RLS and multi-whiteboard schema/policies.
- manifest.webmanifest, sw.js, icon-192.png, icon-512.png: installable PWA support.

DEPLOY TO VERCEL
1. Download/extract this package on a computer or phone file manager.
2. In your GitHub `nextbyte` repository, replace index.html with this package's index.html.
3. Keep your existing supabase-config.js. The included copy is preserved from the uploaded repository, but do not replace it if you have subsequently changed your Supabase URL/key.
4. Add/replace these files in the repository root: manifest.webmanifest, sw.js, icon-192.png, icon-512.png.
5. Keep schema.sql. Add NEXBYTE_ENHANCEMENTS.sql to the repo so you have a backup/reference, but SQL files in the repo are NOT run automatically by Vercel.
6. Commit to the deployment branch. Wait for Vercel to show Ready, then reload the live site.

SUPABASE SQL
- Your existing project already had the original room tables and buckets based on the screenshots and supplied repository context.
- Run NEXBYTE_ENHANCEMENTS.sql in Supabase SQL Editor once after backing up/reviewing your project.
- It creates `study_room_boards`, adjusts the named policies, adds required table grants, and adds private room-file access policies. It does not delete application rows.
- This migration expects existing `public.study_rooms`, `public.study_room_members`, and `public.study_room_messages` tables with the columns used by the current app.
- Review existing policies before relying on this migration. PostgreSQL permissive RLS policies are combined with OR; an older broad policy can still allow access even after these narrower policies are added. Remove/replace only policies you have verified are obsolete or too permissive.
- Ensure the `study-room-files` bucket stays private. The migration creates it as private if it is missing.
- Supabase Storage access is controlled by policies on storage.objects; private file access uses signed URLs.

FEATURES ADDRESSED IN THIS BUILD
- More reliable per-user workspace save queue and device-local recovery snapshots.
- Study material upload validation, private upload paths, immediate workspace metadata save, open/remove controls, and clearer file instructions.
- Separate syllabus attachments with open/download/replace/remove controls.
- Detailed personal task editor and delete controls.
- Clearer Solo vs Room Lock-In description and room focus check-ins.
- Prevents repeated room-create actions while the existing asynchronous creation request is running.
- Shared room task responses stored separately per participant.
- Room practice quiz builder for multiple choice, true/false, identification, fill-in-the-blank, and short answer with user-selected item count.
- Shared notes and room-file uploads with format/size instructions, metadata, and signed-link handling.
- Multiple named room whiteboards, persistence, delete confirmation, fullscreen, touch/mouse drawing tools, and optional Realtime refresh.
- Larger adjustable Notes editor text.
- Removes the two requested profile options while retaining other profile behavior.
- Main music and embedded YouTube playback pauses when the page is hidden; selected track/position is retained for manual resume; shuffle/repeat icon paths are included.
- PWA icon URLs now match the repository-root icon files; service worker cache is versioned and does not intercept Supabase API routes.

UPLOAD LIMITS
- Study materials, syllabus attachments, shared notes/files: maximum 20 MB per file in the app layer.
- Accepted extensions: PDF, DOC/DOCX, PPT/PPTX, XLS/XLSX, TXT, MD, CSV, PNG, JPG/JPEG, WEBP.
- Supabase bucket size limit and Storage policies must also allow the same limit and paths.

IMPORTANT LIMITATIONS — READ BEFORE PUBLIC USE
1. Static validation is not live integration testing. This package has not been deployed to your Vercel project, and its SQL has not been run against your live Supabase database from this session. Sign-in, upload permissions, RLS behavior, and cross-account access must be tested in the live project.
2. Workspace state remains a single JSONB row per user. The local snapshot is per-device recovery only; cloud sync is what transfers data to another device. Simultaneous edits from multiple devices can still be last-write-wins; this is not a conflict-free merge system.
3. Shared room practice quizzes currently keep question/answer data in room message payloads visible to authenticated room members. Do not use them for secure exams or confidential assessments. Secure answer keys/scoring require server-side grading and a protected answer-key table/function.
4. Shared room whiteboards save a canvas snapshot for each board. Concurrent users drawing at exactly the same time can overwrite another user's most recent snapshot; this is not a stroke-level collaborative canvas/CRDT. The canvas image is stored as text in Postgres, so avoid very large boards; very large snapshots may exceed practical API row limits.
5. Room Lock-In shares individual focus status/check-ins, not a single server-authoritative synchronized room timer. Music in Lock-In remains personal to each device and is not broadcast to room members.
6. Background playback pause is triggered when the browser reports the page hidden/pagehide. Mobile browsers may suspend pages unexpectedly; test on your actual Android browser. Returning to the app requires the user to press Play again.
7. Offline app-shell caching does not cache private Supabase API responses. Cloud-only files require internet on a new device unless the user separately downloads them for offline use on that device.
8. Existing broad Supabase policies may weaken the new restrictions because permissive RLS policies are OR-combined. Review the complete policy list for rooms, memberships, messages, and storage before inviting other users.
9. This is not a security audit or a production certification. Use only public publishable/anon key in the browser. Never expose the service-role or secret key.

VALIDATION PERFORMED FOR THIS PACKAGE
- JavaScript syntax checks for inline app scripts and service worker.
- Manifest JSON parse check.
- HTML parser check.
- ZIP integrity check.
- Path/icon existence checks.

NOT PERFORMED
- Live Vercel deployment.
- Live Supabase SQL execution or policy advisor scan.
- Browser end-to-end tests with two independent accounts/devices.
- Actual Android PWA installation, push notifications, or background lifecycle testing.

Suggested live smoke test after deployment:
A. Sign in and create a subject; reload and check it remains.
B. Upload a small PDF; open/download it, sign in on another device, and confirm it is visible there.
C. Create a room with Account A; join using Account B; create one room task and quiz, submit different responses from each account, and verify submissions remain separate.
D. Create two whiteboards, draw/save on both, reload, and switch between them.
E. Start a music track, go to the phone home screen, return, and confirm it is paused at the previous position.
F. Verify Account B cannot read Account A's private personal workspace or private study materials.
