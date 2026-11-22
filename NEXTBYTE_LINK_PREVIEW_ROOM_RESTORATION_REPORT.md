# NEXTBYTE Public Study Room — Link Preview and Room Restoration Repair

## Source inspection findings

The supplied `index.html` uses a hash-based router (`#/room/<room-id>`) and loads shared Study Rooms asynchronously from Supabase. The room renderer previously treated an empty in-memory room list as proof that the room did not exist. On a cold PWA/browser return, `loadWorkspace()` rebuilds the client state and renders before the later shared-room directory refresh completes. This creates a window in which a valid room route can incorrectly display **“Room not found.”** The supplied code also refreshed music UI on `pageshow`, but did not perform a room/session restoration and Realtime reconnect for the room route.

The existing chat already used external anchors with `target="_blank"` and `rel="noopener noreferrer"` for shared links. Existing private room-file uploads use Supabase Storage paths and signed access via the existing in-app preview flow; that mechanism is preserved.

## Changes made

### Room restoration

- A UUID-backed room route with no in-memory room now renders a restoration state rather than immediately declaring the room missing.
- The app verifies the current Supabase user, checks the user's membership row, fetches the room record, and obtains the member roster before restoring the room.
- It preserves the canonical room hash as the primary route. It does not auto-join a user based on an old room ID.
- It distinguishes temporary restoration failure, missing membership/access, and a room record that is genuinely missing after membership was confirmed.
- It restores messages and reattaches the existing room Realtime subscription after returning to the app.
- It listens for `pageshow`, `visibilitychange`, `focus`, and route changes. It saves/restores the current chat scroll position in `sessionStorage` only; no auth tokens or credentials are stored there.
- It retains the existing Public/Private room authorization checks. Private rooms remain owner-only.

### Link and file link previews

- Shared link and external file-link chat messages now render richer cards with a safe thumbnail when available, title, description, source/domain, resource classification, and original URL.
- YouTube video URLs are recognized, including watch, youtu.be, Shorts, embed, and live URL patterns. The metadata endpoint attempts YouTube oEmbed lookup and falls back to a standard YouTube thumbnail.
- Older link messages without saved metadata are hydrated in the chat where preview metadata can be retrieved; a fallback card keeps the URL usable if preview metadata is unavailable.
- Metadata is stored in the existing message body payload. No duplicate chat message table was introduced.
- User-supplied title overrides and metadata are rendered as escaped text, not executable HTML.
- The existing private Supabase Storage file preview and download flow is unchanged. A remote file URL is labelled as an external link and is not represented as a file uploaded into NEXTBYTE.

### Secure metadata endpoint

- Added `api/link-preview.js` for Vercel Node Functions.
- It accepts only HTTP/HTTPS URLs, rejects credentials in URLs, validates DNS answers against private/reserved addresses, pins the resolved address for the request, revalidates each redirect, limits redirects, request time, and HTML response size, and reads only HTML/JSON metadata rather than downloading file bodies.
- It does not forward user cookies, Supabase credentials, or secret keys and does not execute remote scripts.
- The endpoint returns metadata only; preview retrieval failure falls back to a usable link card.

### Android Chrome Share Target and PWA

- Added a Web Share Target to `manifest.webmanifest` for shared `title`, `text`, and `url` values.
- Incoming Chrome shares are validated, temporarily held as a non-sensitive pending-share payload, and presented with a chooser for a joined Public Study Room.
- The service-worker cache version was raised to v22 and `/api/` requests are excluded from static caching so metadata requests are not treated as app-shell assets.

## Files changed

- `index.html`
- `manifest.webmanifest`
- `sw.js`
- `api/link-preview.js` (new)
- `NEXTBYTE_LINK_PREVIEW_ROOM_RESTORATION_REPORT.md` (new)

No Supabase SQL migration was added because this implementation reuses the existing `study_room_messages.body` payload and existing membership, message, and Storage policies.

## Verification performed

- Parsed all inline JavaScript blocks with `node --check`.
- Parsed `api/link-preview.js` with `node --check`.
- Validated `manifest.webmanifest` as JSON.
- Invoked the metadata handler with mocked requests to verify that `javascript:` URLs are rejected (400), loopback/private destinations are rejected (422), and unsupported methods are rejected (405).
- Confirmed the service worker excludes `/api/` and uses the new cache version.

## Tests not performed

This environment does not have access to the user's deployed Vercel site, live Supabase project, Android device, installed PWA, or two authenticated test accounts. Therefore, live website metadata retrieval, the actual Chrome Share Target UI, Android app-switch/resume behavior, Supabase membership authorization, and multi-user Realtime behavior have **not** been claimed as passed.

## Deployment

Deploy the updated project with `index.html`, `manifest.webmanifest`, `sw.js`, and the new `api/link-preview.js` in the same Vercel project root. The Vercel project root must be the directory containing `index.html` and the `api/` folder so the metadata endpoint is deployed as a Node Function. No SQL Editor migration is required for these changes.

After deployment, refresh NEXTBYTE online so service worker v22 installs. For the Android Chrome Share Target, update/reinstall the installed PWA if Chrome continues showing an older installed manifest. Then test with a joined Public Room: open a YouTube/website/file link, return to NEXTBYTE, and confirm the same room and chat remain open. Repeat using the installed PWA and two authenticated accounts.
