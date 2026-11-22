# NEXTBYTE landscape file-preview accessibility enhancement

## Changes made

### `index.html`
- Added a **Landscape view** control to the shared file-preview modal used by Study Hub materials, syllabus files, and task attachments.
- Added a full-screen, wide-layout mode for the preview modal, with safe-area padding for mobile devices.
- Added best-effort Screen Orientation API locking to landscape after the user activates the control. The viewer remains usable in wide mode if a browser does not permit automatic orientation locking.
- Added automatic full-width layout when the device is already in landscape orientation and has a short viewport.
- Made the preview content area expand to use available height and made PDF controls easier to tap in landscape mode.
- Added a short hint explaining that users can turn their device sideways and use the PDF zoom controls.
- Expanded the bounded PDF zoom range to improve magnification for users who need larger on-screen content.
- Added orientation/fullscreen cleanup when the preview is closed.

### `sw.js`
- Updated the app-shell cache version to `nexbyte-pwa-v24-landscape-file-preview` so installed NEXTBYTE clients can fetch the updated interface.

## Compatibility notes

- The Landscape view control always enables the wider full-screen preview layout.
- Automatic physical screen rotation is best-effort only. Browser support and permission depend on the browser, operating system orientation setting, and whether the page is running in a fullscreen or installed-app context. If automatic rotation is unavailable, the user can rotate the device manually; the preview will use the landscape layout when the browser viewport changes orientation.
- PDF page scaling is recalculated after the layout changes using the existing resize observer and window resize handler.

## Local verification

- Parsed all 9 inline JavaScript blocks with Node.js syntax checking: **passed**.
- Parsed `sw.js` with Node.js syntax checking: **passed**.
- Parsed `api/link-preview.js` with Node.js syntax checking: **passed**.
- Parsed all inline stylesheet blocks with `tinycss2`: **passed**.
- Static assertions for the landscape control, accessibility state, full-screen request, orientation locking/unlocking, automatic landscape CSS, and expanded PDF zoom range: **passed**.
- HTML structure and stylesheet blocks were inspected after patching.

## Requires live/device testing

- Actual physical rotation and orientation-lock behavior on Android Chrome and installed NEXTBYTE PWA.
- Landscape PDF rendering and zoom on a real mobile device.
- Landscape behavior for images, Word documents, and spreadsheets.
- Regression testing against live Supabase files in both Syllabus Materials and Tasks.

No Supabase SQL changes, storage-policy changes, or user-file migrations are required.
