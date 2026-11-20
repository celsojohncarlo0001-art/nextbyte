# NEXTBYTE — Static Verification and Post-Deployment Test Report

**Build date:** November 20, 2026  
**Source:** `nextbyte-main.zip` uploaded in this conversation  
**Verification type:** Static source and packaging checks; no live cloud deployment

## Static checks performed

| Check | Result | Notes |
|---|---|---|
| HTML document parsing | PASS | Parsed with a structured HTML parser; document has `html`, `head`, and `body`. |
| Inline JavaScript syntax | PASS | All five inline script blocks pass Node.js syntax checking. |
| Combined inline JavaScript syntax | PASS | Concatenated inline scripts pass Node.js syntax checking. |
| Service worker syntax | PASS | `sw.js` passes Node.js syntax checking. |
| Supabase config syntax | PASS | `supabase-config.js` passes Node.js syntax checking. Its existing project URL and public frontend key were preserved. |
| PWA manifest | PASS | Valid JSON; icon declarations and app metadata present. |
| PWA icon sizes | PASS | `icon-192.png` is 192×192; `icon-512.png` is 512×512. |
| Local asset references | PASS | Local script, stylesheet, and image references found in the HTML resolve to project files. |
| Offline repair source checks | PASS | Last-account marker, cached-workspace restore branch, and reconnect reload branch are present. |
| File-open source checks | PASS | Personal, room, and cloud-manager file open paths pre-open a tab before the asynchronous signed URL call. |
| Cloud delete ordering | PASS | Storage deletion occurs before shared-room message-reference cleanup. |
| Service-worker cache update | PASS | New cache namespace is `nexbyte-pwa-v5-offline-auth-repair`. |
| ZIP integrity | PASS | Final archive test completed without compressed-file errors. |

## Not tested (requires live deployment / Supabase access)

- Sign-up, email confirmation, sign-in, sign-out, password recovery, and session restoration.
- Reading and writing `user_workspaces` with the actual project's RLS policies.
- Supabase SQL migration execution and compatibility with the project's existing room tables.
- Private Storage uploads, signed file viewing, downloading, and deletion.
- Study Room creation, invite-code joins, member capacity, chat, shared notes/tasks/files, and owner/member permissions using two real accounts.
- Whiteboard Realtime delivery and concurrent edits.
- Music uploads and playback across devices.
- Cross-device workspace synchronization and conflict behavior.
- PWA install prompt, service-worker lifecycle, offline launch, and recovery on supported phones/desktops.
- Mobile/tablet/desktop interaction testing, browser console, and network error review.
- Vercel build and live deployment.

## Required Supabase setup

Read `README_SETUP.txt` before running SQL. The intended order is:

1. `schema.sql` only if `public.user_workspaces` is missing.
2. `NEXBYTE_ROOM_SCHEMA.sql` only if the shared-room base tables are missing. If those tables already exist, compare their columns and types before applying it.
3. `NEXBYTE_ENHANCEMENTS.sql` after the base room tables are present.
4. Review `NEXBYTE_UPLOAD_STORAGE_FIX.sql` separately and run only if needed. Do not blindly add permissive policies; Supabase combines permissive policies with OR semantics.

## Known limitations retained from the source app

- The personal workspace is a single JSONB state document; simultaneous edits from multiple devices can be last-write-wins.
- Room quizzes are practice-only because answer keys are included in room-visible message content.
- Whiteboards store whole-canvas snapshots; concurrent drawing can overwrite a newer snapshot.
- Room Lock-In shares member focus status, not a server-authoritative synchronized timer.
- Music playback is device-local.
- Notification preferences are stored, but push/email delivery is not configured in this package.
- Offline workspace recovery is device-local and requires a snapshot saved on that device. Cloud operations require connectivity.
- Offline file downloads do not automatically transfer to another device.

## Deployment acceptance checklist

After deploying the complete project to Vercel over HTTPS:

- [ ] Apply and verify the required Supabase SQL migrations.
- [ ] Sign in with a test account and refresh the page.
- [ ] Create a note and task, refresh, and confirm both persist.
- [ ] Upload a small PDF and an audio file; confirm the cloud objects and app references appear.
- [ ] Open and download a cloud file from the app.
- [ ] Test deletion with a disposable file and confirm Storage removal.
- [ ] Create a shared room, join it from a second test account, and verify member permissions.
- [ ] Send chat, add a shared note/task, and upload/open a shared file.
- [ ] Check room whiteboards from both accounts.
- [ ] Sign in on another device and confirm cloud-backed records appear.
- [ ] Install the PWA from the browser and test offline startup on the same device after a successful online sign-in.
- [ ] Reconnect and confirm the app reloads and resumes cloud access.
- [ ] Test the protected sections and bottom navigation at mobile, tablet, and desktop widths.
- [ ] Review browser console and network logs for errors.

**Status:** Static checks passed. Live integration and deployment acceptance checks remain pending. This report does not certify zero runtime errors.


## Study Hub attachment repair — November 20, 2026

