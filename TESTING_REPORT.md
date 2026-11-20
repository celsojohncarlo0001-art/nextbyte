# NEXTBYTE — Preview and Offline Download Testing Report

Date: November 20, 2026

## Implemented

1. Preview fetches the bytes from the authenticated private Supabase Storage signed URL and displays a local Blob URL. This prevents an attachment `Content-Disposition` header on the signed URL from turning the preview action into a download.
2. PDF file types are normalized to `application/pdf` based on the extension when older records report a generic binary MIME type.
3. Download fetches the original bytes, saves a copy in the existing IndexedDB cache using the same `offline_material_<storage-path>` key used by preview, and downloads the file with its original filename.
4. Preview checks the device cache first. A locally saved file can be previewed again without a network connection.
5. When local storage quota or browser restrictions prevent caching, the normal download continues and the user receives a warning that offline preview is not available for that file on this device.
6. The same behavior applies to Study Hub materials, syllabus attachments, and task attachments, because they share the private `user-study-files` bucket and preview/download helpers.

## Checks performed

- All inline JavaScript blocks: syntax checked.
- Service worker: syntax checked.
- HTML: parsed.
- Preview code path: verified to fetch bytes, create a Blob URL, and attach it to the PDF iframe rather than navigate an anchor to the signed URL.
- Download code path: verified to write the same file bytes to the existing IndexedDB offline key before triggering a local Blob download.
- MIME normalization: checked for PDF files recorded as `application/octet-stream`, as well as common image/video/text types.
- PWA service-worker cache version: incremented.
- ZIP archive: integrity checked.

## Not verified in this environment

- Actual private Supabase Storage responses under the user's deployed account.
- PDF rendering inside the user's particular Android browser/PWA build. The implementation now uses an inline PDF Blob URL and `application/pdf` type, but embedded PDF support still depends on the browser's PDF viewer capability.
- Actual device download manager behavior and IndexedDB quota on the user's device.
- Cross-device offline availability. Offline copies are intentionally device-specific; each device must download the file once while online.

## User verification steps

1. Deploy the included project files to the existing Vercel project, preserving `supabase-config.js`.
2. Open NEXTBYTE online and allow the updated service worker to activate.
3. Open a task with a PDF attachment and choose **Preview**. The file should display within the preview panel without initiating a download.
4. Close the preview, choose **Download** (or **Download & save offline** in the preview panel), and confirm the original file downloads.
5. Disconnect the device from the internet, reopen the same attachment's Preview action, and confirm NEXTBYTE indicates that the file is available offline and displays the saved copy.
6. Repeat the download separately on any other device that needs offline preview.
