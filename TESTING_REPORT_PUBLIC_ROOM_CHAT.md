# NEXTBYTE Public Study Room Chat Repair — Validation Report

Date: 2026-11-22

## Source changes

- `index.html`: author-only chat deletion controls and request checks; realtime subscription for message and poll-vote changes; validated link/file-link share sheets; structured poll creation/voting/closing; Public Room Files tab detail cards; secure signed-URL fetch followed by NEXTBYTE in-app file preview.
- `sw.js`: app-shell cache namespace updated to `nexbyte-pwa-v21-public-room-chat-repair-inapp-files`.
- `NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql`: author-only message DELETE policy, poll-vote table and policies, poll option validation, replica identity, Realtime publication registration, and room-file delete ownership correction.
- `README_SETUP.txt` and `CHANGELOG.md`: setup and change notes.

## Local checks performed

- HTML document parsed with Python's standard HTML parser.
- All 8 non-empty inline JavaScript blocks passed `node --check`.
- `sw.js` passed `node --check`.
- `manifest.webmanifest` parsed as JSON.
- Static checks confirmed author-only delete predicates, filtering delete requests by authenticated user ID, message/vote Realtime subscriptions, `REPLICA IDENTITY FULL`, the unique poll vote key, poll option validation, HTTP/HTTPS URL validation, private Storage configuration, in-app room-file preview wiring, and the updated service-worker cache namespace.
- ZIP integrity was checked after packaging.

## Not tested in this environment

- The SQL migration was not executed against the user's live Supabase project.
- Supabase RLS behavior and Storage authorization were not exercised against a live database.
- Two-account message deletion and Realtime synchronization were not tested with two live signed-in accounts.
- Poll create/vote/change/close behavior was not tested against the deployed Supabase project.
- File previews and downloads were not tested against live Storage objects.
- Vercel deployment and Android browser/PWA behavior were not tested.

## Required deployment steps

1. In Supabase SQL Editor, run `NEXTBYTE_PUBLIC_ROOM_CHAT_REPAIR.sql` after the existing room schema, enhancements, and Public/Private visibility migrations have been applied.
2. Upload the extracted project files to the existing GitHub repository paths, replacing `index.html` and `sw.js`; keep `supabase-config.js` unchanged.
3. Commit to the branch connected to Vercel and wait for deployment to complete.
4. Test with two authenticated accounts in the same Public Room. Confirm each account can delete only its own messages and both screens update without reopening the room. Then test link sharing, private file preview/download, and poll creation/voting/closing.
