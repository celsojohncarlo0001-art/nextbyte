# NEXTBYTE Study Room File Picker Regression Test Report

Date: 2026-11-26

## Issue reproduced from code inspection

The room-resume handler called `scheduleRestore()` whenever the browser regained focus or visibility while a cloud room was open. Selecting a local file temporarily moves focus away from the page. Returning from the operating-system file chooser therefore triggered a room restore, whose render replaced the Shared Notes DOM. This discarded the active composer or edit overlay and its selected file reference. A legacy room owner with no roster row could also be misclassified as unauthorized by the restore routine.

## Changes

1. Defer focus/visibility room restoration while either Shared Notes Create Note or Replace Attachment is open, or while one of those file inputs is the active element.
2. Retain normal restore checks outside the note editor.
3. During restore, verify the room row before deciding membership is missing. Repair only the authenticated room owner's missing roster row; do not auto-enroll non-owners.
4. Add author-only replace/remove attachment UI and server requests filtered by the authenticated note author.
5. Use a new Storage object for replacements and clean up the previous object only after the note metadata has been updated.
6. Keep the current signed-URL preview/download pipeline for private room files.

## Browser regression coverage

The Chromium harness used a mocked Supabase client and exercised:

- Public Shared Notes at a 390×844 viewport.
- Private My Notes at a 1280×800 viewport.
- Focus and visibility events after selecting a file in Create Note.
- Focus and visibility events after selecting a replacement file.
- Selected image thumbnail, remove, and reselect behavior.
- Note/file upload request and immediate display in the list.
- Preview and Download button handler arguments.
- Replacing an attachment, updating the note path/metadata, and removing the old path.
- Removing an attachment while retaining the note text.
- Hiding creator-only controls from another member and rejecting a direct edit attempt against that member's note.
- Zero browser JavaScript errors in the harness.
- Extracted the production `restoreRoom()` function and tested four membership cases: a private owner missing their roster row is restored; a public owner missing their roster row is restored; an existing public member is restored without an insert; and a non-owner with no membership remains unauthorized.

Result: PASS for all mocked browser flows and restore-membership cases.

## Static validation

- 12 inline JavaScript blocks: `node --check` passed.
- `sw.js`: `node --check` passed.
- `manifest.webmanifest`: valid JSON.
- HTML parser: successful.
- ZIP archive integrity: checked after packaging.

## Not verified against live services

The environment did not have an authenticated connection to the NEXTBYTE Supabase project. The tests therefore do not prove live Storage bucket settings, actual RLS behavior, file transfer, signed URL access, or real Android file chooser behavior. Those must be tested after the ZIP is deployed with the existing Supabase project configuration.
