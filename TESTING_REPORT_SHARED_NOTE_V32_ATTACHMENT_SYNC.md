# NEXTBYTE Shared Notes V32 – Attachment Synchronization Repair

## Implementation changes

- Added a room-scoped committed-note overlay. A confirmed database row is inserted into the active room view immediately and is retained across stale or overlapping message refreshes until a normal database read returns the matching `shared-note` row and attachment path.
- Changed post-submit behavior to render the confirmed saved note immediately after upload and insert verification. The follow-up message refresh now runs in the background and reconciles against the committed row.
- Generated the note ID before upload and included it in the private Storage object path. The same ID is saved in the note payload, tying one file to one note.
- Validated the returned database payload's note kind, note ID, room ID, user ID, filename, and storage path before treating an attachment submission as complete.
- Synchronized the V32 File cache with the legacy selected-file preview cache. Removing an attachment, closing the composer, or opening a fresh composer now clears both caches and the native file input, preventing an old attachment from leaking into a later text-only note.
- Failed Storage or database operations keep the draft/composer available. An uploaded object is removed when a definite database failure leaves it unlinked.
- Preserved the existing private `study-room-files` bucket and the existing RLS model. No SQL, bucket visibility, or storage policy changes were made.
- Bumped the PWA cache to V32.

## Local regression checks

Executed a dependency-free Node VM harness using a simulated Supabase client. Passed checks:

- Public room: first attachment submission, stale refresh protection, subsequent text-only note, file removal, and later fresh-read reconciliation.
- Private room: same sequence.
- The second text-only note does not inherit the first note's file path or filename.
- Explicitly removing a selected file prevents it from being uploaded.
- A stale room-message refresh cannot remove a just-committed note from the active view.
- A later fresh read of the exact saved row retires the local overlay.
- Storage failure leaves the composer, title, content, and selected file in place and inserts no note row.
- Database insertion failure removes the orphan upload and keeps the composer open.

## Static validation

- All inline JavaScript blocks passed `node --check`.
- `sw.js` passed `node --check`.
- `manifest.webmanifest` parsed as valid JSON.
- `index.html` parsed successfully with Python's HTML parser.
- ZIP integrity check passed.

## Environment limits

The local submission tests use a simulated Supabase client. They do not replace a real authenticated Android/PWA upload test. The connected Supabase project's bucket and access policies were inspected read-only; this repair made no remote database or Storage configuration changes.
