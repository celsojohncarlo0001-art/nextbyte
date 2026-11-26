# NEXTBYTE Shared Notes V33 — File Selection and Action Buttons

## Changes

- The Shared Notes file input now carries the exact Study Room ID as a `data-room-id` attribute.
- The upload handler prefers that explicit room ID when capturing the selected `File`, instead of depending on router/hash state after the Android native picker returns.
- The legacy preview cache and the authoritative V33 upload cache use the same room identity, preventing the selected file from being treated as belonging to no room after an Android/PWA redraw.
- Attachment actions now have explicit icon+text labels, `aria-label` values, action identifiers, and a two-column responsive grid with larger touch targets.
- Creator-only Replace/Remove and Edit/Delete controls remain creator-restricted. Preview and Download remain available to room members who can access the note.
- The service-worker cache version was bumped to V33.

## Verification performed

- Inline JavaScript syntax checks: see final build check.
- HTML parsing and archive integrity checks: see final build check.
- Source-level regression assertions confirm room identity is taken from the file input's `data-room-id`, the cache is keyed to the explicit room, and all six action labels are present in the renderer.

## Limits

No live Supabase schema, bucket, RLS policy, or user data was changed. Automated local checks cannot replace an authenticated Android upload test against the deployed Vercel app.
