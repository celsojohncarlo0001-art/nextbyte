# NEXTBYTE Update — Testing Report

## Scope
This report covers the Study Hub Materials overview/folder changes, replacement of the Audio Files category with Video Files, video preview, and optional Task supporting-file attachments.

## Static checks performed

| Check | Result | Notes |
|---|---|---|
| Inline JavaScript syntax | PASS | All inline scripts checked with `node --check`. |
| Service worker syntax | PASS | `sw.js` checked with Node. |
| Supabase config syntax | PASS | Existing configuration file retained and syntax checked. |
| Manifest JSON | PASS | Parsed successfully. |
| HTML parse | PASS | Parsed with an HTML parser; no parser exception. |
| Local asset references | PASS | Relative JS/CSS/image references checked against project files. |
| PWA icons | PASS | Both existing icon files retained; image dimensions verified. |
| ZIP integrity | PASS | Archive test completed after packaging. |
| Storage path policy compatibility | PASS (static) | Task objects use `<auth-user-id>/tasks/<task-id>/...`, matching existing first-segment owner policy in `NEXBYTE_UPLOAD_STORAGE_FIX.sql`. |

## Targeted logic checks performed

| Test | Result |
|---|---|
| Materials default selection is folder overview | PASS | Overview has folder cards and upload control; it omits individual file cards. |
| All Files selection | PASS (static/logic) | `all` selection filters to all subject materials and renders their cards. |
| PDF/image/Word/video/text categorization | PASS (logic) | Checked common filename/MIME combinations. |
| Legacy audio categorization | PASS (logic) | MP3/WAV/M4A/OGG resolve to Other Files; objects are not deleted. |
| Legacy presentations/spreadsheets categorization | PASS (logic) | Existing PPT/XLS-family materials remain in Other Files. |
| Video preview selection | PASS (static) | MP4/WebM/MOV/M4V use HTML5 `<video controls playsInline>`. |
| Task file type validation | PASS (logic) | PDF, DOC/DOCX, images, TXT/MD, and supported video accepted; spreadsheet, presentation, CSV and audio rejected. |
| Task multi-file input | PASS (static) | File input has `multiple`; selected files show name/type/size and can be removed before save. |
| Task attachment metadata | PASS (static) | Records include file ID, original name, storage path, MIME, size, owner ID, task ID and timestamp in task workspace state. |
| Task cloud cleanup flow | PASS (static) | Partial upload failures attempt cleanup; removed attachments are deleted from Storage only after workspace metadata sync. |

## Not verified in this environment

The following require the real Supabase project, authenticated user, and deployed site. They are **not** marked as passed:

- Actual upload of PDF/video/task files to Supabase Storage.
- Row Level Security behavior for task paths on the deployed project.
- Cross-device visibility of task attachments after signing in on another device.
- Actual playback of uploaded video files on Android browsers (depends on codec/container support).
- Browser preview behavior for every file format on desktop and Android.
- Actual file deletion permissions and cleanup results.
- Vercel deployment and PWA update on an installed device.

## Post-deployment acceptance checklist

1. Deploy the complete project root to Vercel; preserve `supabase-config.js`.
2. Sign in and open a subject's Materials tab. Confirm that only folder cards and the upload button appear.
3. Open All Files and confirm existing files appear. Check that MP3/WAV files are under Other Files and not Video Files.
4. Upload an MP4/WebM/MOV/M4V sample and confirm it appears in Video Files and plays in the preview where supported.
5. Test category uploads and ensure files uploaded from a specific folder must match that category.
6. Open Tasks → Create a Detailed Task. Attach a PDF, DOCX, and image; verify file names, MIME types, and sizes.
7. Attempt XLSX, PPTX, CSV, and MP3 uploads and confirm each is rejected.
8. Save the task, reopen/edit it, and test Open, Download, Remove, and task deletion.
9. Sign into the same account on another device and verify workspace-linked task attachments and Materials files are accessible.
10. Verify no browser-console errors and no unintended horizontal overflow on phone/tablet/desktop.

## Security and data notes

- The existing `user-study-files` bucket remains private.
- Task uploads are stored beneath the authenticated user ID, satisfying the existing owner-prefix Storage policy.
- Task attachment metadata is stored with the task in the existing workspace JSONB state; no new SQL migration or bucket is required.
- Existing audio, presentation, and spreadsheet objects are preserved. The update changes category display/metadata only; it does not move, rename, or delete Storage objects.
- The app's workspace remains a single JSONB state document. Concurrent edits from multiple devices are still subject to the project's existing last-write-wins behavior.

## Follow-up repair — Study Hub subject Add Task button

### Static checks performed

| Check | Result | Notes |
|---|---|---|
| All inline JavaScript syntax | PASS | All six inline script blocks extracted and checked with `node --check`. |
| Service worker syntax | PASS | `sw.js` passed `node --check`. |
| Supabase config syntax | PASS | Existing `supabase-config.js` passed `node --check`; configuration was not changed. |
| HTML parse | PASS | Parsed with Python's HTML parser. |
| Subject Add Task button markup | PASS (static) | Both empty and populated subject-task states now render `type="button"` controls with `data-nbx-add-subject-task`. |
| Delegated click route | PASS (static) | A guarded document-level handler resolves the current subject and calls `window.openTaskSheet(null, subjectId)`. |
| Modal-open guard | PASS (static) | The handler checks for the task editor fields after invoking the editor and reports failures with a toast. |
| Legacy task-editor binding | PASS (static) | The global `openTaskSheet` identifier is synchronized with `window.openTaskSheet`. |
| PWA cache namespace | PASS | Updated to `nexbyte-pwa-v10-study-task-button-fix`. |
| ZIP integrity | PASS | Archive test completed after packaging. |

### Not verified in this environment

A real interactive browser click through the deployed Vercel application, authenticated task creation, and Supabase workspace save were not available here. After deployment, open a subject → Tasks → Add task and verify that the task editor appears, then create a test task and confirm it remains after refresh.
