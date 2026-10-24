# NEXBYTE — account-based app build

This version removes the prefilled sample student/workspace data and demo bypass. It adds Supabase email/password authentication and private per-user workspace persistence. The UI remains a single-page HTML app.

## Setup (required before public use)

1. Create a Supabase project at https://supabase.com/.
2. In **SQL Editor**, run `schema.sql`.
3. Open **Project Settings → API** and copy the project URL and public anon/publishable key.
4. Put those two values into `supabase-config.js`. Do not use a `service_role` or secret key in browser code.
5. In Supabase **Authentication → URL Configuration**, set the production site URL and add the local/deployed app URL to allowed redirect URLs.
6. Configure email confirmation and SMTP according to your deployment needs. Keep confirmation enabled for public registration.
7. Serve this folder over HTTP(S) (not `file://`). For example, use a static host or run a local web server from this folder.
8. Test registration, email confirmation, login, workspace changes, reload persistence, password reset, sign-out, and access isolation using two separate accounts.

## Included functionality

- Supabase Auth account registration and login
- Password reset email flow
- Per-account workspace state stored in Postgres JSONB
- Row Level Security policies so authenticated users can access only their own workspace row
- Empty starting workspace (no fake student or example assignments/rooms)
- No demo bypass

## Important limitations to resolve before calling this production-ready

- **This is not a fully audited production deployment.** You must configure Supabase, deploy over HTTPS, test the live setup, and review privacy/security requirements.
- The current app persists a user's workspace as one JSON document. Study rooms/messages are not yet a true shared multi-user real-time collaboration service; separate users do not automatically see the same room/chat data. A normalized schema plus membership checks and Realtime policies is needed for that.
- Account deletion is deliberately not falsely simulated in the browser. To support secure full account deletion, add a server-side Supabase Edge Function with appropriate authorization that deletes the auth user and cascades their workspace row. Never expose a service-role key in the client.
- File/material downloads and music entries in the original UI may be placeholders. Review each action before advertising it as implemented.
- Test all app workflows on desktop and mobile, including malicious input and multi-account isolation, before inviting users.

## Files

- `index.html` — NEXBYTE front end
- `supabase-config.js` — public client configuration placeholders
- `schema.sql` — database table and row-level security policies