| Check | Result | Notes |
|---|---|---|
| Per-subject Storage lookup source check | PASS | Subject entry triggers a Storage folder scan under the authenticated user's exact subject ID. |
| Legacy attachment recovery logic | PASS (mocked) | A mocked Storage response recovered files from `materials/`, `syllabus/`, and the older direct subject-folder layout. |
| Duplicate reference prevention | PASS (mocked) | Re-running the recovery scan added zero duplicate paths. |
| Workspace persistence path | PASS (source review) | Newly recovered references are saved using the existing `saveWorkspaceNow()` workspace upsert; no new table was added. |
| Filename overflow styling | PASS (source check) | Scoped flex sizing, `min-width: 0`, hidden overflow, ellipsis, and 44 px fixed-width action controls are applied to Study Hub attachments. |
| Full filename accessibility | PASS (renderer test) | The generated attachment markup retains the complete filename in its `title` attribute, even for a long unbroken filename. |
| Inline JavaScript syntax | PASS | All five inline script blocks and their concatenation passed `node --check` after this repair. |
| CSS parsing | PASS | The inline stylesheet parsed without CSS syntax errors. |
| Subject-entry scan trigger | PASS (mocked) | A route harness confirmed that entering a subject schedules one scan, ordinary rerenders do not repeat it, and leaving/re-entering schedules a fresh scan. |
| Existing protected UI | Not browser-verified | Changes were scoped to subject attachment markup/styles and attachment loading logic. Browser visual regression testing requires a running app. |

## Live checks still required

The mocked Storage test verifies the recovery algorithm, not the user's live Supabase project. These checks remain unverified until deployment:

- [ ] Upload a new PDF from Study Hub → open subject → Materials. Confirm it appears without leaving the subject.
- [ ] Upload a very long filename, including one with no spaces. Confirm the card stays within its frame and all three action buttons remain visible.
- [ ] Refresh and reopen the same subject. Confirm the attachment still appears.
- [ ] Sign in to the same account on another device and open the subject. Confirm the file appears and can be opened/downloaded.
- [ ] Confirm an existing Storage-only file is reattached automatically when its subject is opened, without using Manage Cloud Files.
- [ ] Verify the `user-study-files` bucket is private and the existing Storage `SELECT` policy permits the authenticated owner to list only their own prefix.
- [ ] Verify upload, open, download, and delete operations in the browser console and Network panel.

**Current status:** Static and mocked-recovery checks passed. Live upload, storage policy, cross-device, and visual browser tests have not been performed. This does not certify zero runtime errors.


## Follow-up Study Hub attachment correction — November 20, 2026

| Check | Result | Notes |
|---|---|---|
| Missing Materials Open icon | PASS (source check) | The `external` icon referenced by the middle Materials action is now defined. |
| Recursive subject Storage scan | PASS (mocked) | A mocked account tree restored four files across nested Materials, Syllabus, attachment, and legacy root paths; a second pass restored zero duplicates. |
| Manual/automatic recovery parity | PASS (source review) | Both entry recovery and Manage Cloud Files invoke the same account-wide idempotent reconciliation function. |
| Mobile entry timing | PASS (source check) | Subject entry scan is delayed and uses up to three bounded retries; scans are coalesced and debounced. |
| Syllabus long-name containment | PASS (CSS/markup check) | Syllabus header uses a `minmax(0, 1fr) auto` grid; title and original filename wrap anywhere within the card. |
| PWA cache invalidation | PASS (source check) | Cache version updated to `nexbyte-pwa-v6-subject-attachment-sync`. |
| JavaScript / HTML / CSS syntax | PASS | Five inline scripts, combined inline scripts, service worker, Supabase config, HTML, and inline CSS passed static parsing/syntax checks. |

### Not verified in this environment

- The app was not signed into the user's live Supabase project; actual Storage `SELECT` permissions and folder results could not be observed.
- New and historical attachments were not live-uploaded, opened, downloaded, or tested across two devices.
- Android/Vercel visual deployment was not run. The screenshots were used to identify the missing icon and overflowing Syllabus text, and the markup/CSS were repaired; the hosted display still needs confirmation after deployment.

**Status:** Source-level repairs and static checks passed. Live cloud and deployed-device acceptance tests remain pending.


A local Node.js mock harness executed the actual extracted `recoverExistingSubjectFiles` implementation against representative Storage results. It restored four records, saved the workspace once, ignored a file not belonging to a known subject, and returned zero new records on the second run. This is a logic simulation, not a live Supabase integration test.


## Materials upload live-state correction — November 20, 2026

| Check | Result | Notes |
|---|---|---|
| Materials upload handler syntax | PASS | Updated handler is contained in valid inline JavaScript. |
| Subject object replaced during upload | PASS (mocked) | A test replaced the global workspace while Storage upload was pending; the handler re-resolved the subject by ID and attached the new file to the current subject object. |
| Immediate Materials rendering | PASS (mocked) | The handler rendered the updated Materials list before the delayed cloud workspace save resolved. |
| Workspace metadata includes Storage path | PASS (mocked) | The workspace save mock received the uploaded attachment with its actual `user-id/subject-id/materials/...` path. |
| Duplicate attachment prevention | PASS (mocked) | Re-attaching the same Storage path did not create a second material row. |
| Preserve Storage object on workspace sync failure | PASS (source check) | The new path does not delete a successfully uploaded Storage object when the workspace upsert fails; it preserves the local snapshot and reports pending synchronization. |
| Inline JavaScript syntax | PASS | All seven inline script blocks passed `node --check`. |
| Service worker syntax / cache refresh | PASS | `sw.js` passed `node --check`; cache namespace is `nexbyte-pwa-v7-materials-upload-live-state`. |

### Live checks still required

- [ ] Deploy this build to Vercel and reopen the installed PWA so the v7 service worker activates.
- [ ] Upload a PDF in a signed-in account and confirm the file appears in Materials immediately, without opening Manage Cloud Files.
- [ ] Refresh and reopen the subject; confirm the file remains visible.
- [ ] Check Supabase Storage and `user_workspaces` to confirm both the object and attachment metadata exist.
- [ ] Test on a second device using the same account.
- [ ] Test with the account's actual Storage `SELECT` and `INSERT` policies and inspect browser console/network logs.

**Status:** Source-level and mocked upload-race tests passed. Live Storage, database RLS, cross-device, and deployed-device tests remain unverified. This does not certify zero runtime errors.
