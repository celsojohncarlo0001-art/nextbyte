# NEXTBYTE branding correction

- Corrected visible product branding in `index.html`, the PWA manifest, service-worker messages, and documentation.
- Updated the page background reference and service-worker app shell to `nextbyte-background.png`.
- Removed the duplicate typo-named `nexbyte-background.png` asset. The background artwork itself is abstract and contains no embedded product text.
- Renamed the three SQL script filenames to use `NEXTBYTE_...`; their SQL behavior is unchanged.
- Kept legacy local-storage, IndexedDB, cache, and Supabase configuration aliases where needed so existing user data and deployments remain compatible.
- The download filename and visible product labels use NEXTBYTE. The internal `NEXBYTE_WORKSPACE` serialization token and legacy Supabase aliases are retained so existing exports and deployments remain compatible.
- Existing Supabase policy names were deliberately preserved as database identifiers; this update does not rename or alter deployed policies.
