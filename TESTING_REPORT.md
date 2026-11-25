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


---

# Study Room Public / Private Upgrade (November 22, 2026)

Implemented the two room types in `index.html` and added `NEXTBYTE_STUDY_ROOM_VISIBILITY.sql`. Public rooms are discoverable and joinable by authenticated users. Private rooms are owner-only, have a NULL invite code and capacity one, and remove all chat UI/actions while retaining supported personal study tools. Existing collaborative rooms migrate to Public.

The PWA cache namespace was incremented to `nexbyte-pwa-v19-study-room-visibility`. Static checks for the updated HTML, JavaScript, service worker, and package are recorded in `TESTING_REPORT_STUDY_ROOMS.md`. The new SQL migration still needs to be applied in the user's Supabase project, then verified with two separate accounts. Live Supabase, Vercel, and Android tests have not been performed in this environment.


---

# NEXBYTE UI and collaboration safety repair (November 25, 2026)

## Source changes in this package

- Added base icon paths for `cloud`, `heart`, `repeat`, `shuffle`, and `volume` to prevent empty SVG output for those named controls. The shared icon render helpers now mark decorative SVGs as hidden from screen readers.
- Scoped responsive text/button layout fixes to Music and Lock-In, protecting the known-working Study Hub from a global button restyle. Music tabs can wrap, the music upload action can grow, and library track rows reflow at narrow viewport widths while preserving all four icon actions.
- Added accessible names and titles to mini-player and Lock-In icon-only controls.
- Changed the Lock-In countdown to compute from a persisted absolute deadline. Pausing/resuming, reset, completion, and the final room-mode abandon wrapper now clear or recalculate the deadline and interval. This improves background-tab accuracy but remains a local per-browser countdown, not a shared server clock.
- Added optimistic concurrency checks to shared whiteboard snapshot writes using the previously loaded `updated_at` value. Stale clients are rejected with a recovery message rather than silently replacing a newer saved snapshot. This does not merge simultaneous drawing strokes.
- Bumped the service-worker cache namespace to `nexbyte-pwa-v26-icons-music-lockin-room`.
- Resized the 512px PWA icon asset to exactly 512 × 512 and adjusted its manifest purpose to `any`.
- Updated the Supabase deployment instructions to include the public/private visibility and poll/message repair migrations in order. The Supabase config was not changed and no credentials were added.

## Checks performed for this repair

Source-level validation completed: all 9 non-empty inline JavaScript blocks passed syntax parsing; `sw.js`, `supabase-config.js`, and `api/link-preview.js` passed syntax parsing; HTML parsing succeeded; all 5 embedded CSS stylesheets parsed without reported CSS syntax errors; manifest JSON parsed; declared icons matched their actual dimensions (192 × 192 and 512 × 512); all 57 literal icon references resolved against 64 base icon names; the viewport permits browser zoom; and the v26 cache namespace and core repair markers were present. `npm run validate` reruns the JavaScript, viewport, icon, manifest, cache, and feature-marker checks.

## Not tested / cannot be claimed as passed

- Live Supabase authentication, RLS policies, Storage authorization, Realtime updates, or migrations. This package has no access to the user's Supabase SQL Editor or project credentials.
- Two-account Study Room operation after migrations. This must be tested against the actual Supabase project. Shared notes/tasks/files/whiteboards/polls rely on room message/table migrations, membership records, policies, Storage, and Realtime setup.
- Vercel production build/deployment or deployed service-worker activation.
- Actual audio playback across browser/device combinations.
- Physical Android/iOS screen layouts, touch behavior, PWA installation, or assistive-technology testing.
- Fully concurrent whiteboard stroke merging. The current repair prevents stale snapshot overwrite but retains snapshot storage.
- Server-authoritative room Lock-In timer synchronization. Room status remains a per-member focus-status update.
- Secure exam-grade quiz answer protection, push notification delivery, or real account deletion through Supabase Auth.

## Required post-deployment verification

1. Back up Supabase and apply the shared-room migrations in the order documented in README.md. Do not run the SQL blindly against an unknown existing schema.
2. Sign in with two separate test accounts, create/join a Public Room, and test notes, tasks, files, poll create/vote, whiteboard save/reload, room membership, and chat in both directions.
3. Verify private-room and file Storage access with an account that is not a member; unauthorized requests must fail.
4. Test Music and Lock-In on narrow phones and desktop. Verify all visible labels, icons, track rows, timer controls, pause/resume, background/foreground, and audio playback.
5. Confirm Study Hub subjects, materials, syllabus, notes, tasks, and attachments still work as before.
6. Open the deployed site online and confirm the service worker activates with cache namespace `nexbyte-pwa-v26-icons-music-lockin-room`.

Do not interpret passing static checks as proof that external services, collaboration, or all user workflows work in production.
