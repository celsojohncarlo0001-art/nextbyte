NEXTBYTE CLOUD FILE RECOVERY + STORAGE DELETE FIX

WHAT WAS FOUND
Supabase Storage already contained uploaded study-file objects, but the subject records in user_workspaces had empty materials and syllabusFiles arrays. The application therefore had file bytes in Storage but no workspace references to display in Study Hub.

WHAT THIS BUILD CHANGES
1. After sign-in, NEXTBYTE lists each current subject's private user-study-files folders and reconstructs missing material/syllabus references from existing Storage objects.
2. Recovered references are saved back into the signed-in user's user_workspaces row, then the app refreshes so the files appear in Study Hub.
3. Older direct subject-folder uploads (userId/subjectId/filename) are recovered as study materials.
4. Profile > Settings now includes Manage cloud files. It lists the signed-in user's accessible study files, music, and shared-room files, including unlinked older uploads.
5. The manager provides Open, Download, and Delete from cloud actions. Deletion removes the actual Supabase Storage object and removes its workspace or room-message reference when one exists.
6. The service-worker cache version is increased so devices fetch the updated app shell.
7. Existing per-item Delete/Remove actions in Materials, Syllabus, Music, and Shared Room Files remain available.

IMPORTANT STORAGE NOTE
Deleting the app shortcut or uninstalling the PWA from a phone does NOT delete files stored in Supabase. To reduce Supabase Storage usage, use Profile > Settings > Manage cloud files > Delete from cloud, or delete a file from its relevant Materials/Syllabus/Music/Room list.

SUPABASE
No new SQL migration is required for this fix. The connected NEXTBYTE project was inspected: user-study-files, user-music, and study-room-files buckets exist as private buckets; authenticated Storage policies for personal study/music files and room-member access policies are already present. Keep RLS enabled. Do not add a service-role key to the browser.

DEPLOY
1. Back up your GitHub repository.
2. On the main branch, replace index.html with this package's index.html.
3. Replace sw.js and manifest.webmanifest.
4. Keep icon-192.png, icon-512.png, and nexbyte-background.png in the repository root beside index.html.
5. Keep your current supabase-config.js unchanged. It is intentionally not included in this ZIP so your real public project configuration is not overwritten.
6. Keep schema.sql and all existing SQL migration files.
7. Commit to main and wait for Vercel to report Ready.
8. Close existing NEXTBYTE browser tabs fully, reopen the deployed app online, and sign in. The app will attempt to recover missing file references once per account per page load. You can also use Profile > Settings > Manage cloud files > Recover missing subject files.

TEST
1. Open Study Hub > a subject > Materials. Previously uploaded files under that subject should be restored into the list.
2. Open the subject's Syllabus tab and check recovered syllabus attachments.
3. Open Profile > Settings > Manage cloud files. Check that the storage objects appear, including any files from old/deleted subjects marked as Unlinked / older subject.
4. Delete a test file from the manager and confirm it disappears from Storage and from its subject/music/room reference.
5. Upload a new small PDF, refresh, and confirm it still appears.

VERIFICATION STATUS
Static JavaScript syntax, HTML parsing, manifest JSON, service-worker syntax, image dimensions, and ZIP integrity were checked. Supabase tables, bucket existence, and relevant Storage policies were inspected read-only. A live authenticated browser upload/delete test was not performed here; verify it after deployment.
