# NEXTBYTE repair layer 4.2 — change summary

This package is based on the latest NEXTBYTE repository ZIP previously uploaded in this conversation and the prior repaired build. It keeps the single-page HTML application and existing Supabase configuration.

## Reported issues addressed in source

- **Study materials and syllabus:** selection-triggered upload, extension and 20 MB validation, visible upload status, private user-folder storage paths, cloud workspace metadata write, rollback of in-memory metadata on failed save, and best-effort Storage cleanup.
- **Shared room files:** validates the selected document, checks authenticated room membership, uploads to the room/user folder, writes a shared-file message, and removes the Storage object if message insertion fails.
- **Shared notes:** supports text-only, file-only, and text-plus-file sharing, membership validation, clear status messaging, and best-effort cleanup after failure.
- **Duplicate room cards:** serializes concurrent room-list loads, fetches shared memberships/rooms, rebuilds shared-room state, and deduplicates displayed rooms by stable ID. This does not delete database rows or merge rooms with different IDs.
- **Whiteboard:** visible exit control, browser fullscreen plus CSS fallback, Escape key handling for fallback mode, responsive portrait/landscape toolbar layout, resize snapshot/contain behavior, and autosave attempt after canvas resize.
- **Buttons:** improved minimum sizes, padding, alignment, text wrapping, action row wrapping, and disabled styling.
- **PWA cache:** updated cache version; manifest orientation changed to `any` so it does not declare a portrait-only orientation.

## New SQL migration

`NEXBYTE_UPLOAD_STORAGE_FIX.sql` creates/updates private `user-study-files` and `user-music` buckets and adds owner-folder select/insert/update/delete policies for authenticated users. It does not delete files or existing user rows.

## Preserved

- Existing `supabase-config.js` copied byte-for-byte from the uploaded repository. Do not overwrite it with a placeholder or with an older version if you changed credentials later.
- Existing application theme, routes, workspace, storage bucket names, and PWA architecture.
- Existing `schema.sql` and `NEXBYTE_ENHANCEMENTS.sql` carried into the package.

## Testing boundary / limitations

Static parsing and syntax validation are performed on the generated files. Live Supabase Storage upload, RLS, Vercel deployment, mobile installation, cross-device synchronization, and two-user room interaction have not been executed here.

Supabase Storage requests in this implementation show stage/status messages rather than byte-accurate upload percentages. Whiteboard persistence is snapshot-based, so simultaneous concurrent drawing can still result in last-write-wins behavior. Existing broad permissive RLS policies must be reviewed because permissive PostgreSQL policies are OR-combined.
