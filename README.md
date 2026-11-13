# NEXTBYTE — Academic Collaboration Environment

NEXTBYTE is a single-page academic workspace built with HTML, CSS, JavaScript, and Supabase. This repository version preserves the existing interface and Supabase account configuration and adds a repair layer for persistence, subject files, syllabus attachments, task details, shared-room activities, quizzes, whiteboards, music behavior, and PWA installation.

## Deployment

1. Deploy the repository root to Vercel over HTTPS.
2. Keep `supabase-config.js` beside `index.html`. It must contain only the Supabase project URL and public anon/publishable key. Never add a service-role or secret key to browser code.
3. Keep `manifest.webmanifest`, `sw.js`, `icon-192.png`, and `icon-512.png` in the repository root.
4. Run `schema.sql` only if the personal `user_workspaces` table has not already been created.
5. Review and run `NEXBYTE_ENHANCEMENTS.sql` in the Supabase SQL Editor to add the dedicated multi-whiteboard table and the accompanying room/storage policies. Back up first and review any older policies that may be more permissive.
6. Commit changes to the branch connected to Vercel and wait for the deployment to show **Ready**.

For the detailed setup steps, supported upload formats, limits, testing checklist, and known limitations, read `README_SETUP.txt`.

## Features in this repair build

- Supabase authentication and per-user workspace persistence.
- Local account-scoped recovery snapshots and queued cloud saves.
- Subject materials and separate syllabus file attachments.
- Detailed personal tasks and status tracking.
- Solo and Room Lock-In descriptions, with member focus status in shared rooms.
- Shared room messages, tasks with individual member responses, notes, and files.
- Configurable room practice quizzes with multiple question types.
- Multiple persistent room whiteboards, fullscreen drawing tools, and Realtime refresh.
- Adjustable Notes editor text size.
- Music pause when the app is backgrounded, with track/position restoration for manual resume.
- Installable PWA manifest, icons, and service-worker app-shell caching.

## Important limitations

- The app and SQL have not been deployed or executed against your live project as part of file generation. Test the actual Supabase policies and workflows before public use.
- The personal workspace is still stored as one JSONB document; simultaneous edits from different devices can be last-write-wins.
- Room quizzes are currently practice-only; answer keys are readable by room members. Do not use them for secure examinations.
- Whiteboards save whole-canvas snapshots. Concurrent drawing can cause the latest snapshot to replace another user's latest drawing; stroke-level merge is not implemented.
- Room Lock-In publishes each member's focus status, not a single synchronized server-authoritative timer. Music remains personal to each device.
- Existing broad RLS policies may weaken newly added policies because permissive policies are OR-combined. Review the full policy list.

See `CHANGELOG.md` for the repair summary and `NEXBYTE_ENHANCEMENTS.sql` for the room/database migration.
