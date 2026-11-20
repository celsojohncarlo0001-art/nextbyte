# NEXTBYTE PDF.js

This folder is reserved for PDF.js assets used by the NEXTBYTE file preview system.

## Purpose

PDF.js allows NEXTBYTE to render PDF documents directly inside the application without requiring users to download and open PDFs in another application.

## Required Files for Self-Hosted PDF.js

If NEXTBYTE uses a locally hosted PDF.js engine, this folder should contain:

- `pdf.min.mjs` — PDF.js main library
- `pdf.worker.min.mjs` — PDF.js worker

Both files must use matching versions.

## Offline Support

PDF.js runtime files must be cached locally to support offline PDF previews in the NEXTBYTE Progressive Web App (PWA).

## Security

NEXTBYTE PDF previews must preserve Supabase authentication and private file access.

Never place Supabase service-role keys, passwords, or private credentials in this folder.

## Current Implementation

The current NEXTBYTE preview implementation may load PDF.js from a CDN and cache its runtime resources for offline use.

This folder is reserved for a future self-hosted PDF.js implementation.

---
NEXTBYTE Academic Productivity Platform
