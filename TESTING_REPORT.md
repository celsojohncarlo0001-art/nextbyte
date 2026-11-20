# NEXTBYTE — Study Hub Preview Repair Testing Report (r3)

Date: November 20, 2026

## Scope of this repair

Inspected the user-provided NEXTBYTE ZIP and the reported preview screenshot. The screenshot shows a PDF preview sheet with an “Available offline on this device” status, but its content area is still a generic PDF icon, a UUID-like string, and a second Open button. That is not the current canvas-renderer interface and indicates that the app is still using an older preview implementation or an old cached application shell.

The supplied project contains a `vendor/pdfjs/README.md`, but not the compiled PDF.js main module or worker. The app is CDN-backed and uses the pinned `pdfjs-dist@6.5.438` runtime with IndexedDB and service-worker caching; the README is not treated as a PDF.js engine.

## Changes included

- Routed Syllabus Preview cards away from the old `nbOpenSignedFilePublic()` signed-URL/new-tab path and into `nbPreviewSyllabusFile(subjectId, index)`.
- Preserved separate Syllabus Download behavior through `nbDownloadSyllabusFile()`.
- Kept Study Hub Materials connected to `nbPreviewStudyMaterial()` and Task attachments connected to `nbPreviewTaskAttachment()`.
- Redirected legacy `nbOpenSignedFilePublic()` calls for the private `user-study-files` bucket to the shared in-app preview renderer; other buckets retain the prior handler.
- Hardened original filename selection so UUID-shaped storage identifiers are skipped where a better filename or path basename is available.
- Updated PDF.js initialization to use the version-pinned package module URL first and the saved IndexedDB module Blob as a fallback; both main and worker resources are always obtained from the same pinned CDN release, avoiding accidental mixing with an older vendor copy.
- Updated service worker cache namespace to `nexbyte-pwa-v18-unified-file-preview-r2`; app navigation fetches bypass stale HTTP cache, registration forces a check for updated worker code, and the page reloads once after a new worker takes control.
- Preserved existing Supabase configuration, private Storage bucket/path model, existing IndexedDB store, and database schema.

## Automated checks completed in this environment

| Check | Result | Scope |
|---|---|---|
| HTML parsing | PASS | `index.html` parsed with BeautifulSoup's HTML parser. |
| Inline JavaScript syntax | PASS | All six non-empty inline JavaScript blocks passed `node --check`. |
| Service-worker JavaScript syntax | PASS | `sw.js` passed `node --check`. |
| PWA manifest | PASS | `manifest.webmanifest` parsed as valid JSON. |
| Syllabus Preview routing | PASS (static) | Syllabus preview button calls `nbPreviewSyllabusFile()`; download is separate. |
| Task attachment Preview routing | PASS (static) | Task attachment button calls `nbPreviewTaskAttachment()`. |
| Study Hub Materials routing | PASS (static) | Materials cards use `nbPreviewStudyMaterial()`; legacy `openMaterial` alias points to it. |
| Legacy private-file routing | PASS (static) | Final `nbOpenSignedFilePublic` wrapper routes `user-study-files` preview requests through `nbxPreviewPath()`. |
| PDF canvas renderer | PASS (static) | PDF.js `getDocument()` and `page.render()` canvas code is present; this preview path does not use a PDF iframe. |
| Updated PWA refresh | PASS (static) | Service-worker v18 namespace, update check, no-store navigation fetch, and one-time controller-change reload are present. |
| Supabase configuration preservation | PASS | `supabase-config.js` was kept unchanged from the supplied project ZIP. |
| Vendor folder audit | PASS | `vendor/pdfjs/README.md` exists; no local `pdf.mjs` or `pdf.worker.mjs` is present, and docs disclose the CDN-backed design. |
| ZIP integrity | PASS | The final archive was created and passed Python ZIP CRC/member validation. |

## Not tested / cannot be claimed as passed

- The live GitHub repository was not accessible through the connected GitHub account (no repositories were returned), so this package was patched from the uploaded project ZIP.
- Live Vercel deployment and the deployed branch/root path.
- Live Supabase authentication, signed-URL generation, private Storage policies, or actual user document retrieval.
- Actual PDF.js CDN module/worker load and page rendering on the user's Android browser. This container could not resolve the CDN host.
- Actual normal, multi-page, malformed, and generic-MIME PDF rendering in the target phone environment.
- Full offline replay after the service worker and PDF auxiliary CMap/font/WASM assets have been populated on the phone.
- Android file picker behavior, media codecs, DOCX/XLSX rendering, and regressions across all live NEXTBYTE screens.

## Deployment and verification steps

1. Back up the current GitHub repository. Extract the corrected ZIP and upload its contents to the same repository root/paths; do not upload only the ZIP file.
2. Keep `supabase-config.js` unchanged. Commit to the Vercel-connected branch and wait for Vercel to report Ready.
3. Open NEXTBYTE online. The new service worker checks for updates and reloads once when it takes control. If the page does not reload, close and reopen the installed PWA while online.
4. Open one PDF from Study Hub Materials, one Syllabus file, and one Task attachment. Each should display rendered pages inside the NEXTBYTE preview sheet without the generic icon/UUID/second Open button.
5. Test PDF previous/next page, zoom, and fit width.
6. Use Download & Save Offline, wait for the viewer-ready status, close and reopen the file, then test with the network disabled. Repeat on each device that needs its own offline copy.
7. Repeat with image, text, CSV, media, DOCX, and XLSX test files. PowerPoint remains preserved but is explicitly not rendered in-app in this build.

A successful static check is not evidence that the deployed website or Android device has passed these live tests.
