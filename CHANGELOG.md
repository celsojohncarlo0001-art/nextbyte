# NEXTBYTE Cloud File Recovery and Delete Fix

## Root cause identified
Supabase Storage contained study-file objects while the associated `user_workspaces.state.subjects[].materials` and `syllabusFiles` arrays were empty. The files existed in cloud storage, but the app had no metadata references to render them.

## Changes
- Automatically recover material and syllabus references from the authenticated user's private Storage folders after workspace load.
- Support both categorized paths (`userId/subjectId/materials/...`, `.../syllabus/...`) and legacy direct paths (`userId/subjectId/filename`).
- Persist recovered references to `user_workspaces` and refresh the application UI.
- Add Profile > Settings > Manage cloud files.
- List personal study files, music, and shared-room files visible to the current account.
- Add Open, Download, and Delete from cloud controls.
- Delete removes the Storage object and cleans matching workspace metadata or room message references.
- Preserve per-item delete controls already present in Study Hub, Syllabus, Music, and Study Rooms.
- Bump the service-worker cache version to refresh deployed app assets.

## Supabase inspection
The expected private buckets and authenticated Storage policies were present. No additional SQL migration was added.

## Validation
Passed: inline JavaScript syntax checks, service-worker syntax, HTML parser, manifest JSON, icon dimensions, and archive integrity.
Not performed: live authenticated browser upload/delete, two-account room verification, or Vercel deployment.
