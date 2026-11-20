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
- Service worker cache version is v18. It checks the network for a fresh app shell and removes older NEXTBYTE app-shell caches while leaving IndexedDB user files alone.
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
