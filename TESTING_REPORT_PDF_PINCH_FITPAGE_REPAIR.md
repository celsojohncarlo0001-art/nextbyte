# NEXTBYTE PDF Viewer Repair — Pinch Zoom, Fit Page, and Landscape Layout

## Source inspected

Used the uploaded `NEXTBYTE_LANDSCAPE_FILE_PREVIEW_ACCESSIBILITY.zip` as the source project. The repair was made in the existing shared PDF.js preview implementation in `index.html`; the PDF.js runtime, Supabase retrieval flow, file metadata, upload logic, and existing preview entry points were retained.

## Findings in the supplied source

- PDF scaling was calculated from available width only. There was no height-aware Fit Page mode.
- Initial zoom used the width-fit scale, which could make portrait pages taller than the visible reading viewport.
- The PDF canvas wrapper did not have a reliable flex-constrained height in the full-screen landscape layout, so the renderer could calculate against an unreliable reading area.
- No multi-touch pinch gesture handlers were connected to the shared PDF zoom state.
- Resize observation watched width but not height, which missed some orientation and viewport changes.
- The toolbar exposed only Fit width and did not provide Fit Page or Reset.

## Changes made

### `index.html`

- Reworked the existing PDF.js page renderer while retaining the same PDF.js version, worker setup, document fetch path, and shared preview function.
- Added a height-and-width-aware **Fit Page** scale; the entire page is visible at the fitted scale when the preview viewport can accommodate it.
- Preserved **Fit Width** as a separate mode.
- Added **Reset** to return to Fit Page.
- Connected zoom buttons and two-finger pointer-based pinch gestures to the same PDF.js zoom factor.
- Added one-finger panning when the rendered PDF page is larger than its reading viewport.
- Preserved the approximate document point under the pinch midpoint during zoom changes.
- Serialized/cancelled PDF render operations to avoid simultaneous rendering into the same canvas.
- Added render-pixel budgeting for lower-memory mobile devices.
- Added resize/orientation/visual-viewport handling and width-plus-height `ResizeObserver` checks.
- Added explicit flex sizing for the PDF reading area in portrait and landscape, with safe-area-aware full-screen landscape behavior retained. In compact landscape, the duplicate bottom Close button is hidden because the header close control remains available, giving more height to the document; file action buttons remain available in a compact row.
- Added cleanup for pointer listeners, observers, timers, and PDF resources when the preview closes.

### `sw.js`

- Bumped the app-shell cache to `nexbyte-pwa-v25-pdf-pinch-fitpage` so installed clients can retrieve the repaired application shell.

## Local verification performed

- Parsed all 9 inline JavaScript blocks with Node.js `--check`: **passed**.
- Parsed `sw.js` and `api/link-preview.js` with Node.js `--check`: **passed**.
- Parsed all 4 stylesheet blocks, including nested media rules, with `tinycss2`: **passed**.
- Static checks for Fit Page, Fit Width, Reset, pointer pinch handling, one-finger panning, resize observers, cleanup hooks, and the PWA cache version: **passed**.
- Ran a headless Chromium smoke test using an isolated mock PDF.js page renderer at 390×844 portrait and 844×390 landscape viewports: **passed**. Fit Page kept both portrait-oriented and landscape-oriented fixture pages within the reading viewport; Next changed the page label to `2 / 3`; synthetic two-pointer pinch events increased the rendered canvas width from 326 to 489 CSS pixels in portrait and from 283 to 424 CSS pixels in landscape; no browser page errors were observed.

The browser smoke test exercises the viewer layout and interaction logic using a PDF.js-shaped mock renderer. It does **not** prove that the live PDF.js CDN, an actual Supabase PDF, or physical Android touch hardware works end to end.

## Requires live/device testing

- Physical two-finger pinch and one-finger pan on Android Chrome.
- Physical screen rotation and full-screen mode in Android Chrome and installed PWA.
- Actual Supabase-hosted PDF opening in Syllabus Materials and Tasks.
- Visual confirmation using the user's original `HCI-Chapter5.pdf` and PDFs with portrait and landscape page dimensions.

No Supabase SQL, storage-policy changes, database migrations, or user-file changes are required by this frontend viewer repair.
