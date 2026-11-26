NEXTBYTE — STUDY HUB PREVIEW REPAIR (DEPLOYMENT NOTES)

DEPLOY TO GITHUB + VERCEL
1. Make a backup of the current repository first.
2. Extract the complete corrected ZIP on your phone or computer.
3. Upload the extracted project files to the same repository paths, replacing the old index.html and sw.js. Do not upload the ZIP as a single file.
4. Keep supabase-config.js unchanged. Do not replace the Supabase project URL or public anon/publishable key. Never put a service_role key in browser code.
5. Commit the changes to the branch connected to Vercel and wait for the deployment to show Ready.
6. Open NEXTBYTE while online. The new service worker checks for updates and reloads the page once when it takes control. If the app does not visibly reload, close the installed PWA and open it again while online.

WHAT WAS FIXED
- Study Hub Materials, subject Syllabus, and Task attachments now route to one shared in-app preview pipeline.
- Legacy nbOpenSignedFilePublic() and openMaterial() callers for the private study bucket are redirected to the in-app preview/download handlers rather than opening a new tab or a browser-native PDF prompt.
- PDFs use PDF.js to render actual pages to an HTML canvas, with page navigation, zoom, and fit-to-width. The viewer shows loading and error states.
- The preview uses authenticated private Supabase Storage access and keeps the existing user-study-files bucket and existing paths.
- Original filenames are preferred over UUID-like storage object names.
- Download & Save Offline stores a separate IndexedDB Blob with filename, MIME type, file/path identifiers, and account ownership. Open from Device previews files selected through the device file picker without uploading them.
- Service worker cache version is v19 for the updated Study Room application shell. It checks the network for a fresh app shell and removes older NEXTBYTE app-shell caches while leaving IndexedDB user files alone.
- A one-time reload on service-worker controller change helps avoid showing an old preview panel after deployment.

PDF.JS / VENDOR FOLDER
The vendor/pdfjs folder in this ZIP contains a README only; the compiled PDF.js runtime is not physically bundled. The current loader deliberately obtains both the main module and worker from the same pinned pdfjs-dist 6.5.438 CDN release, stores them in IndexedDB, and caches matching CDN resources with the service worker during online preparation. This avoids accidentally combining an old vendor worker with a newer CDN main module. A README by itself is not a PDF.js engine.

This build does not load local vendor files. To move to a fully self-hosted PDF.js distribution later, both main and worker modules must be wired to the same local version together, and the matching auxiliary cmaps/, standard_fonts/, and wasm/ resources and their resource base URLs must be updated as one set. Never mix main and worker versions.

OFFLINE PREVIEW
- On each device, open NEXTBYTE online after deployment.
- Let the service worker take control and allow the one-time reload.
- Open the cloud PDF and select Download & Save Offline.
- Wait for the app to confirm that both the file and viewer runtime have been prepared.
- Reopen it after closing the preview, then test with the network disabled.
- Cloud file copies and browser runtime caches are device-specific; repeat the save process on each device.
- A file downloaded outside NEXTBYTE must be selected with Open from Device; a web app cannot silently browse the phone's Downloads folder.

VALIDATION LIMITS
Static code checks are included in TESTING_REPORT.md. Live Supabase retrieval, actual PDF rendering on an Android phone, offline use after deployment, and Vercel deployment have not been tested from this local environment.

NEXTBYTE STUDY ROOM PUBLIC / PRIVATE VISIBILITY UPGRADE
1. Open Supabase Dashboard > SQL Editor.
2. Run NEXTBYTE_STUDY_ROOM_VISIBILITY.sql AFTER NEXTBYTE_ROOM_SCHEMA.sql and NEXTBYTE_ENHANCEMENTS.sql have already been applied.
3. Existing collaborative rooms remain invite-only and hidden from public discovery, while their memberships and invite codes continue to work. This avoids unexpectedly exposing old room metadata.
4. New Public Rooms appear in the signed-in public directory and can be joined there or with a public room invite code.
5. New Private Rooms have no invite code, a capacity of one, owner-only database access, and no chat/messaging interface.
6. Upload the updated index.html and SQL file to the GitHub repository. No service-role key is required or added to the frontend.


PUBLIC STUDY ROOM CHAT REPAIR (November 22, 2026)

After the existing room schema and room enhancement SQL have already been
installed, and after NEXTBYTE_STUDY_ROOM_VISIBILITY.sql has been run, execute
NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql in Supabase Dashboard > SQL Editor. This
adds the author-only message DELETE policy, Realtime old-row support, and the
database-backed poll vote table. It preserves existing room messages and file
objects. Do not skip this SQL migration: frontend button hiding alone is not
security.

Then deploy the updated index.html and sw.js from this project to the Vercel-
connected GitHub branch. Close and reopen NEXTBYTE while online so the v21
service-worker cache can install. Test with two separate authenticated accounts.


NEXTBYTE PUBLIC STUDY ROOM CHAT REPAIR (November 22, 2026)
1. In Supabase Dashboard > SQL Editor, run NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql AFTER these migrations have already been applied:
   - NEXTBYTE_ROOM_SCHEMA.sql
   - NEXTBYTE_ENHANCEMENTS.sql
   - NEXTBYTE_STUDY_ROOM_VISIBILITY.sql
2. The new migration makes message deletion author-only, enables room-filtered Realtime DELETE updates, and creates the unique poll-vote table. Do not skip it: the client-side poll voting requires study_room_poll_votes.
3. The study-room-files bucket remains private. Room-file Preview now uses a short-lived signed URL after Supabase Storage authorizes the room member, then renders the downloaded Blob through NEXTBYTE's in-app file preview.
4. Upload the extracted project files to the same GitHub paths, replacing index.html and sw.js. Keep supabase-config.js unchanged. Commit to the Vercel-connected branch and wait for Ready.
5. Test with two authorized accounts in the same Public Room: one account should not see another person's Delete control; each account can delete only its own messages; deletion should disappear from both screens without reopening the room. Also test link sharing, uploaded file preview/download, and poll create/vote/change/close.

The source ZIP did not contain a hard-coded visible nexbyte-mu.vercel.app label. Share cards avoid rendering a hostname banner.


STUDY ROOM SHARED NOTES + TASKS REPAIR (November 25, 2026)

- Deploy the updated index.html and sw.js from this ZIP to the existing Vercel-connected project. Keep supabase-config.js and its public publishable/anon key unchanged.
- No new SQL migration is required for this frontend repair. Confirm the existing room schema, NEXTBYTE_ENHANCEMENTS.sql, room visibility SQL, and public-room chat repair have already been applied as appropriate.
- The existing study-room-files bucket must remain private, with the existing room-member read policy and user-folder upload policy. Do not make the bucket public and do not add broad RLS policies.
- Shared notes now show file name/type/size and provide in-app Preview and Download. Attachments are restricted to supported academic document/image formats and 20 MB.
- Shared Notes and Tasks now place their lists and forms inside one full-height scrollable panel. All joined members can publish notes/tasks, and each member's task response/status is saved as their own room-message row.
- The new PWA cache is nextbyte-pwa-v35-branding-background-fix. Open NEXTBYTE online after deployment and close/reopen the installed PWA if it continues showing the previous interface.
- Follow TESTING_REPORT_STUDY_ROOM_NOTES_TASKS.md to verify with two separate authenticated room accounts.
